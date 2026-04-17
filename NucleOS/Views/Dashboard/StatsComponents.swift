//
//  StatsComponents.swift
//  NucleOS
//
//  Stats row and stat cards
//

import SwiftUI

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

    private func loadStats() async {
        // Load tasks
        do {
            let tasks = try await remindersService.fetchTasks()

            tasksToday = tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, inSameDayAs: Date())
            }.count

            completedToday = tasks.filter { task in
                task.isCompleted &&
                Calendar.current.isDateInToday(task.dueDate ?? Date.distantPast)
            }.count

            completedThisWeek = tasks.filter { task in
                task.isCompleted &&
                isInCurrentWeek(task.dueDate)
            }.count
        } catch {
            // Silently fall back to 0
        }

        // Load events
        do {
            let events = try await calendarService.fetchTodayEvents()
            eventsToday = events.count
        } catch {
            // Silently fall back to 0
        }
    }

    private func isInCurrentWeek(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

struct StatCard: View {
    let label: String
    let value: String
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
