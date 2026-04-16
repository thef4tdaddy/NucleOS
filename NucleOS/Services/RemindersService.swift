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

// MARK: - Errors

enum RemindersServiceError: LocalizedError {
    case unimplemented

    var errorDescription: String? {
        switch self {
        case .unimplemented:
            return "RemindersService is not implemented yet. EventKit integration is still pending."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with EventKit Reminders.
class RemindersService: RemindersServiceProtocol {

    func fetchTasks() async throws -> [NucleTask] {
        // TODO: Request EventKit authorization and fetch reminders
        throw RemindersServiceError.unimplemented
    }

    func addTask(_ task: NucleTask) async throws {
        // TODO: Create EKReminder and save to default Reminders list
        throw RemindersServiceError.unimplemented
    }

    func completeTask(_ task: NucleTask) async throws {
        // TODO: Mark corresponding EKReminder as completed
        throw RemindersServiceError.unimplemented
    }

    func deleteTask(_ task: NucleTask) async throws {
        // TODO: Remove EKReminder from the store
        throw RemindersServiceError.unimplemented
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
/// Declared as an `actor` so concurrent async calls cannot introduce data races on `tasks`.
actor MockRemindersService: RemindersServiceProtocol {

    private var tasks: [NucleTask] = MockData.tasks

    func fetchTasks() async throws -> [NucleTask] {
        return tasks
    }

    func addTask(_ task: NucleTask) async throws {
        tasks.append(task)
    }

    func completeTask(_ task: NucleTask) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = tasks[index]
        updated.isCompleted = true
        tasks[index] = updated
    }

    func deleteTask(_ task: NucleTask) async throws {
        tasks.removeAll { $0.id == task.id }
    }
}
