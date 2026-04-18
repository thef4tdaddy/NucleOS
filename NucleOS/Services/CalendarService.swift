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
    /// - Parameter days: Number of days to look ahead. Must be ≥ 1; passing 0 returns an empty array.
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent]
}

// MARK: - Errors

/// Errors that can be thrown by ``CalendarServiceProtocol`` implementations.
enum CalendarServiceError: LocalizedError {
    /// Access to Calendar was not granted by the user.
    case permissionDenied
    /// An underlying EventKit error prevented the fetch.
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access was denied. Please grant permission in System Settings."
        case .fetchFailed(let error):
            return "Failed to fetch events: \(error.localizedDescription)"
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that integrates with EventKit Calendar.
@MainActor
class CalendarService: CalendarServiceProtocol {
    private var eventStore: EKEventStore { permissionsManager.eventStore }
    private let permissionsManager = PermissionsManager.shared

    /// Fetches all events occurring today (midnight-to-midnight in the user's time zone).
    func fetchTodayEvents() async throws -> [NucleEvent] {
        try await SentryConfig.traced(operation: "db.query", name: "CalendarService.fetchTodayEvents") {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return try await fetchEvents(from: startOfDay, to: endOfDay)
        }
    }

    /// Fetches events in the half-open range [now, now + `days`).
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        guard days > 0 else { return [] }

        let startDate = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) else {
            return []
        }

        return try await fetchEvents(from: startDate, to: endDate)
    }

    // MARK: - Private Helpers

    /// Fetches EventKit events in the given date range, requesting permission if needed.
    private func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [NucleEvent] {
        // Check and request permissions if needed
        if permissionsManager.calendarAuthStatus == .notDetermined {
            _ = await permissionsManager.requestCalendarAccess()
        }

        guard permissionsManager.hasCalendarAccess else {
            throw CalendarServiceError.permissionDenied
        }

        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        // Capture eventStore before detaching to avoid actor isolation issues
        let store = eventStore

        // Move heavy EventKit query off main actor
        let ekEvents = await Task.detached {
            store.events(matching: predicate)
        }.value

        // Convert on main actor since this is UI-safe
        return ekEvents.compactMap { convertToNucleEvent(from: $0) }
    }

    /// Converts an `EKEvent` into a ``NucleEvent``, or returns `nil` if the title is missing.
    private func convertToNucleEvent(from ekEvent: EKEvent) -> NucleEvent? {
        guard let title = ekEvent.title, !title.isEmpty else {
            return nil
        }

        // Convert EKCalendar color to EventColor
        let eventColor: EventColor
        if let cgColor = ekEvent.calendar?.cgColor {
            let hexString = cgColorToHex(cgColor)
            eventColor = .custom(hexString)
        } else {
            eventColor = .accentPrimary
        }

        return NucleEvent(
            title: title,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            calendarColor: eventColor,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location
        )
    }

    /// Converts a `CGColor` to a lowercase hex string, converting to sRGB first.
    /// Falls back to the accent-primary hex (`5b3fd4`) if conversion fails.
    private func cgColorToHex(_ cgColor: CGColor) -> String {
        let rgbColor = cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil) ?? cgColor
        guard let components = rgbColor.components, components.count >= 3 else {
            return "5b3fd4" // Default to accentPrimary
        }

        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)

        return String(format: "%02x%02x%02x", red, green, blue)
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
class MockCalendarService: CalendarServiceProtocol {

    /// Returns hardcoded events for today, suitable for previews and tests.
    func fetchTodayEvents() async throws -> [NucleEvent] {
        return MockData.events
    }

    /// Returns events over the next `days` days, starting from today.
    /// Passing `days <= 0` returns an empty array.
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        guard days > 0 else { return [] }
        var events: [NucleEvent] = try await fetchTodayEvents()
        for dayOffset in 1..<days {
            guard let futureDay = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            events.append(contentsOf: upcomingEvents(for: futureDay, offset: dayOffset))
        }
        return events
    }

    // MARK: - Private

    private let calendar = Calendar.current

    /// Generates sample events for the given `date`, cycling through three patterns based on `offset`.
    private func upcomingEvents(for date: Date, offset: Int) -> [NucleEvent] {
        switch offset % 3 {
        case 0:
            return [
                NucleEvent(
                    title: "Sprint Planning",
                    startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date,
                    endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date) ?? date,
                    calendarColor: .accentPrimary
                )
            ]
        case 1:
            return [
                NucleEvent(
                    title: "Engineering All-Hands",
                    startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date,
                    endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) ?? date,
                    calendarColor: .accentLavender,
                    location: "Main Auditorium"
                )
            ]
        default:
            return [
                NucleEvent(
                    title: "Focus Block",
                    startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date,
                    endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date,
                    calendarColor: .accentLight
                )
            ]
        }
    }
}
