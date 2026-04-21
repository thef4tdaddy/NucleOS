//
//  TestConnectionRow.swift
//  NucleOS
//
//  Settings row that sends a test prompt to the active LLM provider
//  and shows the result inline.
//

import SwiftUI

// MARK: - TestConnectionRow

/// Row with a "Test" button that fires `testConnection()` on the view model and
/// renders idle / testing / success / failure states inline.
struct TestConnectionRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                settingsRowLabel("Test Connection")
                Spacer()
                Button("Test") {
                    Task { await viewModel.testConnection() }
                }
                .buttonStyle(SettingsActionButtonStyle(role: .primary))
                .disabled(isTesting)
            }

            testResultView
        }
    }

    private var isTesting: Bool {
        if case .testing = viewModel.testConnectionState { return true }
        return false
    }

    @ViewBuilder
    private var testResultView: some View {
        switch viewModel.testConnectionState {
        case .idle:
            EmptyView()
        case .testing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.accentLavender)
                Text("Sending test prompt…")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }
        case .success(let response):
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentLight)
                Text(response.isEmpty ? "Connection successful" : response)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .failure(let message):
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentWarm)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
