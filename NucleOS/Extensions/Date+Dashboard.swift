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

        // Yesterday 18:00 (6 PM)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday) ?? yesterday

        // Today 10:00 (10 AM)
        let end = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today

        return (start, end)
    }

    /// The past 24 hours: from 24 hours ago to now.
    static func last24HoursRange() -> (start: Date, end: Date) {
        let end = Date()
        let start = end.addingTimeInterval(-24 * 3600)
        return (start, end)
    }
}
