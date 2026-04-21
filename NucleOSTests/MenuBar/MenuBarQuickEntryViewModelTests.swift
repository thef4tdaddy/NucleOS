//
//  MenuBarQuickEntryViewModelTests.swift
//  NucleOSTests/MenuBar
//
//  Swift Testing suite for MenuBarQuickEntryViewModel — mock-only, zero real Apple framework calls.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("MenuBar Quick Entry ViewModel")
@MainActor
struct MenuBarQuickEntryViewModelTests {

    // MARK: - Initial state

    @Test("Initial state is idle with empty title")
    func initialStateIsIdle() async {
        let vm = MenuBarQuickEntryViewModel(service: MockRemindersService())
        #expect(vm.taskTitle == "")
        #expect(vm.state == .idle)
    }

    // MARK: - submit: blank title is a no-op

    @Test("submit with blank title stays idle")
    func submitWithBlankTitleIsNoOp() async {
        let vm = MenuBarQuickEntryViewModel(service: MockRemindersService())
        vm.taskTitle = "   "
        await vm.submit()
        #expect(vm.state == .idle)
    }

    @Test("submit with empty title stays idle")
    func submitWithEmptyTitleIsNoOp() async {
        let vm = MenuBarQuickEntryViewModel(service: MockRemindersService())
        vm.taskTitle = ""
        await vm.submit()
        #expect(vm.state == .idle)
    }

    // MARK: - submit: success path

    @Test("submit with valid title transitions to success")
    func submitTransitionsToSuccess() async throws {
        let service = MockRemindersService()
        let vm = MenuBarQuickEntryViewModel(service: service)
        vm.taskTitle = "Buy milk"
        await vm.submit()
        #expect(vm.state == .success)
    }

    @Test("submit appends task to the mock service")
    func submitAppendsTaskToService() async throws {
        let service = MockRemindersService()
        let before = try await service.fetchTasks()
        let vm = MenuBarQuickEntryViewModel(service: service)
        vm.taskTitle = "Buy oat milk"
        await vm.submit()
        let after = try await service.fetchTasks()
        #expect(after.count == before.count + 1)
        #expect(after.contains(where: { $0.title == "Buy oat milk" }))
    }

    @Test("submit trims whitespace from task title")
    func submitTrimsTitleWhitespace() async throws {
        let service = MockRemindersService()
        let vm = MenuBarQuickEntryViewModel(service: service)
        vm.taskTitle = "  Walk the dog  "
        await vm.submit()
        let tasks = try await service.fetchTasks()
        #expect(tasks.contains(where: { $0.title == "Walk the dog" }))
    }

    // MARK: - submit: failure path

    @Test("submit transitions to failure when service throws")
    func submitTransitionsToFailure() async {
        let vm = MenuBarQuickEntryViewModel(service: FailingMockRemindersService())
        vm.taskTitle = "This will fail"
        await vm.submit()
        if case .failure = vm.state {
            // expected
        } else {
            Issue.record("Expected .failure state but got \(vm.state)")
        }
    }

    @Test("failure state contains error description")
    func failureStateContainsErrorDescription() async {
        let vm = MenuBarQuickEntryViewModel(service: FailingMockRemindersService())
        vm.taskTitle = "Will fail"
        await vm.submit()
        if case .failure(let message) = vm.state {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected .failure state")
        }
    }

    // MARK: - reset

    @Test("reset clears title and returns to idle")
    func resetClearsTitleAndReturnsIdle() async {
        let vm = MenuBarQuickEntryViewModel(service: MockRemindersService())
        vm.taskTitle = "Something"
        await vm.submit()
        vm.reset()
        #expect(vm.taskTitle == "")
        #expect(vm.state == .idle)
    }
}

// MARK: - FailingMockRemindersService

/// A mock that always throws `permissionDenied` from `addTask`.
private actor FailingMockRemindersService: RemindersServiceProtocol {
    func fetchTasks() async throws -> [NucleTask] { [] }
    func addTask(_ task: NucleTask) async throws {
        throw RemindersServiceError.permissionDenied
    }
    func completeTask(_ task: NucleTask) async throws {}
    func deleteTask(_ task: NucleTask) async throws {}
}
