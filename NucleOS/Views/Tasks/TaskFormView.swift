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
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)

                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.border, lineWidth: 1)
                        )
                }

                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(NucleTask.Priority.none)
                        Text("Low").tag(NucleTask.Priority.low)
                        Text("Medium").tag(NucleTask.Priority.medium)
                        Text("High").tag(NucleTask.Priority.high)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                        .toggleStyle(.switch)

                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }

                Section(header: Text("Options")) {
                    Toggle("Repeat Daily", isOn: $isRecurring)
                        .toggleStyle(.switch)

                    Picker("Category", selection: $category) {
                        Text("None").tag(TaskCategory?.none)
                        ForEach(TaskCategory.allCases) { category in
                            Text(category.rawValue.capitalized).tag(TaskCategory?.some(category))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTask) {
                        Text(task == nil ? "Create" : "Save")
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $error.isNotEmpty, actions: {
                Button("OK", role: .cancel) { }
            }) {
                Text(error ?? "")
            }
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