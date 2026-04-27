//
//  TasksView.swift
//  NucleOS
//
//  Full tasks view with read-only reminders from EventKit.
//  NUC-73: Reminders list filter chips
//

import SwiftUI
import EventKit

/// Full-page view that displays all Reminders tasks, grouped into incomplete and completed sections.
struct TasksView: View {
    @State private var tasks: [NucleTask] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showCompleted = false
    @State private var permissionDenied = false
    @State private var currentLoadTask: Task<Void, Never>?
    @State private var isCreatingTask = false
    @State private var searchText = ""
    @State private var showingQuickAdd = false
    @State private var quickAddText = ""

    // NUC-73: list filter
    @State private var reminderLists: [EKCalendar] = []
    @State private var selectedListID: String? = nil   // nil = All Lists

    private let remindersService = RemindersService()

    private var filteredTasks: [NucleTask] {
        var result = tasks
        // List filter
        if let listID = selectedListID {
            result = result.filter { $0.listIdentifier == listID }
        }
        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return result
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
                    ProgressView().tint(.accentPrimary)
                }

                Button(action: { showingQuickAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Quick add task")

                Button(action: { isCreatingTask = true }) {
                    Image(systemName: "square.and.pencil").foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Add task")

                Button(action: {
                    currentLoadTask?.cancel()
                    currentLoadTask = Task { await loadTasks() }
                }) {
                    Image(systemName: "arrow.clockwise").foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Refresh tasks")
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)

            // NUC-73: List filter chips
            if !reminderLists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ListFilterChip(
                            title: "All Lists",
                            color: .accentPrimary,
                            isSelected: selectedListID == nil,
                            action: {
                                selectedListID = nil
                                persistListFilter(nil)
                            }
                        )
                        ForEach(reminderLists, id: \.calendarIdentifier) { list in
                            ListFilterChip(
                                title: list.title,
                                color: Color(cgColor: list.cgColor),
                                isSelected: selectedListID == list.calendarIdentifier,
                                action: {
                                    selectedListID = list.calendarIdentifier
                                    persistListFilter(list.calendarIdentifier)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                }
            }

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
                            Image(systemName: "xmark.circle.fill").foregroundColor(.textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.backgroundCard))
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }

            Divider().background(Color.border)

            // Content
            if permissionDenied {
                PermissionBanner(permission: .reminders)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                Spacer()
            } else if let error = error {
                ErrorStateView(message: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tasks.isEmpty && !isLoading {
                EmptyStateView(message: "No tasks found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        if !incompleteTasks.isEmpty {
                            TasksSection(title: "Incomplete", tasks: incompleteTasks, icon: "circle")
                        }

                        if !completedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) { showCompleted.toggle() }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textMuted)
                                        Text("Completed (\(completedTasks.count))")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.textSecondary)
                                            .tracking(0.5)
                                    }
                                }
                                .buttonStyle(.plain)

                                if showCompleted {
                                    VStack(spacing: 8) {
                                        ForEach(completedTasks) { task in
                                            TaskCardView(task: task)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $isCreatingTask) {
            TaskFormView(task: nil, isPresented: $isCreatingTask)
                .frame(minWidth: 480, minHeight: 520)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddEventView(text: $quickAddText, isPresented: $showingQuickAdd)
                .frame(minWidth: 440, minHeight: 380)
        }
        .task(priority: .userInitiated) { await loadTasks() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemindersDataChanged"))) { _ in
            currentLoadTask?.cancel()
            currentLoadTask = Task { await loadTasks() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if permissionDenied {
                currentLoadTask?.cancel()
                currentLoadTask = Task { await loadTasks() }
            }
        }
        .onAppear { loadListFilter() }
    }

    private var incompleteTasks: [NucleTask] { filteredTasks.filter { !$0.isCompleted } }
    private var completedTasks: [NucleTask]  { filteredTasks.filter { $0.isCompleted } }

    private func loadTasks() async {
        guard !Task.isCancelled else { return }
        isLoading = true
        error = nil
        permissionDenied = false

        do {
            tasks = try await remindersService.fetchTasks()
            // Refresh list after tasks load (calendars available after permission granted)
            reminderLists = remindersService.fetchReminderLists()
        } catch RemindersServiceError.permissionDenied {
            permissionDenied = true
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
        currentLoadTask = nil
    }

    private func loadListFilter() {
        reminderLists = remindersService.fetchReminderLists()
        selectedListID = UserDefaults.standard.string(forKey: "selected_task_list_id")
    }

    private func persistListFilter(_ id: String?) {
        if let id {
            UserDefaults.standard.set(id, forKey: "selected_task_list_id")
        } else {
            UserDefaults.standard.removeObject(forKey: "selected_task_list_id")
        }
    }
}

// MARK: - List filter chip (NUC-73)

struct ListFilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentPrimary : Color.backgroundCard
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tasks section

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
                ForEach(tasks) { task in
                    TaskCardView(task: task)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Task card

struct TaskCardView: View {
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
            HStack {
                Spacer()
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                Button(action: toggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .accentPrimary : .textMuted)
                }
                .buttonStyle(.plain)
                .help(task.isCompleted ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(task.isCompleted ? .textMuted : .textPrimary)
                        .strikethrough(task.isCompleted)

                    HStack(spacing: 12) {
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar").font(.system(size: 10))
                                Text(formatDueDate(dueDate)).font(.system(size: 12))
                            }
                            .foregroundColor(isOverdue(dueDate) ? .red : .textMuted)
                        }

                        if task.priority == .high {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill").font(.system(size: 10))
                                Text("High Priority").font(.system(size: 12))
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
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            )
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        if g.translation.width < 0 {
                            offset = CGSize(width: max(-80, g.translation.width), height: 0)
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
                withAnimation(.easeInOut) { offset = .zero; isSwiped = false }
            }
            .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Delete Task", role: .destructive) {
                    Task { try? await remindersProvider.deleteTask(task) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInTomorrow(date)  { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Date() && !task.isCompleted
    }

    private func toggleComplete() {
        Task {
            var updated = task
            updated.isCompleted.toggle()
            if updated.isCompleted {
                try? await remindersProvider.completeTask(updated)
            }
        }
    }
}

#Preview {
    TasksView()
}
