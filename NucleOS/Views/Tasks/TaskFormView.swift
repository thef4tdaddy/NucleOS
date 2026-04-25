//
//  TaskFormView.swift
//  NucleOS
//
//  Form for creating and editing reminders tasks
//

import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    let task: NucleTask?
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var notes = ""
    @State private var priority: NucleTask.Priority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var isRecurring = false
    @State private var category: TaskCategory?
    @State private var isLoading = false
    @State private var error: String?

    private let remindersService = RemindersService()

    init(task: NucleTask?, isPresented: Binding<Bool>) {
        self.task = task
        self._isPresented = isPresented

        if let task = task {
            _title = State(initialValue: task.title)
            _notes = State(initialValue: task.notes ?? "")
            _priority = State(initialValue: task.priority)
            if let dueDate = task.dueDate {
                _dueDate = State(initialValue: dueDate)
                _hasDueDate = State(initialValue: true)
            }
            _isRecurring = State(initialValue: task.isRecurring)
            _category = State(initialValue: task.category)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // NucleOS branded header — no macOS window chrome
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.backgroundCard)
                    .foregroundColor(.textSecondary)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))

                Spacer()

                Text(task == nil ? "New Task" : "Edit Task")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                if isLoading {
                    ProgressView().tint(.accentPrimary).scaleEffect(0.8)
                } else {
                    Button(task == nil ? "Create" : "Save") { saveTask() }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(title.isEmpty ? Color.accentPrimary.opacity(0.35) : Color.accentPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(title.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.backgroundCard)

            Divider().background(Color.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    formSection(title: "Task Details") {
                        VStack(alignment: .leading, spacing: 16) {
                            FormTextField(title: "Title", text: $title, placeholder: "Task title")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.backgroundCard)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))
                                    )
                            }
                        }
                    }

                    formSection(title: "Priority") {
                        Picker("", selection: $priority) {
                            Text("None").tag(NucleTask.Priority.none)
                            Text("Low").tag(NucleTask.Priority.low)
                            Text("Medium").tag(NucleTask.Priority.medium)
                            Text("High").tag(NucleTask.Priority.high)
                        }
                        .pickerStyle(.segmented)
                    }

                    formSection(title: "Due Date") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Set Due Date", isOn: $hasDueDate).toggleStyle(.switch)
                            if hasDueDate {
                                DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                            }
                        }
                    }

                    formSection(title: "Options") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Repeat Daily", isOn: $isRecurring).toggleStyle(.switch)
                            Picker("Category", selection: $category) {
                                Text("None").tag(TaskCategory?.none)
                                ForEach(TaskCategory.allCases) { cat in
                                    Text(cat.rawValue.capitalized).tag(TaskCategory?.some(cat))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
        .alert("Error", isPresented: $error.isNotEmpty) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error ?? "")
        }
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            )
        }
    }

    private func saveTask() {
        guard !title.isEmpty else { return }
        isLoading = true
        error = nil

        let taskToSave = NucleTask(
            id: task?.id ?? UUID(),
            title: title,
            isCompleted: task?.isCompleted ?? false,
            dueDate: hasDueDate ? dueDate : nil,
            notes: notes.isEmpty ? nil : notes,
            priority: priority,
            category: category,
            isRecurring: isRecurring,
            calendarItemIdentifier: task?.calendarItemIdentifier ?? ""
        )

        Task {
            do {
                if task != nil {
                    try await remindersService.updateTask(taskToSave)
                } else {
                    try await remindersService.addTask(taskToSave)
                }
                dismiss()
            } catch {
                self.error = "Failed to save task: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
