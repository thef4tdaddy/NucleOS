//
//  APIKeySection.swift
//  NucleOS
//
//  Secure text field, Save/Clear buttons, status badge, and error feedback
//  for managing a provider API key in the Settings panel.
//

import SwiftUI

// MARK: - APIKeySection

/// API key management row — shown only when `selectedProvider.requiresAPIKey`.
struct APIKeySection: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsRowLabel("API Key")

            HStack(spacing: 8) {
                SecureField("Paste your API key here", text: $viewModel.apiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.border, lineWidth: 0.5)
                            )
                    )

                Button("Save") {
                    viewModel.saveAPIKey()
                }
                .buttonStyle(SettingsActionButtonStyle(role: .primary))
                .disabled(viewModel.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if viewModel.hasAPIKey {
                    Button("Clear") {
                        viewModel.clearAPIKey()
                    }
                    .buttonStyle(SettingsActionButtonStyle(role: .destructive))
                }
            }

            APIKeyStatusBadge(hasKey: viewModel.hasAPIKey)

            if let error = viewModel.saveError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentWarm)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.accentWarm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - APIKeyStatusBadge

/// Dot + label badge indicating whether an API key is stored in the Keychain.
struct APIKeyStatusBadge: View {

    let hasKey: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hasKey ? Color.accentLight : Color.textDim)
                .frame(width: 6, height: 6)
            Text(hasKey ? "Key saved" : "No key configured")
                .font(.system(size: 11))
                .foregroundColor(hasKey ? .accentLavender : .textMuted)
        }
    }
}
