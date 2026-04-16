//
//  MockData.swift
//  NucleOS
//
//  Centralized mock data for SwiftUI previews and development.
//  Tasks and events are computed properties so dates are always relative
//  to the current day — previews and long-lived sessions stay accurate.
//

import Foundation

enum MockData {

    // MARK: - Tasks

    /// Returns a fresh set of tasks relative to the current calendar day.
    static var tasks: [NucleTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        return [
            NucleTask(
                title: "Review quarterly goals",
                isCompleted: false,
                dueDate: today,
                notes: "Focus on Q3 OKRs",
                priority: .high
            ),
            NucleTask(
                title: "Update project documentation",
                isCompleted: true,
                dueDate: today,
                priority: .medium
            ),
            NucleTask(
                title: "Team sync at 2 PM",
                isCompleted: false,
                dueDate: today,
                priority: .high
            ),
            NucleTask(
                title: "Prepare presentation slides",
                isCompleted: false,
                dueDate: tomorrow,
                notes: "Include Q2 metrics and roadmap",
                priority: .medium
            ),
            NucleTask(
                title: "Code review for PR #234",
                isCompleted: true,
                dueDate: today,
                priority: .medium
            ),
            NucleTask(
                title: "Respond to design feedback",
                isCompleted: false,
                dueDate: today,
                priority: .low
            ),
            NucleTask(
                title: "Write unit tests for auth module",
                isCompleted: false,
                dueDate: tomorrow,
                priority: .high
            ),
        ]
    }

    // MARK: - Events

    /// Returns a fresh set of today's events relative to the current calendar day.
    static var events: [NucleEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func time(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        }

        return [
            NucleEvent(
                title: "Team Standup",
                startDate: time(hour: 9),
                endDate: time(hour: 9, minute: 30),
                calendarColor: .accentPrimary
            ),
            NucleEvent(
                title: "Product Review",
                startDate: time(hour: 11),
                endDate: time(hour: 12),
                calendarColor: .accentLavender,
                location: "Conference Room A"
            ),
            NucleEvent(
                title: "Lunch with Team",
                startDate: time(hour: 12, minute: 30),
                endDate: time(hour: 13, minute: 30),
                calendarColor: .accentLight,
                location: "Cafeteria"
            ),
            NucleEvent(
                title: "Design Sync",
                startDate: time(hour: 14),
                endDate: time(hour: 15),
                calendarColor: .accentLight
            ),
            NucleEvent(
                title: "1:1 with Manager",
                startDate: time(hour: 16, minute: 30),
                endDate: time(hour: 17),
                calendarColor: .custom("ff6b6b")
            ),
        ]
    }

    // MARK: - Health

    static let healthSnapshot = HealthSnapshot(
        steps: 8_234,
        stepGoal: 10_000,
        heartRate: 72.0,
        sleepDuration: (7 * 60 + 23) * 60,
        sleepGoal: 8 * 3600,
        activeCalories: 1_847,
        calorieGoal: 2_200
    )

    // MARK: - AI Briefing

    /// Returns a fresh briefing string reflecting the current mock data.
    static var aiBriefing: String {
        let snapshot = healthSnapshot
        let currentTasks = tasks
        let currentEvents = events
        return """
            Good morning! Here's your daily briefing:

            • You have \(currentEvents.count) events today, including a design sync at 2 PM.
            • You're \(Int(snapshot.stepsProgress * 100))% towards your step goal — consider a walk after lunch.
            • \(currentTasks.filter { !$0.isCompleted && $0.priority == .high }.count) high-priority tasks are still open today.
            • Your sleep was \(snapshot.sleepFormatted) last night, slightly below your \(snapshot.sleepGoalFormatted) goal.
            """
    }
}
