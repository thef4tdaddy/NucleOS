//
//  MenuBarQuickEntryViewModel.swift
//  NucleOS
//
//  View model for the quick-entry reminder action in the menu bar popover.
//  Routes task creation through RemindersServiceProtocol — no new persistence.
//
//  Keyboard shortcut: ⌘N opens quick-entry from the popover (see MenuBarQuickEntryView).
//

import Foundation

// MARK: - QuickEntryState

/// Represents every possible UI state of the quick-entry form.
enum QuickEntryState: Equatable {
    /// Waiting for the user to type a title.
    case idle
    /// A save call is in-flight.
    case submitting
    /// The reminder was created successfully; shows a confirmation message.
    case success
    /// The save call failed; carries an inline error description.
    case failure(String)
}

// MARK: - MenuBarQuickEntryViewModel

/// Drives the menu bar quick-entry reminder form.
///
/// Inject a custom ``RemindersServiceProtocol`` for SwiftUI previews and tests.
@MainActor
final class MenuBarQuickEntryViewModel: ObservableObject {

    // MARK: Published state

    /// The text typed by the user in the title field.
    @Published var taskTitle: String = ""

    /// Current UI state of the form.
    @Published private(set) var state: QuickEntryState = .idle

    // MARK: Private

    private let service: any RemindersServiceProtocol
    /// Prevents duplicate submissions while one is already in-flight.
    private var isSubmitting = false

    // MARK: Init

    init(service: any RemindersServiceProtocol = RemindersService()) {
        self.service = service
    }

    // MARK: - Actions

    /// Validates the title, calls `addTask`, then transitions to `.success` or `.failure`.
    ///
    /// A no-op when the title is blank or a submission is already in progress.
    func submit() async {
        let trimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmitting else { return }

        isSubmitting = true
        state = .submitting
        defer { isSubmitting = false }

        do {
            let task = NucleTask(title: trimmed)
            try await service.addTask(task)
            state = .success
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    /// Resets form state and clears the text field (used on cancel or after dismiss).
    func reset() {
        taskTitle = ""
        state = .idle
    }
}
