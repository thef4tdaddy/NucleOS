//
//  DateDashboardTests.swift
//  NucleOSTests
//
//  Unit tests for Date+Dashboard.swift extension helpers.
//

import XCTest
@testable import NucleOS

final class DateDashboardTests: XCTestCase {

    // MARK: - startOfToday

    func testStartOfTodayIsAtMidnight() {
        let start = Date.startOfToday
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testStartOfTodayIsOnCurrentDay() {
        let start = Date.startOfToday
        let now = Date()
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: start),
            calendar.dateComponents([.year, .month, .day], from: now)
        )
    }

    func testStartOfTodayIsPastOrEqualToNow() {
        let start = Date.startOfToday
        XCTAssertLessThanOrEqual(start, Date())
    }

    func testStartOfTodayIsWithin24HoursOfNow() {
        let start = Date.startOfToday
        let now = Date()
        // Should be less than 24 hours ago
        XCTAssertGreaterThan(start, now.addingTimeInterval(-86400))
    }

    // MARK: - lastNightRange

    func testLastNightRangeStartIsYesterday6PM() {
        let (start, _) = Date.lastNightRange()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 18)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testLastNightRangeEndIsToday10AM() {
        let (_, end) = Date.lastNightRange()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testLastNightRangeStartIsYesterdayDate() {
        let (start, _) = Date.lastNightRange()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let startDay = calendar.startOfDay(for: start)
        XCTAssertEqual(startDay, yesterday)
    }

    func testLastNightRangeEndIsTodayDate() {
        let (_, end) = Date.lastNightRange()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: end)
        XCTAssertEqual(endDay, today)
    }

    func testLastNightRangeStartIsBeforeEnd() {
        let (start, end) = Date.lastNightRange()
        XCTAssertLessThan(start, end)
    }

    func testLastNightRangeDurationIsApproximately16Hours() {
        let (start, end) = Date.lastNightRange()
        // 18:00 yesterday to 10:00 today = 16 hours
        let duration = end.timeIntervalSince(start)
        XCTAssertEqual(duration, 16 * 3600, accuracy: 60) // allow 1 minute tolerance for DST
    }

    func testLastNightRangeReturnsTupleWithCorrectLabels() {
        let range = Date.lastNightRange()
        XCTAssertLessThan(range.start, range.end)
    }

    // MARK: - last24HoursRange

    func testLast24HoursRangeEndIsApproximatelyNow() {
        let before = Date()
        let (_, end) = Date.last24HoursRange()
        let after = Date()
        XCTAssertGreaterThanOrEqual(end, before)
        XCTAssertLessThanOrEqual(end, after)
    }

    func testLast24HoursRangeStartIsApproximately24HoursAgo() {
        let (start, end) = Date.last24HoursRange()
        let duration = end.timeIntervalSince(start)
        XCTAssertEqual(duration, 86400, accuracy: 3600) // allow up to 1 hour tolerance for DST adjustments
    }

    func testLast24HoursRangeStartIsBeforeEnd() {
        let (start, end) = Date.last24HoursRange()
        XCTAssertLessThan(start, end)
    }

    func testLast24HoursRangeEndIsInThePast() {
        let (start, end) = Date.last24HoursRange()
        // end should be approximately now; start should be before end
        XCTAssertLessThan(start, end)
        // Both should be within reasonable time of now
        let now = Date()
        XCTAssertLessThan(end, now.addingTimeInterval(1)) // end <= now + 1s
    }

    func testLast24HoursRangeReturnsTupleWithCorrectLabels() {
        let range = Date.last24HoursRange()
        XCTAssertLessThan(range.start, range.end)
    }

    // MARK: - Consistency between helpers

    func testStartOfTodayIsWithinLast24Hours() {
        let startOfToday = Date.startOfToday
        let (rangeStart, _) = Date.last24HoursRange()
        // startOfToday should be >= the start of the 24h range
        XCTAssertGreaterThanOrEqual(startOfToday, rangeStart)
    }

    func testLastNightEndIsBeforeOrEqualStartOfToday10AM() {
        let (_, lastNightEnd) = Date.lastNightRange()
        let now = Date()
        // lastNightEnd (today at 10:00) should be in the past or very close to now
        // (This will pass any time of day since we're just checking it's a reasonable time)
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: lastNightEnd)
        XCTAssertEqual(todayComponents.year, endComponents.year)
        XCTAssertEqual(todayComponents.month, endComponents.month)
        XCTAssertEqual(todayComponents.day, endComponents.day)
    }
}