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
    /// Produces a date range representing the conventional "last night" sleep window.
    /// 
    /// The range follows the convention: yesterday at 18:00 (6:00 PM) through today at 10:00 (10:00 AM).
    /// Computations use `Calendar.current` and the user's current time zone; if calendar-based date
    /// construction fails, the function falls back to the nearest available day values.
    /// - Returns: A tuple where `start` is yesterday at 18:00 and `end` is today at 10:00.
    static func lastNightRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Yesterday 18:00 (6 PM)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday) ?? yesterday

        // Today 10:00 (10 AM)
        let end = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today

        return (start, end)
    }

    /// Returns the date interval covering the past 24 hours ending at the current time.
    /// 
    /// The `start` is computed as one calendar day before `end` using `Calendar.current`; if that computation fails, `start` falls back to `end` minus 86,400 seconds.
    /// - Returns: A tuple `(start: Date, end: Date)` where `end` is now and `start` is approximately 24 hours before `end`.
    static func last24HoursRange() -> (start: Date, end: Date) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end.addingTimeInterval(-86400)
        return (start, end)
    }
}
