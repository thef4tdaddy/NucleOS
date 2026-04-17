//
//  Date+Dashboard.swift
//  NucleOS
//
//  Date range helpers used by the HealthKit query layer for dashboard summaries.
//

import Foundation

extension Date {

    /// Midnight (00:00:00) at the start of the current calendar day in the user's time zone.
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Returns the [start, end) range covering last night's sleep window.
    ///
    /// Convention: yesterday 6 PM → today 10 AM.  This captures a full night
    /// including early-morning hours while excluding daytime naps.
    static func lastNightRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Yesterday at start of day
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        // DST-safe matching: locate yesterday 18:00
        var startComponents = DateComponents()
        startComponents.hour = 18
        startComponents.minute = 0
        startComponents.second = 0
        guard let start = calendar.nextDate(after: yesterday.addingTimeInterval(-1), matching: startComponents, matchingPolicy: .nextTime) else {
            print("⚠️ lastNightRange: Failed to match 18:00 on yesterday, falling back to yesterday start of day")
            return (yesterday, today)
        }

        // DST-safe matching: locate today 10:00
        var endComponents = DateComponents()
        endComponents.hour = 10
        endComponents.minute = 0
        endComponents.second = 0
        guard let end = calendar.nextDate(after: today.addingTimeInterval(-1), matching: endComponents, matchingPolicy: .nextTime) else {
            print("⚠️ lastNightRange: Failed to match 10:00 on today, falling back to start + 16h")
            return (start, start.addingTimeInterval(16 * 3600))
        }

        return (start, end)
    }

    /// The past 24 hours: from 24 hours ago to now.
    static func last24HoursRange() -> (start: Date, end: Date) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end.addingTimeInterval(-86400)
        return (start, end)
    }
}