//
//  MenuBarQuickEntryView.swift
//  NucleOS
//
//  Quick-add reminder form for the menu bar popover.
//
//  Keyboard shortcuts
//  ──────────────────
//  ⌘N   — open / focus quick-entry from the popover (attach .keyboardShortcut("n", modifiers: .command)
//          to the button or view that presents this sheet in the parent popover view)
//  Return — submit the form and create the reminder
//  Escape — cancel and dismiss without saving
//

import SwiftUI

// MARK: - MenuBarQuickEntryView

/// A compact quick-add reminder form designed for the menu bar popover.
///
/// The text field is focused automatically on appear.  Pressing Return creates
/// the reminder via ``MenuBarQuickEntryViewModel``; pressing Escape cancels.
/// Inline success ("Added ✓") and error feedback is shown before the view
/// auto-dismisses on success.
struct MenuBarQuickEntryView: View {

    // MARK: Dependencies

    @StateObject private var viewModel: MenuBarQuickEntryViewModel

    // MARK: Environment

    /// Called by the parent to dismiss this view (e.g. popover close, sheet dismiss).
    var onDismiss: () -> Void

    // MARK: Focus

    @FocusState private var isFocused: Bool

    // MARK: Init

    init(
        viewModel: MenuBarQuickEntryViewModel = MenuBarQuickEntryViewModel(),
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            inputRow
            feedbackRow
        }
        .padding(16)
        .background(Color.backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.border, lineWidth: 0.5)
        )
        .cornerRadius(10)
        // Auto-focus the text field when the view appears
        .onAppear { isFocused = true }
        // Auto-dismiss after showing the success confirmation
        .onChange(of: viewModel.state) { _, newState in
            if case .success = newState {
                Task {
                    try? await Task.sleep(for: .milliseconds(900))
                    viewModel.reset()
                    onDismiss()
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(.accentLight)

            Text("New Reminder")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)

            Spacer()

            Button {
                viewModel.reset()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            .buttonStyle(.plain)
            .help("Cancel  (Esc)")
            // Escape key cancels
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Task title…", text: $viewModel.taskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .focused($isFocused)
                .disabled(isSubmitting)
                // Return key submits
                .onSubmit {
                    Task { await viewModel.submit() }
                }

            submitButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(fieldBorderColor, lineWidth: 0.5)
                )
        )
    }

    @ViewBuilder
    private var submitButton: some View {
        if isSubmitting {
            ProgressView()
                .controlSize(.small)
                .tint(.accentLight)
                .frame(width: 22, height: 22)
        } else {
            Button {
                Task { await viewModel.submit() }
            } label: {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? .textDim : .accentLavender)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Add reminder  (Return)")
        }
    }

    @ViewBuilder
    private var feedbackRow: some View {
        switch viewModel.state {
        case .idle, .submitting:
            hintText
        case .success:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentLight)
                Text("Added")
                    .font(.system(size: 12))
                    .foregroundColor(.accentLavender)
            }
            .transition(.opacity)
        case .failure(let message):
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.accentWarm)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.accentWarm)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .transition(.opacity)
        }
    }

    private var hintText: some View {
        Text("Return to add · Esc to cancel")
            .font(.system(size: 11))
            .foregroundColor(.textDim)
    }

    // MARK: - Helpers

    private var isSubmitting: Bool {
        if case .submitting = viewModel.state { return true }
        return false
    }

    private var fieldBorderColor: Color {
        if case .failure = viewModel.state { return .accentWarm.opacity(0.5) }
        return isFocused ? Color.accentPrimary.opacity(0.6) : Color.border
    }
}

// MARK: - Preview

#Preview("Idle") {
    MenuBarQuickEntryView(
        viewModel: MenuBarQuickEntryViewModel(service: MockRemindersService()),
        onDismiss: {}
    )
    .padding()
    .background(Color.backgroundPrimary)
    .frame(width: 320)
}
