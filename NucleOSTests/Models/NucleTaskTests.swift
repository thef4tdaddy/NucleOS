//
//  NucleTaskTests.swift
//  NucleOSTests/Models
//
//  Swift Testing suite for the NucleTask model.
//

import Testing
@testable import NucleOS

@Suite("NucleTask Model")
struct NucleTaskModelTests {

    // MARK: - Identifiable

    @Test("NucleTask conforms to Identifiable with UUID id")
    func identifiableConformance() {
        let task = NucleTask(title: "Test")
        // Identifiable conformance — id is a UUID
        #expect(task.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("Two tasks created independently have different ids")
    func twoTasksHaveDifferentIDs() {
        let t1 = NucleTask(title: "A")
        let t2 = NucleTask(title: "B")
        #expect(t1.id != t2.id)
    }

    // MARK: - Equatable / same id

    @Test("Tasks with same id are equal")
    func sameIDTasksAreEqual() {
        let id = UUID()
        let t1 = NucleTask(id: id, title: "Task", priority: .low)
        let t2 = NucleTask(id: id, title: "Task", priority: .low)
        #expect(t1 == t2)
    }

    @Test("Tasks with different ids are not equal even if title matches")
    func differentIDTasksAreNotEqual() {
        let t1 = NucleTask(title: "Same Title", priority: .medium)
        let t2 = NucleTask(title: "Same Title", priority: .medium)
        #expect(t1 != t2)
    }

    // MARK: - Priority cases

    @Test("All Priority cases exist: none, low, medium, high")
    func allPriorityCasesExist() {
        let cases = NucleTask.Priority.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.none))
        #expect(cases.contains(.low))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.high))
    }

    @Test("Priority.none rawValue is -1")
    func priorityNoneRawValue() {
        #expect(NucleTask.Priority.none.rawValue == -1)
    }

    @Test("Priority.low rawValue is 0")
    func priorityLowRawValue() {
        #expect(NucleTask.Priority.low.rawValue == 0)
    }

    @Test("Priority.medium rawValue is 1")
    func priorityMediumRawValue() {
        #expect(NucleTask.Priority.medium.rawValue == 1)
    }

    @Test("Priority.high rawValue is 2")
    func priorityHighRawValue() {
        #expect(NucleTask.Priority.high.rawValue == 2)
    }

    // MARK: - Hashable (via Priority which is Hashable)

    @Test("Priority is usable as dictionary key (Hashable)")
    func priorityHashable() {
        var dict: [NucleTask.Priority: String] = [:]
        dict[.none] = "none"
        dict[.low] = "low"
        dict[.medium] = "medium"
        dict[.high] = "high"
        #expect(dict.count == 4)
    }

    // MARK: - Default values

    @Test("Default isCompleted is false")
    func defaultIsCompletedFalse() {
        let task = NucleTask(title: "T")
        #expect(task.isCompleted == false)
    }

    @Test("Default dueDate is nil")
    func defaultDueDateNil() {
        let task = NucleTask(title: "T")
        #expect(task.dueDate == nil)
    }

    @Test("Default completionDate is nil")
    func defaultCompletionDateNil() {
        let task = NucleTask(title: "T")
        #expect(task.completionDate == nil)
    }

    @Test("Default notes is nil")
    func defaultNotesNil() {
        let task = NucleTask(title: "T")
        #expect(task.notes == nil)
    }

    @Test("Default priority is .medium")
    func defaultPriorityMedium() {
        let task = NucleTask(title: "T")
        #expect(task.priority == .medium)
    }
}
