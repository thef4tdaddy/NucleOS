//
//  MenuBarStateTests.swift
//  NucleOSTests/Models
//
//  Swift Testing suite for the MenuBarState model.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("MenuBarState Model")
struct MenuBarStateTests {

    // MARK: - Default values

    @Test("Default pendingTaskCount is 0")
    func defaultPendingTaskCount() {
        let state = MenuBarState()
        #expect(state.pendingTaskCount == 0)
    }

    @Test("Default nextEvent is nil")
    func defaultNextEventIsNil() {
        let state = MenuBarState()
        #expect(state.nextEvent == nil)
    }

    @Test("Default iconState is .idle")
    func defaultIconStateIsIdle() {
        let state = MenuBarState()
        if case .idle = state.iconState { } else {
            Issue.record("Expected .idle, got \(state.iconState)")
        }
    }

    // MARK: - Custom initialisation

    @Test("Custom pendingTaskCount is stored")
    func customPendingTaskCount() {
        let state = MenuBarState(pendingTaskCount: 5)
        #expect(state.pendingTaskCount == 5)
    }

    @Test("Custom nextEvent is stored")
    func customNextEvent() {
        let event = NucleEvent(title: "Standup", startDate: Date(), endDate: Date())
        let state = MenuBarState(nextEvent: event)
        #expect(state.nextEvent == event)
    }

    @Test("Custom iconState .active is stored")
    func customIconStateActive() {
        let state = MenuBarState(iconState: .active)
        if case .active = state.iconState { } else {
            Issue.record("Expected .active, got \(state.iconState)")
        }
    }

    @Test("Custom iconState .error is stored")
    func customIconStateError() {
        let state = MenuBarState(iconState: .error)
        if case .error = state.iconState { } else {
            Issue.record("Expected .error, got \(state.iconState)")
        }
    }

    // MARK: - Mutability

    @Test("pendingTaskCount can be updated after init")
    func pendingTaskCountMutable() {
        let state = MenuBarState(pendingTaskCount: 2)
        state.pendingTaskCount = 7
        #expect(state.pendingTaskCount == 7)
    }

    @Test("nextEvent can be cleared after init")
    func nextEventCanBeCleared() {
        let event = NucleEvent(title: "Meeting", startDate: Date(), endDate: Date())
        let state = MenuBarState(nextEvent: event)
        state.nextEvent = nil
        #expect(state.nextEvent == nil)
    }

    @Test("iconState can be updated after init")
    func iconStateMutable() {
        let state = MenuBarState(iconState: .idle)
        state.iconState = .active
        if case .active = state.iconState { } else {
            Issue.record("Expected .active, got \(state.iconState)")
        }
    }

    // MARK: - Preview

    @Test("preview has non-zero pendingTaskCount")
    func previewHasNonZeroPendingTaskCount() {
        #expect(MenuBarState.preview.pendingTaskCount > 0)
    }

    @Test("preview has a nextEvent")
    func previewHasNextEvent() {
        #expect(MenuBarState.preview.nextEvent != nil)
    }

    @Test("preview iconState is .active")
    func previewIconStateIsActive() {
        let preview = MenuBarState.preview
        if case .active = preview.iconState { } else {
            Issue.record("Expected .active, got \(preview.iconState)")
        }
    }
}
