//
//  RemindersService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for Reminders / EventKit tasks
//

import EventKit
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
    case permissionDenied
    case fetchFailed(Error)
    case fetchReturnedNil
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

    func fetchTasks() async throws -> [NucleTask] {
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

    func addTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    func completeTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    func deleteTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.unimplemented
    }

    // MARK: - Private Helpers

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

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
/// Declared as an `actor` so concurrent async calls cannot introduce data races on `tasks`.
actor MockRemindersService: RemindersServiceProtocol {

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
        var updated = tasks[index]
        updated.isCompleted = true
        tasks[index] = updated
    }

    func deleteTask(_ task: NucleTask) async throws {
        tasks.removeAll { $0.id == task.id }
    }
}