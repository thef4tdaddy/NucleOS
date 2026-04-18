//
//  RemindersService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Reminders / EventKit tasks
//

import EventKit
import Foundation

// MARK: - Protocol

/// Declares the async interface for fetching and mutating Reminders tasks.
protocol RemindersServiceProtocol {
    /// Returns all reminders from every Reminders list the user owns.
    func fetchTasks() async throws -> [NucleTask]
    /// Saves a new reminder to the default Reminders list.
    func addTask(_ task: NucleTask) async throws
    /// Marks an existing reminder as complete.
    func completeTask(_ task: NucleTask) async throws
    /// Permanently removes a reminder.
    func deleteTask(_ task: NucleTask) async throws
}

// MARK: - Errors

/// Errors that can be thrown by ``RemindersServiceProtocol`` implementations.
enum RemindersServiceError: LocalizedError {
    /// Access to Reminders was not granted by the user.
    case permissionDenied
    /// An underlying EventKit error prevented the fetch.
    case fetchFailed(Error)
    /// EventKit's fetch callback returned `nil`, indicating an internal failure.
    case fetchReturnedNil
    /// The requested operation has not been implemented yet.
    case unimplemented

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Reminders access was denied. Please grant permission in System Settings."
        case .fetchFailed(let error):
            return "Failed to fetch reminders: \(error.localizedDescription)"
        case .fetchReturnedNil:
            return "Failed to fetch reminders: EventKit returned nil"
        case .unimplemented:
            return "This feature is not implemented yet."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that integrates with EventKit Reminders.
@MainActor
class RemindersService: RemindersServiceProtocol {
    private var eventStore: EKEventStore { permissionsManager.eventStore }
    private let permissionsManager = PermissionsManager.shared

    /// Fetches all reminders from EventKit, requesting permission if not yet determined.
    func fetchTasks() async throws -> [NucleTask] {
        try await SentryConfig.traced(operation: "db.query", name: "RemindersService.fetchTasks") {
        // Check and request permissions if needed
        if permissionsManager.remindersAuthStatus == .notDetermined {
            _ = await permissionsManager.requestRemindersAccess()
        }

        guard permissionsManager.hasRemindersAccess else {
            throw RemindersServiceError.permissionDenied
        }

        do {
            let calendars = eventStore.calendars(for: .reminder)
            let predicate = eventStore.predicateForReminders(in: calendars)

            let ekReminders = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<[EKReminder], Error>) in
                eventStore.fetchReminders(matching: predicate) { ekReminders in
                    if let ekReminders = ekReminders {
                        continuation.resume(returning: ekReminders)
                    } else {
                        // nil indicates a fetch failure, not an empty result
                        continuation.resume(throwing: RemindersServiceError.fetchReturnedNil)
                    }
                }
            }

            return ekReminders.compactMap { convertToNucleTask(from: $0) }
        } catch {
            throw RemindersServiceError.fetchFailed(error)
        }
        }
    }

    /// Not yet implemented; throws ``RemindersServiceError/unimplemented``.
    func addTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    /// Not yet implemented; throws ``RemindersServiceError/unimplemented``.
    func completeTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    /// Not yet implemented; throws ``RemindersServiceError/unimplemented``.
    func deleteTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    // MARK: - Private Helpers

    /// Converts an `EKReminder` into a ``NucleTask``, or returns `nil` if the title is missing.
    private func convertToNucleTask(from ekReminder: EKReminder) -> NucleTask? {
        guard let title = ekReminder.title, !title.isEmpty else {
            return nil
        }

        // Map priority according to RFC5545:
        // 0 = undefined/none, 1-4 = high, 5 = medium, 6-9 = low
        let priority: NucleTask.Priority
        switch ekReminder.priority {
        case 0:
            priority = .none
        case 1...4:
            priority = .high
        case 5:
            priority = .medium
        case 6...9:
            priority = .low
        default:
            priority = .none
        }

        return NucleTask(
            title: title,
            isCompleted: ekReminder.isCompleted,
            dueDate: ekReminder.dueDateComponents?.date,
            completionDate: ekReminder.completionDate,
            notes: ekReminder.notes,
            priority: priority
        )
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
/// Declared as an `actor` so concurrent async calls cannot introduce data races on `tasks`.
actor MockRemindersService: RemindersServiceProtocol {

    private var tasks: [NucleTask] = MockData.tasks

    /// Returns the in-memory task list.
    func fetchTasks() async throws -> [NucleTask] {
        return tasks
    }

    /// Appends `task` to the in-memory list.
    func addTask(_ task: NucleTask) async throws {
        tasks.append(task)
    }

    /// Marks the task with the matching `id` as completed.
    func completeTask(_ task: NucleTask) async throws {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = tasks[index]
        updated.isCompleted = true
        tasks[index] = updated
    }

    /// Removes the task with the matching `id` from the in-memory list.
    func deleteTask(_ task: NucleTask) async throws {
        tasks.removeAll { $0.id == task.id }
    }
}
