//
//  NucleTask.swift
//  NucleOS
//
//  Data model representing a task sourced from Reminders
//

import Foundation

struct NucleTask: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var notes: String?
    var priority: Priority

    enum Priority: Int, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
    }

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        notes: String? = nil,
        priority: Priority = .medium
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.notes = notes
        self.priority = priority
    }
}
