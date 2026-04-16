//
//  TasksComponents.swift
//  NucleOS
//
//  Tasks panel and task row
//

import SwiftUI

struct TasksPanelView: View {
    @State private var tasks: [NucleTask] = []
    @State private var isLoading = false
    @State private var error: String?

    private let remindersService = RemindersService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.accentPrimary)
                }

                Button(action: {}, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(true) // Disabled until add functionality is implemented
            }

            if let error = error {
                ErrorStateView(message: error)
            } else if tasks.isEmpty && !isLoading {
                EmptyStateView(message: "No tasks found")
            } else {
                ScrollView(content: {
                    VStack(spacing: 12) {
                        ForEach(tasks.prefix(5), content: { task in
                            TaskRow(task: task)
                        })
                    }
                })
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
        .task(priority: .userInitiated, operation: {
            await loadTasks()
        })
    }

    private func loadTasks() async {
        isLoading = true
        error = nil

        do {
            let allTasks = try await remindersService.fetchTasks()
            tasks = allTasks.filter { !$0.isCompleted }
        } catch RemindersServiceError.permissionDenied {
            // Fall back to mock data
            tasks = try? await MockRemindersService().fetchTasks() ?? []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct TaskRow: View {
    let task: NucleTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .accentPrimary : .textMuted)
                .font(.system(size: 16))

            Text(task.title)
                .font(.system(size: 13))
                .foregroundColor(task.isCompleted ? .textMuted : .textPrimary)
                .strikethrough(task.isCompleted)

            Spacer()

            if let dueDate = task.dueDate {
                Text(formatDueDate(dueDate))
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
        }
        .padding(.vertical, 6)
    }

    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.textMuted)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.textMuted)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
