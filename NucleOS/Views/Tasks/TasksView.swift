//
//  TasksView.swift
//  NucleOS
//
//  Full tasks view with read-only reminders from EventKit
//

import SwiftUI

struct TasksView: View {
    @State private var tasks: [NucleTask] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCompleted = false

    private let remindersService = RemindersService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
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

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(.accentPrimary)
                }

                Button(action: { Task { await loadTasks() } }, label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()
                .background(Color.border)

            // Content
            if let error = error {
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

    private var incompleteTasks: [NucleTask] {
        tasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [NucleTask] {
        tasks.filter { $0.isCompleted }
    }

    private func loadTasks() async {
        isLoading = true
        error = nil

        do {
            tasks = try await remindersService.fetchTasks()
        } catch RemindersServiceError.permissionDenied {
            // Fall back to mock data
            tasks = (try? await MockRemindersService().fetchTasks()) ?? []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct TasksSection: View {
    let title: String
    let tasks: [NucleTask]
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

struct TaskCardView: View {
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

    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

#Preview {
    TasksView()
}
