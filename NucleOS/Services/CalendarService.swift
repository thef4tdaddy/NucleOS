//
//  CalendarService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Calendar / EventKit events
//

import Foundation

// MARK: - Protocol

protocol CalendarServiceProtocol {
    func fetchTodayEvents() async throws -> [NucleEvent]
    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent]
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with EventKit Calendar.
class CalendarService: CalendarServiceProtocol {

    func fetchTodayEvents() async throws -> [NucleEvent] {
        // TODO: Request EventKit authorization and fetch today's EKEvents
        return []
    }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
        // TODO: Fetch EKEvents in a date range of [now, now + days]
        return []
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
                calendarColor: "5b3fd4"
            ),
            NucleEvent(
                title: "Product Review",
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today) ?? today,
                calendarColor: "c4b5fd",
                location: "Conference Room B"
            ),
            NucleEvent(
                title: "Design Sync",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 14, minute: 45, second: 0, of: today) ?? today,
                calendarColor: "7c5cf0"
            ),
            NucleEvent(
                title: "1:1 with Manager",
                startDate: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today) ?? today,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today,
                calendarColor: "ff6b6b"
            )
        ]
    }

    func fetchUpcomingEvents(days: Int) async throws -> [NucleEvent] {
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
                    calendarColor: "5b3fd4"
                )
            ]
        case 1:
            return [
                NucleEvent(
                    title: "Engineering All-Hands",
                    startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date,
                    endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) ?? date,
                    calendarColor: "c4b5fd",
                    location: "Main Auditorium"
                )
            ]
        default:
            return [
                NucleEvent(
                    title: "Focus Block",
                    startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date,
                    endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date,
                    calendarColor: "7c5cf0"
                )
            ]
        }
    }
}
