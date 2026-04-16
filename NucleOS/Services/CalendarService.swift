//
//  CalendarService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Calendar / EventKit events
//

import EventKit
import Foundation

// MARK: - Protocol

protocol CalendarServiceProtocol {
    /// Returns all events occurring today (midnight-to-midnight in the user's time zone).
    func fetchTodayEvents() async throws -> [NucleEvent]
    /// Returns events in the half-open range [today, today + days).
    /// - Parameter days: Number of days to look ahead. Must be ≥ 1; passing 0 returns an empty array.
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent]
}

// MARK: - Errors

enum CalendarServiceError: LocalizedError {
    case permissionDenied
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
    private let eventStore = EKEventStore()
    private let permissionsManager = PermissionsManager.shared

    func fetchTodayEvents() async throws -> [NucleEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return try await fetchEvents(from: startOfDay, to: endOfDay)
    }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        guard days > 0 else { return [] }

        let startDate = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) else {
            return []
        }

        return try await fetchEvents(from: startDate, to: endDate)
    }

    // MARK: - Private Helpers

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

        let ekEvents = eventStore.events(matching: predicate)
        return ekEvents.compactMap { convertToNucleEvent(from: $0) }
    }

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

    private func cgColorToHex(_ cgColor: CGColor) -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "5b3fd4" // Default to accentPrimary
        }

        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)

        return String(format: "%02x%02x%02x", red, green, blue)
    }
}

// MARK: - Mock Implementation

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
class MockCalendarService: CalendarServiceProtocol {

    func fetchTodayEvents() async throws -> [NucleEvent] {
        let today = Date()
        return [
            NucleEvent(
                title: "Team Standup",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today) ?? today,
                calendarColor: .accentPrimary
            ),
            NucleEvent(
                title: "Product Review",
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) ?? today,
                calendarColor: .accentLavender,
                location: "Conference Room B"
            ),
            NucleEvent(
                title: "Design Sync",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 14, minute: 45, second: 0, of: today) ?? today,
                calendarColor: .accentLight
            ),
            NucleEvent(
                title: "1:1 with Manager",
                startDate: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today,
                calendarColor: .custom("ff6b6b")
            )
        ]
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
