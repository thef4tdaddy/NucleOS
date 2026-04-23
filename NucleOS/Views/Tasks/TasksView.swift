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
    @State private var isCreatingTask = false
    @State private var searchText = ""
    @State private var showingQuickAdd = false
    @State private var quickAddText = ""

    private let remindersService = RemindersService()

    private var filteredTasks: [NucleTask] {
        if searchText.isEmpty { return tasks }
        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

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

                Button(action: { showingQuickAdd = true }, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Quick add task")

                Button(action: { isCreatingTask = true }, label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Add task")

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

            // Search bar
            if !tasks.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textMuted)
                        .padding(.leading, 8)

                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.backgroundCard)
                )
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }

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
        .sheet(isPresented: $isCreatingTask) {
            TaskFormView(task: nil, isPresented: $isCreatingTask)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddEventView(text: $quickAddText, isPresented: $showingQuickAdd)
        }
        .task(priority: .userInitiated) {
            await loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemindersDataChanged"))) { _ in
            currentLoadTask?.cancel()
            currentLoadTask = Task { await loadTasks() }
        }
    }

    /// Tasks that have not yet been marked complete.
    private var incompleteTasks: [NucleTask] {
        filteredTasks.filter { !$0.isCompleted }
    }

    /// Tasks that have been marked complete.
    private var completedTasks: [NucleTask] {
        filteredTasks.filter { $0.isCompleted }
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
    @State private var showingDeleteConfirmation = false
    @State private var offset = CGSize.zero
    @State private var isSwiped = false
    @EnvironmentObject var appSettings: AppSettings

    private var remindersProvider: RemindersServiceProtocol {
        appSettings.useMockCalendarData ? MockRemindersService() : RemindersService()
    }

    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .frame(width: 80, height: .infinity)
                        .background(Color.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                // Checkbox
                Button(action: toggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .accentPrimary : .textMuted)
                }
                .buttonStyle(.plain)

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
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            offset = CGSize(width: max(-80, gesture.translation.width), height: 0)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut) {
                            if offset.width < -40 {
                                offset = CGSize(width: -80, height: 0)
                                isSwiped = true
                            } else {
                                offset = .zero
                                isSwiped = false
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.easeInOut) {
                    offset = .zero
                    isSwiped = false
                }
            }
            .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Delete Task", role: .destructive) {
                    Task {
                        try? await remindersProvider.deleteTask(task)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
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

    /// Toggles the completion state of this task.
    private func toggleComplete() {
        Task {
            var updatedTask = task
            updatedTask.isCompleted.toggle()
            if updatedTask.isCompleted {
                try? await remindersProvider.completeTask(updatedTask)
            }
        }
    }
}

#Preview {
    TasksView()
}
