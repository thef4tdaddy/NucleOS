//
//  CalendarService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Calendar / EventKit events
//

import EventKit
import Foundation

// MARK: - Protocol

/// Declares the async interface for fetching calendar events from EventKit.
protocol CalendarServiceProtocol {
    /// Returns all events occurring today (midnight-to-midnight in the user's time zone).
    func fetchTodayEvents() async throws -> [NucleEvent]
    /// Returns events in the half-open range [today, today + days).
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent]
    /// Returns all events for the month containing the given date.
    func fetchEvents(for month: Date) async throws -> [NucleEvent]
    /// Creates a new event in the user's calendar.
    func createEvent(_ event: NucleEvent, calendarIdentifier: String?) async throws
    /// Updates an existing event in the user's calendar.
    func updateEvent(_ event: NucleEvent, calendarIdentifier: String?) async throws
    /// Deletes an event from the user's calendar.
    func deleteEvent(_ event: NucleEvent) async throws
    /// Returns all EKCalendars for events, sorted by title.
    func fetchCalendars() -> [EKCalendar]
}

// MARK: - Errors

enum CalendarServiceError: LocalizedError {
    case permissionDenied
    case fetchFailed(Error)
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access was denied. Please grant permission in System Settings."
        case .fetchFailed(let error):
            return "Failed to fetch events: \(error.localizedDescription)"
        case .eventNotFound:
            return "Event not found in calendar."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that integrates with EventKit Calendar.
@MainActor
class CalendarService: CalendarServiceProtocol {
    private var eventStore: EKEventStore { permissionsManager.eventStore }
    private let permissionsManager = PermissionsManager.shared
    private var changeObserver: NSObjectProtocol?

    init() {
        setupChangeObserver()
    }

    deinit {
        if let observer = changeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupChangeObserver() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: NSNotification.Name("CalendarDataChanged"), object: nil)
        }
    }

    // MARK: - Fetch

    func fetchTodayEvents() async throws -> [NucleEvent] {
        try await SentryConfig.traced(operation: "db.query", name: "CalendarService.fetchTodayEvents") {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
            return try await fetchEvents(from: startOfDay, to: endOfDay)
        }
    }

    func fetchEvents(for month: Date) async throws -> [NucleEvent] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [] }
        return try await fetchEvents(from: monthStart, to: monthEnd)
    }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: days, to: startOfDay) else { return [] }
        return try await fetchEvents(from: startOfDay, to: endDate)
    }

    /// Returns EKCalendars for events sorted by title.
    func fetchCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event).sorted { $0.title < $1.title }
    }

    // MARK: - Mutations

    func createEvent(_ event: NucleEvent, calendarIdentifier: String? = nil) async throws {
        guard permissionsManager.hasCalendarAccess else { throw CalendarServiceError.permissionDenied }

        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.location = event.location
        ekEvent.notes = event.notes
        ekEvent.url = event.url

        // Use specified calendar or default
        if let calId = calendarIdentifier,
           let cal = eventStore.calendar(withIdentifier: calId) {
            ekEvent.calendar = cal
        } else {
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        }

        // Apply reminder
        if let offset = event.reminderOffset {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-offset * 60))
            ekEvent.addAlarm(alarm)
        }

        try eventStore.save(ekEvent, span: .thisEvent)
    }

    func updateEvent(_ event: NucleEvent, calendarIdentifier: String? = nil) async throws {
        guard permissionsManager.hasCalendarAccess else { throw CalendarServiceError.permissionDenied }

        let store = eventStore

        // Prefer lookup by eventIdentifier
        var ekEvent: EKEvent?
        if let identifier = event.eventIdentifier {
            ekEvent = store.calendarItem(withIdentifier: identifier) as? EKEvent
        }

        guard let ekEvent else {
            throw CalendarServiceError.eventNotFound
        }

        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.location = event.location
        ekEvent.notes = event.notes
        ekEvent.url = event.url

        if let calId = calendarIdentifier,
           let cal = store.calendar(withIdentifier: calId) {
            ekEvent.calendar = cal
        }

        // Update alarms
        ekEvent.alarms?.forEach { ekEvent.removeAlarm($0) }
        if let offset = event.reminderOffset {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-offset * 60))
            ekEvent.addAlarm(alarm)
        }

        try store.save(ekEvent, span: .thisEvent)
    }

    func deleteEvent(_ event: NucleEvent) async throws {
        guard permissionsManager.hasCalendarAccess else { throw CalendarServiceError.permissionDenied }

        let store = eventStore
        var ekEvent: EKEvent?

        if let identifier = event.eventIdentifier {
            ekEvent = store.calendarItem(withIdentifier: identifier) as? EKEvent
        }

        guard let ekEvent else {
            throw CalendarServiceError.eventNotFound
        }

        try store.remove(ekEvent, span: .thisEvent)
    }

    // MARK: - Private Helpers

    private func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [NucleEvent] {
        if permissionsManager.calendarAuthStatus == .notDetermined {
            _ = await permissionsManager.requestCalendarAccess()
        }
        guard permissionsManager.hasCalendarAccess else { throw CalendarServiceError.permissionDenied }

        // Apply visible-calendar filter from UserDefaults
        let visibleIDs = Set(UserDefaults.standard.stringArray(forKey: "visible_calendar_ids") ?? [])
        let allCalendars = eventStore.calendars(for: .event)
        let filteredCalendars: [EKCalendar]? = visibleIDs.isEmpty ? nil :
            allCalendars.filter { visibleIDs.contains($0.calendarIdentifier) }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: filteredCalendars
        )

        let store = eventStore
        let ekEvents = await Task.detached {
            store.events(matching: predicate)
        }.value

        return ekEvents.compactMap { convertToNucleEvent(from: $0) }
    }

    private func convertToNucleEvent(from ekEvent: EKEvent) -> NucleEvent? {
        guard let title = ekEvent.title, !title.isEmpty else { return nil }

        let eventColor: EventColor
        if let cgColor = ekEvent.calendar?.cgColor {
            eventColor = .custom(cgColorToHex(cgColor))
        } else {
            eventColor = .accentPrimary
        }

        let availability: EventAvailability
        switch ekEvent.availability {
        case .free: availability = .free
        case .tentative: availability = .tentative
        case .unavailable: availability = .unavailable
        default: availability = .busy
        }

        let isDeclined = ekEvent.attendees?.contains(where: {
            $0.isCurrentUser && $0.participantStatus == .declined
        }) ?? false

        let reminderOffset = ekEvent.alarms?.first.map { Int(-$0.relativeOffset / 60) }

        return NucleEvent(
            eventIdentifier: ekEvent.eventIdentifier,
            calendarIdentifier: ekEvent.calendar?.calendarIdentifier,
            title: title,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            calendarColor: eventColor,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            notes: ekEvent.notes,
            url: ekEvent.url,
            availability: availability,
            reminderOffset: reminderOffset,
            isDeclined: isDeclined
        )
    }

    private func cgColorToHex(_ cgColor: CGColor) -> String {
        let rgbColor = cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        ) ?? cgColor
        guard let components = rgbColor.components, components.count >= 3 else { return "5b3fd4" }
        return String(format: "%02x%02x%02x",
                      Int(components[0] * 255),
                      Int(components[1] * 255),
                      Int(components[2] * 255))
    }
}

// MARK: - Mock Implementation

class MockCalendarService: CalendarServiceProtocol {

    func fetchTodayEvents() async throws -> [NucleEvent] { MockData.events }
    func fetchEvents(for month: Date) async throws -> [NucleEvent] { MockData.events }
    func createEvent(_ event: NucleEvent, calendarIdentifier: String?) async throws {}
    func updateEvent(_ event: NucleEvent, calendarIdentifier: String?) async throws {}
    func deleteEvent(_ event: NucleEvent) async throws {}
    func fetchCalendars() -> [EKCalendar] { [] }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        guard days > 0 else { return [] }
        var events: [NucleEvent] = try await fetchTodayEvents()
        for dayOffset in 1..<days {
            guard let futureDay = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            events.append(contentsOf: upcomingEvents(for: futureDay, offset: dayOffset))
        }
        return events
    }

    private let calendar = Calendar.current

    private func upcomingEvents(for date: Date, offset: Int) -> [NucleEvent] {
        switch offset % 3 {
        case 0:
            return [NucleEvent(
                title: "Sprint Planning",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date,
                endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date) ?? date,
                calendarColor: .accentPrimary
            )]
        case 1:
            return [NucleEvent(
                title: "Engineering All-Hands",
                startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date,
                endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) ?? date,
                calendarColor: .accentLavender,
                location: "Main Auditorium"
            )]
        default:
            return [NucleEvent(
                title: "Focus Block",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date,
                endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date,
                calendarColor: .accentLight
            )]
        }
    }
}
