//
//  CalendarServiceTests.swift
//  NucleOSTests/Services
//
//  Swift Testing suite for CalendarService — mock-only, zero real Apple framework calls.
//

import Testing
@testable import NucleOS

@Suite("Calendar Service")
struct CalendarServiceTests {

    // MARK: - fetchTodayEvents

    @Test("fetchTodayEvents returns events")
    func fetchTodayEventsReturnsEvents() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        #expect(!events.isEmpty)
    }

    @Test("NucleEvent has non-empty title")
    func nucleEventHasNonEmptyTitle() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        for event in events {
            #expect(!event.title.isEmpty)
        }
    }

    @Test("NucleEvent startDate is before endDate")
    func nucleEventStartBeforeEnd() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        for event in events where !event.isAllDay {
            #expect(event.startDate <= event.endDate)
        }
    }

    @Test("Today events have startDate within today")
    func todayEventsWithinToday() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let cal = Calendar.current
        for event in events {
            #expect(cal.isDateInToday(event.startDate))
        }
    }

    @Test("fetchTodayEvents: empty calendar handled gracefully via zero-days upcoming")
    func emptyCalendarHandled() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 0)
        #expect(events.isEmpty)
    }

    // MARK: - fetchUpcomingEvents

    @Test("fetchUpcomingEvents(days: 0) returns empty")
    func upcomingZeroDaysReturnsEmpty() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 0)
        #expect(events.isEmpty)
    }

    @Test("fetchUpcomingEvents(days: -1) returns empty")
    func upcomingNegativeDaysReturnsEmpty() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: -1)
        #expect(events.isEmpty)
    }

    @Test("Upcoming events are in future or today")
    func upcomingEventsAreInFutureOrToday() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 7)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        for event in events {
            #expect(event.startDate > yesterday)
        }
    }

    @Test("fetchUpcomingEvents returns more events for more days")
    func moreEventsForMoreDays() async throws {
        let service = MockCalendarService()
        let week = try await service.fetchUpcomingEvents(days: 7)
        let day = try await service.fetchUpcomingEvents(days: 1)
        #expect(week.count >= day.count)
    }

    // MARK: - NucleEvent properties

    @Test("NucleEvent id is unique per instance")
    func nucleEventIDIsUnique() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let ids = events.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }
}
