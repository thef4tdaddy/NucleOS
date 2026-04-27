//
//  NucleTask.swift
//  NucleOS
//
//  Data model representing a task sourced from Reminders
//

import Foundation

/// A task sourced from the user's Apple Reminders, surfaced in NucleOS.
struct NucleTask: Identifiable, Equatable, Sendable {
    /// Stable identifier used to correlate tasks across reloads.
    let id: UUID
    /// User-visible title of the reminder.
    var title: String
    /// Whether the reminder has been marked complete.
    var isCompleted: Bool
    /// The date and time the task is due, if set.
    var dueDate: Date?
    /// The date and time the task was completed, if available from EventKit.
    var completionDate: Date?
    /// Optional free-form notes attached to the reminder.
    var notes: String?
    /// Relative importance of the task.
    var priority: Priority
    /// Optional category/tag for the task.
    var category: TaskCategory?
    /// Whether this task repeats (simple recurrence flag).
    var isRecurring: Bool
    /// EventKit calendar item identifier for stable cross-reload lookups.
    var calendarItemIdentifier: String
    /// EKCalendar identifier of the Reminders list this task belongs to (NUC-73).
    var listIdentifier: String?

    enum Priority: Int, CaseIterable, Hashable, Sendable {
        case none = -1
        case low = 0
        case medium = 1
        case high = 2
    }

    nonisolated init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        completionDate: Date? = nil,
        notes: String? = nil,
        priority: Priority = .medium,
        category: TaskCategory? = nil,
        isRecurring: Bool = false,
        calendarItemIdentifier: String = "",
        listIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.completionDate = completionDate
        self.notes = notes
        self.priority = priority
        self.category = category
        self.isRecurring = isRecurring
        self.calendarItemIdentifier = calendarItemIdentifier
        self.listIdentifier = listIdentifier
    }

    static func == (lhs: NucleTask, rhs: NucleTask) -> Bool {
        lhs.id == rhs.id
    }
}

/// Category tags for tasks.
enum TaskCategory: String, CaseIterable, Sendable, Identifiable {
    case personal, work, shopping, health, finance, home, travel, other
    var id: String { rawValue }
}
