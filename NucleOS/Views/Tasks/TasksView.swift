//
//  TasksView.swift
//  NucleOS
//
//  Full tasks view with read-only reminders from EventKit
//

import SwiftUI

/// Full-page view that displays all Reminders tasks, grouped into incomplete and completed sections.
struct TasksView: View {
    @State private var tasks: [NucleTask] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCompleted = false
    @State private var permissionDenied = false
    @State private var currentLoadTask: Task<Void, Never>?

    private let remindersService = RemindersService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image("icon-tasks")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tasks")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        if !tasks.isEmpty {
                            Text("\(incompleteTasks.count) incomplete, \(completedTasks.count) completed")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(.accentPrimary)
                }

                Button(action: {
                    currentLoadTask?.cancel()
                    currentLoadTask = Task { await loadTasks() }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()
                .background(Color.border)

            // Content
            if permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 48))
                        .foregroundColor(.textMuted)

                    Text("Grant Reminders access to see your tasks")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                    }, label: {
                        Text("Open System Settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentPrimary)
                    })
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let error = error {
                ErrorStateView(message: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tasks.isEmpty && !isLoading {
                EmptyStateView(message: "No tasks found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(content: {
                    VStack(spacing: 32) {
                        // Incomplete Tasks Section
                        if !incompleteTasks.isEmpty {
                            TasksSection(
                                title: "Incomplete",
                                tasks: incompleteTasks,
                                icon: "circle"
                            )
                        }

                        // Completed Tasks Section
                        if !completedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showCompleted.toggle()
                                    }
                                }, label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textMuted)

                                        Text("Completed (\(completedTasks.count))")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.textSecondary)
                                            .tracking(0.5)
                                    }
                                })
                                .buttonStyle(.plain)

                                if showCompleted {
                                    VStack(spacing: 8) {
                                        ForEach(completedTasks, content: { task in
                                            TaskCardView(task: task)
                                        })
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.vertical, 24)
                })
            }
        }
        .background(Color.backgroundPrimary)
        .task(priority: .userInitiated) {
            await loadTasks()
        }
    }

    /// Tasks that have not yet been marked complete.
    private var incompleteTasks: [NucleTask] {
        tasks.filter { !$0.isCompleted }
    }

    /// Tasks that have been marked complete.
    private var completedTasks: [NucleTask] {
        tasks.filter { $0.isCompleted }
    }

    /// Fetches all tasks from Reminders; sets `permissionDenied` if access is not granted.
    /// Cancels any in-progress load before starting.
    private func loadTasks() async {
        // Early exit if task was cancelled
        guard !Task.isCancelled else { return }

        isLoading = true
        error = nil
        permissionDenied = false

        do {
            tasks = try await remindersService.fetchTasks()
        } catch RemindersServiceError.permissionDenied {
            permissionDenied = true
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
        currentLoadTask = nil
    }
}

/// A titled section of ``TaskCardView`` rows with an icon label.
struct TasksSection: View {
    /// Section heading (uppercased before display).
    let title: String
    /// Tasks to render.
    let tasks: [NucleTask]
    /// SF Symbol name shown next to the section title.
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)

                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 8) {
                ForEach(tasks, content: { task in
                    TaskCardView(task: task)
                })
            }
            .padding(.horizontal, 32)
        }
    }
}

/// A full-width card displaying a single task's title, due date, and priority badge.
struct TaskCardView: View {
    /// The task to display.
    let task: NucleTask

    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.isCompleted ? .accentPrimary : .textMuted)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isCompleted ? .textMuted : .textPrimary)
                    .strikethrough(task.isCompleted)

                HStack(spacing: 12) {
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))

                            Text(formatDueDate(dueDate))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : .textMuted)
                    }

                    // Only show priority badge for high priority (hide .none, .low, .medium)
                    if task.priority == .high {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10))

                            Text("High Priority")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.accentLavender)
                    }
                }
            }

            Spacer()
        }
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

    /// Returns a relative date label ("Today", "Tomorrow", "Yesterday") or a medium-style date string.
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    /// Returns `true` if `date` is in the past and the task is not yet complete.
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

#Preview {
    TasksView()
}
