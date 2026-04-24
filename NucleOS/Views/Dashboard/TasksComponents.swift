//
//  TasksComponents.swift
//  NucleOS
//
//  Tasks panel and task row
//

import SwiftUI

/// Dashboard panel that lists the user's upcoming incomplete tasks from Reminders.
struct TasksPanelView: View {
    @State private var tasks: [NucleTask] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var permissionDenied = false

    private let remindersService = RemindersService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {}, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(true) // Disabled until add functionality is implemented
            }

            if isLoading && tasks.isEmpty {
                VStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in TaskShimmerRow() }
                }
            } else if permissionDenied {
                PermissionBanner(permission: .reminders)
            } else if let error = error {
                ErrorStateView(message: error, retry: {
                    Task { await loadTasks() }
                })
            } else if tasks.isEmpty {
                EmptyStateView(
                    message: "No tasks for today 🎉",
                    subtext: "Enjoy your free time"
                )
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
        .task(priority: .userInitiated) {
            await loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if permissionDenied {
                Task { await loadTasks() }
            }
        }
    }

    /// Fetches incomplete tasks from Reminders; sets `permissionDenied` if access is not granted.
    private func loadTasks() async {
        isLoading = true
        error = nil
        permissionDenied = false

        do {
            let allTasks = try await remindersService.fetchTasks()
            tasks = allTasks.filter { !$0.isCompleted }
        } catch RemindersServiceError.permissionDenied {
            permissionDenied = true
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

/// Full-screen prompt shown when the user has not granted Reminders or Calendar access.
struct PermissionDeniedView: View {
    /// SF Symbol name for the accompanying icon.
    let icon: String
    /// Short explanation of why access is needed.
    let message: String
    /// Action invoked when the user taps "Open System Settings".
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.textMuted)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: action, label: {
                Text("Open System Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentPrimary)
            })
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// A single compact task row used inside ``TasksPanelView``.
struct TaskRow: View {
    /// The task to display.
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

    /// Returns a short human-readable string for `date`: time-only if today, short date otherwise.
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

/// Placeholder shown when a list has no items to display.
struct EmptyStateView: View {
    let message: String
    var subtext: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.textMuted)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)

            if let subtext {
                Text(subtext)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Placeholder shown when a data fetch encounters an error, with an optional retry button.
struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.textMuted)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let retry {
                Button(action: retry) {
                    Text("Retry")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.12))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
