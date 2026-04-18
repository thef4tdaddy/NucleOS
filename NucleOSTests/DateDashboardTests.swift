//
//  DateDashboardTests.swift
//  NucleOSTests
//
//  Unit tests for Date+Dashboard.swift extension helpers.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Date Dashboard Extensions")
struct DateDashboardTests {

    // MARK: - startOfToday

    @Test("startOfToday is at midnight")
    func startOfTodayIsAtMidnight() {
        let start = Date.startOfToday
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("startOfToday is on current day")
    func startOfTodayIsOnCurrentDay() {
        let start = Date.startOfToday
        let now = Date()
        let calendar = Calendar.current
        #expect(
            calendar.dateComponents([.year, .month, .day], from: start) ==
            calendar.dateComponents([.year, .month, .day], from: now)
        )
    }

    @Test("startOfToday is past or equal to now")
    func startOfTodayIsPastOrEqualToNow() {
        let start = Date.startOfToday
        #expect(start <= Date())
    }

    @Test("startOfToday is within 24 hours of now")
    func startOfTodayIsWithin24HoursOfNow() {
        let start = Date.startOfToday
        let now = Date()
        #expect(start > now.addingTimeInterval(-86400))
    }

    // MARK: - lastNightRange

    @Test("lastNightRange start is yesterday at 18:00")
    func lastNightRangeStartIsYesterday6PM() {
        let (start, _) = Date.lastNightRange()
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 18)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("lastNightRange end is today at 10:00")
    func lastNightRangeEndIsToday10AM() {
        let (_, end) = Date.lastNightRange()
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 10)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("lastNightRange start date is yesterday")
    func lastNightRangeStartIsYesterdayDate() {
        let (start, _) = Date.lastNightRange()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let startDay = calendar.startOfDay(for: start)
        #expect(startDay == yesterday)
    }

    @Test("lastNightRange end date is today")
    func lastNightRangeEndIsTodayDate() {
        let (_, end) = Date.lastNightRange()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDay = calendar.startOfDay(for: end)
        #expect(endDay == today)
    }

    @Test("lastNightRange start is before end")
    func lastNightRangeStartIsBeforeEnd() {
        let (start, end) = Date.lastNightRange()
        #expect(start < end)
    }

    @Test("lastNightRange duration is approximately 16 hours")
    func lastNightRangeDurationIsApproximately16Hours() {
        let (start, end) = Date.lastNightRange()
        let duration = end.timeIntervalSince(start)
        #expect(abs(duration - 16 * 3600) <= 60)
    }

    @Test("lastNightRange tuple start < end")
    func lastNightRangeReturnsTupleWithCorrectOrder() {
        let range = Date.lastNightRange()
        #expect(range.start < range.end)
    }

    // MARK: - last24HoursRange

    @Test("last24HoursRange end is approximately now")
    func last24HoursRangeEndIsApproximatelyNow() {
        let before = Date()
        let (_, end) = Date.last24HoursRange()
        let after = Date()
        #expect(end >= before)
        #expect(end <= after)
    }

    @Test("last24HoursRange spans approximately 24 hours")
    func last24HoursRangeStartIsApproximately24HoursAgo() {
        let (start, end) = Date.last24HoursRange()
        let duration = end.timeIntervalSince(start)
        #expect(abs(duration - 86400) <= 3600)
    }

    @Test("last24HoursRange start is before end")
    func last24HoursRangeStartIsBeforeEnd() {
        let (start, end) = Date.last24HoursRange()
        #expect(start < end)
    }

    @Test("last24HoursRange tuple start < end")
    func last24HoursRangeReturnsTupleWithCorrectOrder() {
        let range = Date.last24HoursRange()
        #expect(range.start < range.end)
    }

    // MARK: - Consistency between helpers

    @Test("startOfToday is within last 24 hours range")
    func startOfTodayIsWithinLast24Hours() {
        let startOfToday = Date.startOfToday
        let (rangeStart, _) = Date.last24HoursRange()
        #expect(startOfToday >= rangeStart)
    }

    @Test("lastNightRange end is on today's date")
    func lastNightEndIsOnTodayDate() {
        let (_, lastNightEnd) = Date.lastNightRange()
        let now = Date()
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: lastNightEnd)
        #expect(todayComponents.year == endComponents.year)
        #expect(todayComponents.month == endComponents.month)
        #expect(todayComponents.day == endComponents.day)
    }
}
