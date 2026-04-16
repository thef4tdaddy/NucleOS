//
//  RemindersService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Reminders / EventKit tasks
//

import Foundation

// MARK: - Protocol

protocol RemindersServiceProtocol {
    func fetchTasks() async throws -> [NucleTask]
    func addTask(_ task: NucleTask) async throws
    func completeTask(_ task: NucleTask) async throws
    func deleteTask(_ task: NucleTask) async throws
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with EventKit Reminders.
class RemindersService: RemindersServiceProtocol {

    func fetchTasks() async throws -> [NucleTask] {
        // TODO: Request EventKit authorization and fetch reminders
        return []
    }

    func addTask(_ task: NucleTask) async throws {
        // TODO: Create EKReminder and save to default Reminders list
    }

    func completeTask(_ task: NucleTask) async throws {
        // TODO: Mark corresponding EKReminder as completed
    }

    func deleteTask(_ task: NucleTask) async throws {
        // TODO: Remove EKReminder from the store
    }
}

// MARK: - Mock Implementation

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
class MockRemindersService: RemindersServiceProtocol {

    private var tasks: [NucleTask] = [
        NucleTask(
            title: "Review quarterly goals",
            isCompleted: false,
            dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            priority: .high
        ),
        NucleTask(
            title: "Update project documentation",
            isCompleted: true,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            priority: .medium
        ),
        NucleTask(
            title: "Team sync at 2pm",
            isCompleted: false,
            dueDate: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
            priority: .medium
        ),
        NucleTask(
            title: "Prepare presentation slides",
            isCompleted: false,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            notes: "Focus on Q3 metrics and roadmap",
            priority: .high
        ),
        NucleTask(
            title: "Code review for PR #234",
            isCompleted: true,
            priority: .low
        ),
        NucleTask(
            title: "Schedule dentist appointment",
            isCompleted: false,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            priority: .low
        ),
        NucleTask(
            title: "Refactor auth module",
            isCompleted: false,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            notes: "See architecture doc for details",
            priority: .medium
        )
    ]

    func fetchTasks() async throws -> [NucleTask] {
        return tasks
    }

    func addTask(_ task: NucleTask) async throws {
        tasks.append(task)
    }

    func completeTask(_ task: NucleTask) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = true
    }

    func deleteTask(_ task: NucleTask) async throws {
        tasks.removeAll { $0.id == task.id }
    }
}
