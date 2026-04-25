//
//  RemindersServiceTests.swift
//  NucleOSTests
//
//  Swift Testing suite for RemindersService
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Reminders Service")
struct RemindersServiceTests {

    @Test("Mock service returns tasks")
    func mockServiceReturnsTasks() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        #expect(!tasks.isEmpty)
    }

    @Test("Mock service can add task")
    func mockServiceCanAddTask() async throws {
        let service = MockRemindersService()
        let newTask = NucleTask(title: "New Task")

        try await service.addTask(newTask)

        let tasks = try await service.fetchTasks()
        #expect(tasks.contains(where: { $0.title == "New Task" }))
    }

    @Test("Mock service can complete task")
    func mockServiceCanCompleteTask() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let task = try #require(tasks.first)

        try await service.completeTask(task)

        let updatedTasks = try await service.fetchTasks()
        let updatedTask = try #require(updatedTasks.first(where: { $0.id == task.id }))
        #expect(updatedTask.isCompleted)
    }

    @Test("Mock service can delete task")
    func mockServiceCanDeleteTask() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let task = try #require(tasks.first)

        try await service.deleteTask(task)

        let updatedTasks = try await service.fetchTasks()
        #expect(!updatedTasks.contains(where: { $0.id == task.id }))
    }

    @Test("NucleTask default initialization")
    func nucleTaskDefaultInitialization() {
        let task = NucleTask(title: "Test")

        #expect(task.title == "Test")
        #expect(task.isCompleted == false)
        #expect(task.dueDate == nil)
        #expect(task.completionDate == nil)
        #expect(task.notes == nil)
        #expect(task.priority == .medium)
    }

    @Test("NucleTask full initialization")
    func nucleTaskFullInitialization() {
        let dueDate = Date()

        let task = NucleTask(
            title: "Full Task",
            isCompleted: true,
            dueDate: dueDate,
            completionDate: dueDate,
            notes: "Notes",
            priority: .high
        )

        #expect(task.title == "Full Task")
        #expect(task.isCompleted == true)
        #expect(task.dueDate == dueDate)
        #expect(task.completionDate == dueDate)
        #expect(task.notes == "Notes")
        #expect(task.priority == .high)
    }

    @Test("NucleTask priority raw values")
    func nucleTaskPriorityRawValues() {
        #expect(NucleTask.Priority.none.rawValue == -1)
        #expect(NucleTask.Priority.low.rawValue == 0)
        #expect(NucleTask.Priority.medium.rawValue == 1)
        #expect(NucleTask.Priority.high.rawValue == 2)
    }

    @Test("NucleTask equality")
    func nucleTaskEquality() {
        let id = UUID()
        let task1 = NucleTask(id: id, title: "Same")
        let task2 = NucleTask(id: id, title: "Different")

        #expect(task1 == task2)
    }

    @Test("NucleTask sendable conformance")
    func nucleTaskSendable() {
        let task = NucleTask(title: "Sendable")
        let _ = task as Sendable
    }
}