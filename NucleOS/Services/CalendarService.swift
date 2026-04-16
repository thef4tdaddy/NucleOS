//
//  CalendarService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Calendar / EventKit events
//

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
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "CalendarService is not implemented yet. EventKit integration is still pending."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with EventKit Calendar.
class CalendarService: CalendarServiceProtocol {

    func fetchTodayEvents() async throws -> [NucleEvent] {
        // TODO: Request EventKit authorization and fetch today's EKEvents
        throw CalendarServiceError.notImplemented
    }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        // TODO: Fetch EKEvents in a date range of [now, now + days]
        throw CalendarServiceError.notImplemented
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
