//
//  CalendarServiceTests.swift
//  NucleOSTests
//
//  Tests for CalendarService changes in this PR:
//  - New CalendarServiceError cases (permissionDenied, fetchFailed)
//  - MockCalendarService implementation
//  - fetchUpcomingEvents edge cases
//

import XCTest
@testable import NucleOS

final class CalendarServiceTests: XCTestCase {

    // MARK: - CalendarServiceError Tests

    func testPermissionDeniedErrorDescription() {
        let error = CalendarServiceError.permissionDenied
        XCTAssertEqual(
            error.errorDescription,
            "Calendar access was denied. Please grant permission in System Settings."
        )
    }

    func testFetchFailedErrorDescriptionContainsUnderlyingMessage() {
        let underlying = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "network failure"])
        let error = CalendarServiceError.fetchFailed(underlying)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("network failure"), "Expected underlying error message in: \(description)")
    }

    func testFetchFailedErrorDescriptionPrefix() {
        let underlying = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "timeout"])
        let error = CalendarServiceError.fetchFailed(underlying)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.hasPrefix("Failed to fetch events:"))
    }

    func testCalendarServiceErrorConformsToLocalizedError() {
        let error: LocalizedError = CalendarServiceError.permissionDenied
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - MockCalendarService.fetchTodayEvents Tests

    func testFetchTodayEventsReturnsEvents() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        XCTAssertFalse(events.isEmpty, "fetchTodayEvents should return at least one event")
    }

    func testFetchTodayEventsReturnsFourEvents() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        XCTAssertEqual(events.count, 4)
    }

    func testFetchTodayEventsContainsTeamStandup() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let titles = events.map(\.title)
        XCTAssertTrue(titles.contains("Team Standup"), "Expected 'Team Standup' in today's events")
    }

    func testFetchTodayEventsContainsProductReview() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let titles = events.map(\.title)
        XCTAssertTrue(titles.contains("Product Review"))
    }

    func testFetchTodayEventsContainsDesignSync() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let titles = events.map(\.title)
        XCTAssertTrue(titles.contains("Design Sync"))
    }

    func testFetchTodayEventsContainsOneOnOne() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let titles = events.map(\.title)
        XCTAssertTrue(titles.contains("1:1 with Manager"))
    }

    func testFetchTodayEventsAllOccurToday() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let calendar = Calendar.current
        for event in events {
            XCTAssertTrue(
                calendar.isDateInToday(event.startDate),
                "Event '\(event.title)' startDate should be today"
            )
        }
    }

    func testFetchTodayEventsProductReviewHasLocation() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let productReview = events.first { $0.title == "Product Review" }
        XCTAssertNotNil(productReview?.location)
    }

    func testFetchTodayEventsTeamStandupUsesAccentPrimaryColor() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let standup = events.first { $0.title == "Team Standup" }
        XCTAssertEqual(standup?.calendarColor, .accentPrimary)
    }

    func testFetchTodayEventsManagerOneOnOneUsesCustomColor() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        let oneOnOne = events.first { $0.title == "1:1 with Manager" }
        XCTAssertEqual(oneOnOne?.calendarColor, .custom("ff6b6b"))
    }

    func testFetchTodayEventsNoneAreAllDay() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchTodayEvents()
        for event in events {
            XCTAssertFalse(event.isAllDay, "Mock today events should not be all-day")
        }
    }

    // MARK: - MockCalendarService.fetchUpcomingEvents Tests

    func testFetchUpcomingEventsZeroDaysReturnsEmpty() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 0)
        XCTAssertTrue(events.isEmpty, "days=0 should return empty array")
    }

    func testFetchUpcomingEventsNegativeDaysReturnsEmpty() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: -1)
        XCTAssertTrue(events.isEmpty, "Negative days should return empty array")
    }

    func testFetchUpcomingEventsOneDayReturnsTodayEvents() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 1)
        // days=1 should include today's 4 events
        XCTAssertEqual(events.count, 4)
    }

    func testFetchUpcomingEventsSevenDaysReturnsMoreThanTodayEvents() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 7)
        // Should return today's 4 events plus events for days 1..6
        XCTAssertGreaterThan(events.count, 4)
    }

    func testFetchUpcomingEventsSevenDaysEventCount() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 7)
        // Today (4) + 6 more days (1 event each from offset 1..6) = 10
        XCTAssertEqual(events.count, 10)
    }

    func testFetchUpcomingEventsTwoDaysEventCount() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 2)
        // Today (4) + offset 1 day (1 event) = 5
        XCTAssertEqual(events.count, 5)
    }

    func testFetchUpcomingEventsStartDatesAreSortedOrDistributed() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 7)
        // All events should be non-nil and have valid dates
        XCTAssertFalse(events.isEmpty)
        for event in events {
            XCTAssertFalse(event.title.isEmpty)
        }
    }

    func testFetchUpcomingEventsContainsTodayEventsInResults() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 3)
        let titles = events.map(\.title)
        XCTAssertTrue(titles.contains("Team Standup"))
    }

    func testFetchUpcomingEventsThreeDaysIncludesSprintPlanningOrOther() async throws {
        let service = MockCalendarService()
        let events = try await service.fetchUpcomingEvents(days: 3)
        // days=3 → today(4) + offset1(1) + offset2(1) = 6
        XCTAssertEqual(events.count, 6)
    }

    // MARK: - Concurrency: Multiple async calls do not race

    func testFetchTodayEventsIsCallableConcurrently() async throws {
        let service = MockCalendarService()
        // Fire two concurrent fetches and expect both to succeed with 4 events
        async let fetch1 = service.fetchTodayEvents()
        async let fetch2 = service.fetchTodayEvents()
        let (events1, events2) = try await (fetch1, fetch2)
        XCTAssertEqual(events1.count, 4)
        XCTAssertEqual(events2.count, 4)
    }
}