//
//  MenuBarState.swift
//  NucleOS
//
//  Observable state model for the menu bar companion.
//  State flows one way: main app services → MenuBarState → companion views.
//  No UI code, no business logic — pure data container.
//

import Foundation
import Observation

// MARK: - MenuBarIconState

/// Represents the visual state of the menu bar icon.
enum MenuBarIconState {
    /// The app is active — there are pending tasks or an imminent event.
    case active
    /// No pending items; everything is quiet.
    case idle
    /// A service error has occurred that the user should be aware of.
    case error
}

// MARK: - MenuBarState

/// Observable state model that drives the menu bar companion popover.
///
/// Inject custom values via ``init(pendingTaskCount:nextEvent:iconState:)`` when
/// constructing SwiftUI previews or unit tests. The main app is responsible for
/// pushing updates into this model — no business logic lives here.
@Observable
final class MenuBarState {

    // MARK: Properties

    /// Number of incomplete tasks sourced from Reminders.
    var pendingTaskCount: Int

    /// The next upcoming calendar event sourced from EventKit, if any.
    var nextEvent: NucleEvent?

    /// Current icon state reflecting overall activity at a glance.
    var iconState: MenuBarIconState

    // MARK: Init

    /// Creates a new `MenuBarState` with the supplied initial values.
    ///
    /// - Parameters:
    ///   - pendingTaskCount: Initial pending task count. Defaults to `0`.
    ///   - nextEvent: Initial next event. Defaults to `nil`.
    ///   - iconState: Initial icon state. Defaults to `.idle`.
    init(
        pendingTaskCount: Int = 0,
        nextEvent: NucleEvent? = nil,
        iconState: MenuBarIconState = .idle
    ) {
        self.pendingTaskCount = pendingTaskCount
        self.nextEvent = nextEvent
        self.iconState = iconState
    }
}

// MARK: - Preview

extension MenuBarState {

    /// A pre-populated instance suitable for SwiftUI previews.
    static var preview: MenuBarState {
        MenuBarState(
            pendingTaskCount: 3,
            nextEvent: NucleEvent(
                title: "Team Standup",
                startDate: Calendar.current.date(
                    bySettingHour: 9, minute: 30, second: 0, of: Date()
                ) ?? Date(),
                endDate: Calendar.current.date(
                    bySettingHour: 10, minute: 0, second: 0, of: Date()
                ) ?? Date()
            ),
            iconState: .active
        )
    }
}
