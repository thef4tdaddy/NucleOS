//
//  RemindersServiceTests.swift
//  NucleOSTests/Services
//
//  Swift Testing suite for RemindersService — mock-only, zero real Apple framework calls.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Reminders Service")
struct RemindersServiceSwiftTests {

    // MARK: - fetchTasks: basic

    @Test("fetchTasks returns non-empty array")
    func fetchTasksReturnsNonEmptyArray() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        #expect(!tasks.isEmpty)
    }

    @Test("fetchTasks returns tasks with valid id")
    func fetchTasksHaveValidID() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        for task in tasks {
            #expect(task.id.uuidString != "00000000-0000-0000-0000-000000000000")
        }
    }

    @Test("fetchTasks returns tasks with non-empty title")
    func fetchTasksHaveNonEmptyTitle() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        for task in tasks {
            #expect(!task.title.isEmpty)
        }
    }

    @Test("fetchTasks returns tasks with valid isCompleted — totals are consistent")
    func fetchTasksHaveIsCompleted() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let completedCount = tasks.filter(\.isCompleted).count
        let incompleteCount = tasks.filter { !$0.isCompleted }.count
        #expect(completedCount + incompleteCount == tasks.count)
    }

    @Test("completed tasks are flagged correctly")
    func completedTasksFlaggedCorrectly() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let completed = tasks.filter(\.isCompleted)
        let incomplete = tasks.filter { !$0.isCompleted }
        #expect(!completed.isEmpty, "Expected at least one completed task in mock data")
        #expect(!incomplete.isEmpty, "Expected at least one incomplete task in mock data")
    }

    @Test("empty list handled without crash via deleteAll")
    func emptyListHandledWithoutCrash() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        for task in tasks {
            try await service.deleteTask(task)
        }
        let remaining = try await service.fetchTasks()
        #expect(remaining.isEmpty)
    }

    // MARK: - Priority coverage

    @Test("Priority.none case exists with rawValue -1")
    func priorityNoneExists() {
        #expect(NucleTask.Priority.none.rawValue == -1)
    }

    @Test("Priority.low case exists with rawValue 0")
    func priorityLowExists() {
        #expect(NucleTask.Priority.low.rawValue == 0)
    }

    @Test("Priority.medium case exists with rawValue 1")
    func priorityMediumExists() {
        #expect(NucleTask.Priority.medium.rawValue == 1)
    }

    @Test("Priority.high case exists with rawValue 2")
    func priorityHighExists() {
        #expect(NucleTask.Priority.high.rawValue == 2)
    }

    @Test("All Priority cases covered via CaseIterable")
    func allPriorityCasesCovered() {
        let cases = NucleTask.Priority.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.none))
        #expect(cases.contains(.low))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.high))
    }

    // MARK: - addTask

    @Test("addTask appends to fetchTasks result")
    func addTaskAppendsToList() async throws {
        let service = MockRemindersService()
        let before = try await service.fetchTasks()
        let newTask = NucleTask(title: "Swift Testing Task", priority: .low)
        try await service.addTask(newTask)
        let after = try await service.fetchTasks()
        #expect(after.count == before.count + 1)
        #expect(after.contains(where: { $0.id == newTask.id }))
    }

    // MARK: - completeTask

    @Test("completeTask marks task as completed")
    func completeTaskMarksAsCompleted() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let incomplete = try #require(tasks.first(where: { !$0.isCompleted }))
        try await service.completeTask(incomplete)
        let updated = try await service.fetchTasks()
        let found = updated.first(where: { $0.id == incomplete.id })
        #expect(found?.isCompleted == true)
    }

    @Test("completeTask with unknown id does nothing")
    func completeTaskUnknownIDNoOp() async throws {
        let service = MockRemindersService()
        let before = try await service.fetchTasks()
        let ghost = NucleTask(title: "Ghost", priority: .none)
        try await service.completeTask(ghost)
        let after = try await service.fetchTasks()
        #expect(after.count == before.count)
    }

    // MARK: - deleteTask

    @Test("deleteTask removes task from list")
    func deleteTaskRemovesFromList() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let target = try #require(tasks.first)
        try await service.deleteTask(target)
        let after = try await service.fetchTasks()
        #expect(!after.contains(where: { $0.id == target.id }))
        #expect(after.count == tasks.count - 1)
    }
}
