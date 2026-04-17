//
//  RemindersServiceTests.swift
//  NucleOSTests
//
//  Tests for RemindersService changes in this PR:
//  - New RemindersServiceError cases (permissionDenied, fetchFailed, fetchReturnedNil)
//  - MockRemindersService actor CRUD operations
//  - RFC5545 priority mapping logic
//

import XCTest
@testable import NucleOS

final class RemindersServiceTests: XCTestCase {

    // MARK: - RemindersServiceError Tests

    func testPermissionDeniedErrorDescription() {
        let error = RemindersServiceError.permissionDenied
        XCTAssertEqual(
            error.errorDescription,
            "Reminders access was denied. Please grant permission in System Settings."
        )
    }

    func testFetchFailedErrorDescriptionContainsUnderlyingMessage() {
        let underlying = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "connection refused"])
        let error = RemindersServiceError.fetchFailed(underlying)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("connection refused"), "Expected underlying error in: \(description)")
    }

    func testFetchFailedErrorDescriptionPrefix() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "err"])
        let error = RemindersServiceError.fetchFailed(underlying)
        XCTAssertTrue(error.errorDescription?.hasPrefix("Failed to fetch reminders:") == true)
    }

    func testFetchReturnedNilErrorDescription() {
        let error = RemindersServiceError.fetchReturnedNil
        XCTAssertEqual(
            error.errorDescription,
            "Failed to fetch reminders: EventKit returned nil"
        )
    }

    func testUnimplementedErrorDescription() {
        let error = RemindersServiceError.unimplemented
        XCTAssertEqual(error.errorDescription, "This feature is not implemented yet.")
    }

    func testRemindersServiceErrorConformsToLocalizedError() {
        let error: LocalizedError = RemindersServiceError.unimplemented
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - MockRemindersService.fetchTasks Tests

    func testFetchTasksReturnsSevenDefaultTasks() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        XCTAssertEqual(tasks.count, 7)
    }

    func testFetchTasksContainsReviewQuarterlyGoals() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let titles = tasks.map(\.title)
        XCTAssertTrue(titles.contains("Review quarterly goals"))
    }

    func testFetchTasksContainsMixOfCompletedAndIncomplete() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let completed = tasks.filter(\.isCompleted)
        let incomplete = tasks.filter { !$0.isCompleted }
        XCTAssertFalse(completed.isEmpty, "Should have at least one completed task")
        XCTAssertFalse(incomplete.isEmpty, "Should have at least one incomplete task")
    }

    func testFetchTasksDefaultCompletedCount() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let completedCount = tasks.filter(\.isCompleted).count
        XCTAssertEqual(completedCount, 2, "Default mock has 2 completed tasks")
    }

    func testFetchTasksHighPriorityTasksExist() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let highPriority = tasks.filter { $0.priority == .high }
        XCTAssertFalse(highPriority.isEmpty)
    }

    func testFetchTasksContainsTaskWithNotes() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let withNotes = tasks.filter { $0.notes != nil }
        XCTAssertFalse(withNotes.isEmpty)
    }

    func testFetchTasksTasksHaveUniqueIDs() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let ids = tasks.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All tasks should have unique IDs")
    }

    // MARK: - MockRemindersService.addTask Tests

    func testAddTaskIncreasesCount() async throws {
        let service = MockRemindersService()
        let newTask = NucleTask(title: "New Test Task", priority: .low)
        try await service.addTask(newTask)
        let tasks = try await service.fetchTasks()
        XCTAssertEqual(tasks.count, 8)
    }

    func testAddTaskAppearsInFetchResults() async throws {
        let service = MockRemindersService()
        let newTask = NucleTask(title: "Unique Task XYZ", priority: .medium)
        try await service.addTask(newTask)
        let tasks = try await service.fetchTasks()
        XCTAssertTrue(tasks.contains(where: { $0.title == "Unique Task XYZ" }))
    }

    func testAddMultipleTasksIncreasesCountCorrectly() async throws {
        let service = MockRemindersService()
        let task1 = NucleTask(title: "Extra Task 1", priority: .low)
        let task2 = NucleTask(title: "Extra Task 2", priority: .high)
        try await service.addTask(task1)
        try await service.addTask(task2)
        let tasks = try await service.fetchTasks()
        XCTAssertEqual(tasks.count, 9)
    }

    func testAddedTaskPreservesAllFields() async throws {
        let service = MockRemindersService()
        let due = Date(timeIntervalSinceNow: 3600)
        let completion = Date(timeIntervalSinceNow: -1000)
        let newTask = NucleTask(
            title: "Detailed Task",
            isCompleted: true,
            dueDate: due,
            completionDate: completion,
            notes: "Important notes",
            priority: .high
        )
        try await service.addTask(newTask)
        let tasks = try await service.fetchTasks()
        let found = tasks.first { $0.title == "Detailed Task" }
        XCTAssertNotNil(found)
        XCTAssertTrue(found!.isCompleted)
        XCTAssertEqual(found!.dueDate, due)
        XCTAssertEqual(found!.completionDate, completion)
        XCTAssertEqual(found!.notes, "Important notes")
        XCTAssertEqual(found!.priority, .high)
    }

    // MARK: - MockRemindersService.completeTask Tests

    func testCompleteTaskMarksItAsCompleted() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        guard let incompleteTask = tasks.first(where: { !$0.isCompleted }) else {
            XCTFail("Expected at least one incomplete task in mock data")
            return
        }
        try await service.completeTask(incompleteTask)
        let updatedTasks = try await service.fetchTasks()
        let updated = updatedTasks.first(where: { $0.id == incompleteTask.id })
        XCTAssertTrue(updated?.isCompleted == true)
    }

    func testCompleteTaskDoesNotChangeTaskCount() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        guard let task = tasks.first(where: { !$0.isCompleted }) else {
            XCTFail("Need an incomplete task")
            return
        }
        try await service.completeTask(task)
        let afterTasks = try await service.fetchTasks()
        XCTAssertEqual(afterTasks.count, tasks.count)
    }

    func testCompleteTaskWithUnknownIDDoesNothing() async throws {
        let service = MockRemindersService()
        let unknownTask = NucleTask(title: "Unknown", priority: .none)
        // Should not throw, just silently do nothing
        try await service.completeTask(unknownTask)
        let tasks = try await service.fetchTasks()
        XCTAssertEqual(tasks.count, 7)
    }

    // MARK: - MockRemindersService.deleteTask Tests

    func testDeleteTaskDecreasesCount() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let taskToDelete = tasks[0]
        try await service.deleteTask(taskToDelete)
        let afterTasks = try await service.fetchTasks()
        XCTAssertEqual(afterTasks.count, 6)
    }

    func testDeleteTaskRemovesCorrectTask() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        let taskToDelete = tasks[0]
        try await service.deleteTask(taskToDelete)
        let afterTasks = try await service.fetchTasks()
        XCTAssertFalse(afterTasks.contains(where: { $0.id == taskToDelete.id }))
    }

    func testDeleteTaskWithUnknownIDDoesNothing() async throws {
        let service = MockRemindersService()
        let unknownTask = NucleTask(title: "Ghost Task", priority: .none)
        try await service.deleteTask(unknownTask)
        let tasks = try await service.fetchTasks()
        XCTAssertEqual(tasks.count, 7)
    }

    func testDeleteAllTasksResultsInEmptyList() async throws {
        let service = MockRemindersService()
        let tasks = try await service.fetchTasks()
        for task in tasks {
            try await service.deleteTask(task)
        }
        let remaining = try await service.fetchTasks()
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: - RFC5545 Priority Mapping Tests
    // These verify the mapping documented in RemindersService.convertToNucleTask
    // We test via NucleTask.Priority directly since convertToNucleTask is private.

    func testPriorityNoneRawValueIsNegativeOne() {
        // RFC5545 undefined/none maps to Priority.none (rawValue -1)
        XCTAssertEqual(NucleTask.Priority.none.rawValue, -1)
    }

    func testPriorityHighRawValueIsTwo() {
        // RFC5545 1..4 maps to .high
        XCTAssertEqual(NucleTask.Priority.high.rawValue, 2)
    }

    func testPriorityMediumRawValueIsOne() {
        // RFC5545 5 maps to .medium
        XCTAssertEqual(NucleTask.Priority.medium.rawValue, 1)
    }

    func testPriorityLowRawValueIsZero() {
        // RFC5545 6..9 maps to .low
        XCTAssertEqual(NucleTask.Priority.low.rawValue, 0)
    }

    // MARK: - Concurrency safety

    func testFetchTasksIsCallableMultipleTimes() async throws {
        let service = MockRemindersService()
        async let fetch1 = service.fetchTasks()
        async let fetch2 = service.fetchTasks()
        let (tasks1, tasks2) = try await (fetch1, fetch2)
        XCTAssertEqual(tasks1.count, tasks2.count)
    }
}