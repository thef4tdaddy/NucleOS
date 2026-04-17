//
//  StatsComponents.swift
//  NucleOS
//
//  Stats row and stat cards
//

import SwiftUI

/// Horizontal row of four ``StatCard`` views populated from live Reminders and Calendar data.
struct StatsRowView: View {
    @State private var tasksToday = 0
    @State private var completedToday = 0
    @State private var eventsToday = 0
    @State private var completedThisWeek = 0

    private let remindersService = RemindersService()
    private let calendarService = CalendarService()

    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                label: "Tasks Today",
                value: "\(tasksToday)",
                subtitle: "\(completedToday) completed"
            )
            StatCard(
                label: "Events",
                value: "\(eventsToday)",
                subtitle: eventsToday > 0 ? "Today" : "No events"
            )
            StatCard(
                label: "Completed This Week",
                value: "\(completedThisWeek)",
                subtitle: completedThisWeek > 0 ? "Tasks done" : "No tasks"
            )
            StatCard(
                label: "Focus Time",
                value: "—",
                subtitle: "Coming soon"
            )
        }
        .task(priority: .userInitiated) {
            await loadStats()
        }
    }

    /// Fetches tasks and events concurrently and updates the four stat counters.
    private func loadStats() async {
        // Load tasks
        do {
            let tasks = try await remindersService.fetchTasks()

            tasksToday = tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, inSameDayAs: Date())
            }.count

            // Use completionDate instead of dueDate for completed metrics
            completedToday = tasks.filter { task in
                guard task.isCompleted, let completionDate = task.completionDate else { return false }
                return Calendar.current.isDateInToday(completionDate)
            }.count

            completedThisWeek = tasks.filter { task in
                guard task.isCompleted else { return false }
                return isInCurrentWeek(task.completionDate)
            }.count
        } catch {
            print("Error loading task stats: \(error)")
        }

        // Load events
        do {
            let events = try await calendarService.fetchTodayEvents()
            eventsToday = events.count
        } catch {
            print("Error loading event stats: \(error)")
        }
    }

    /// Returns `true` if `date` falls within the same ISO week as today.
    private func isInCurrentWeek(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

/// A single labelled metric card used inside ``StatsRowView``.
struct StatCard: View {
    /// Short label displayed above the value.
    let label: String
    /// Primary numeric or text value.
    let value: String
    /// Contextual subtitle displayed below the value.
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textMuted)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
    }
}
