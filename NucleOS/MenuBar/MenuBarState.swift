//
//  MenuBarState.swift
//  NucleOS
//
//  Observable state object for the menu bar popover.
//  Holds pre-aggregated data from services so views never call services directly.
//

import Foundation

// MARK: - MenuBarState

/// Holds all data surfaced in the menu bar popover.
///
/// A single source of truth for ``MenuBarStatusView``. Populated by a lifecycle
/// coordinator (NUC-31) that bridges the app's services into this lightweight
/// container. Views read from this object only — they never call services directly.
@MainActor
final class MenuBarState: ObservableObject {

    // MARK: Tasks

    /// Number of incomplete tasks due today.
    /// Zero means "all clear".
    @Published var pendingTaskCount: Int = 0

    // MARK: Calendar

    /// The next upcoming event today, sorted by start time.
    /// `nil` when there are no remaining events today.
    @Published var nextEvent: NucleEvent? = nil

    // MARK: Health

    /// Latest health snapshot (steps, calories, sleep).
    /// `nil` when HealthKit access has not been granted.
    @Published var healthSnapshot: HealthSnapshot? = nil

    // MARK: Init

    init(
        pendingTaskCount: Int = 0,
        nextEvent: NucleEvent? = nil,
        healthSnapshot: HealthSnapshot? = nil
    ) {
        self.pendingTaskCount = pendingTaskCount
        self.nextEvent = nextEvent
        self.healthSnapshot = healthSnapshot
    }

    // MARK: Preview

    /// A fully-populated `MenuBarState` suitable for SwiftUI previews.
    static var preview: MenuBarState {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextEventStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? today
        let nextEventEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today

        return MenuBarState(
            pendingTaskCount: 3,
            nextEvent: NucleEvent(
                title: "Design Sync",
                startDate: nextEventStart,
                endDate: nextEventEnd,
                calendarColor: .accentLight
            ),
            healthSnapshot: MockData.healthSnapshot
        )
    }

    /// An empty `MenuBarState` with no data — exercises all empty-state paths.
    static var previewEmpty: MenuBarState {
        MenuBarState(pendingTaskCount: 0, nextEvent: nil, healthSnapshot: nil)
    }
}
