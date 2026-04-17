//
//  NucleTaskTests.swift
//  NucleOSTests
//
//  Tests for NucleTask model changes introduced in this PR:
//  - New `completionDate` field
//  - New `Priority.none` case with rawValue -1
//  - Removal of Hashable conformance
//

import XCTest
@testable import NucleOS

final class NucleTaskTests: XCTestCase {

    // MARK: - Initializer Tests

    func testDefaultInitializerValues() {
        let task = NucleTask(title: "Test Task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.dueDate)
        XCTAssertNil(task.completionDate)
        XCTAssertNil(task.notes)
        XCTAssertEqual(task.priority, .medium)
    }

    func testInitializerWithAllParameters() {
        let id = UUID()
        let dueDate = Date()
        let completionDate = Date()
        let task = NucleTask(
            id: id,
            title: "Full Task",
            isCompleted: true,
            dueDate: dueDate,
            completionDate: completionDate,
            notes: "Some notes",
            priority: .high
        )
        XCTAssertEqual(task.id, id)
        XCTAssertEqual(task.title, "Full Task")
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.completionDate, completionDate)
        XCTAssertEqual(task.notes, "Some notes")
        XCTAssertEqual(task.priority, .high)
    }

    func testCompletionDateIsNilByDefault() {
        // completionDate is a new field added in this PR — verify default is nil
        let task = NucleTask(title: "Task without completion date")
        XCTAssertNil(task.completionDate)
    }

    func testCompletionDateCanBeSetIndependentlyOfIsCompleted() {
        let completionDate = Date()
        let task = NucleTask(
            title: "Task",
            isCompleted: false,
            completionDate: completionDate
        )
        // completionDate is independent of isCompleted flag
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.completionDate, completionDate)
    }

    func testCompletionDateStoredCorrectly() {
        let reference = Date(timeIntervalSinceReferenceDate: 0)
        let task = NucleTask(title: "T", isCompleted: true, completionDate: reference)
        XCTAssertEqual(task.completionDate, reference)
    }

    // MARK: - Priority Tests

    func testPriorityNoneRawValue() {
        // Priority.none is a new case added in PR with rawValue -1
        XCTAssertEqual(NucleTask.Priority.none.rawValue, -1)
    }

    func testPriorityLowRawValue() {
        XCTAssertEqual(NucleTask.Priority.low.rawValue, 0)
    }

    func testPriorityMediumRawValue() {
        XCTAssertEqual(NucleTask.Priority.medium.rawValue, 1)
    }

    func testPriorityHighRawValue() {
        XCTAssertEqual(NucleTask.Priority.high.rawValue, 2)
    }

    func testPriorityCaseIterableContainsNone() {
        XCTAssertTrue(NucleTask.Priority.allCases.contains(.none))
    }

    func testPriorityCaseIterableContainsAll() {
        let cases = NucleTask.Priority.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.none))
        XCTAssertTrue(cases.contains(.low))
        XCTAssertTrue(cases.contains(.medium))
        XCTAssertTrue(cases.contains(.high))
    }

    func testPriorityInitFromRawValueMinusOne() {
        let priority = NucleTask.Priority(rawValue: -1)
        XCTAssertEqual(priority, .none)
    }

    func testPriorityInitFromRawValueZero() {
        let priority = NucleTask.Priority(rawValue: 0)
        XCTAssertEqual(priority, .low)
    }

    func testPriorityInitFromRawValueOne() {
        let priority = NucleTask.Priority(rawValue: 1)
        XCTAssertEqual(priority, .medium)
    }

    func testPriorityInitFromRawValueTwo() {
        let priority = NucleTask.Priority(rawValue: 2)
        XCTAssertEqual(priority, .high)
    }

    func testPriorityInitFromInvalidRawValueReturnsNil() {
        XCTAssertNil(NucleTask.Priority(rawValue: 99))
        XCTAssertNil(NucleTask.Priority(rawValue: -2))
        XCTAssertNil(NucleTask.Priority(rawValue: 3))
    }

    // MARK: - Equatable Tests

    func testTasksWithSameIDAreEqual() {
        let id = UUID()
        let task1 = NucleTask(id: id, title: "Task A", priority: .low)
        let task2 = NucleTask(id: id, title: "Task A", priority: .low)
        XCTAssertEqual(task1, task2)
    }

    func testTasksWithDifferentIDsAreNotEqual() {
        let task1 = NucleTask(title: "Task A", priority: .medium)
        let task2 = NucleTask(title: "Task A", priority: .medium)
        // UUIDs auto-generated, so they will differ
        XCTAssertNotEqual(task1, task2)
    }

    func testTasksWithDifferentCompletionDatesAreNotEqual() {
        let id = UUID()
        let date1 = Date(timeIntervalSinceReferenceDate: 1000)
        let date2 = Date(timeIntervalSinceReferenceDate: 2000)
        let task1 = NucleTask(id: id, title: "Task", completionDate: date1)
        let task2 = NucleTask(id: id, title: "Task", completionDate: date2)
        XCTAssertNotEqual(task1, task2)
    }

    // MARK: - Mutability Tests

    func testTaskFieldsAreMutable() {
        var task = NucleTask(title: "Original")
        task.title = "Modified"
        task.isCompleted = true
        task.completionDate = Date()
        task.notes = "Updated notes"
        task.priority = .high
        XCTAssertEqual(task.title, "Modified")
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completionDate)
        XCTAssertEqual(task.notes, "Updated notes")
        XCTAssertEqual(task.priority, .high)
    }

    // MARK: - Regression: completionDate independent of dueDate

    func testCompletionDateAndDueDateAreIndependent() {
        let due = Date(timeIntervalSinceNow: 3600)
        let completed = Date(timeIntervalSinceNow: -7200)
        let task = NucleTask(
            title: "Task",
            isCompleted: true,
            dueDate: due,
            completionDate: completed
        )
        XCTAssertEqual(task.dueDate, due)
        XCTAssertEqual(task.completionDate, completed)
        XCTAssertNotEqual(task.dueDate, task.completionDate)
    }
}