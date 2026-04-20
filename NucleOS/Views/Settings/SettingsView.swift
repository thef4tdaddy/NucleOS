//
//  SettingsView.swift
//  NucleOS
//
//  Settings panel — LLM provider selection and API key management.
//

import SwiftUI

// MARK: - SettingsView

/// Root settings view.  Currently contains the AI Provider section.
/// Additional settings sections can be added below the AI card without
/// modifying the existing layout.
struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader
                AIProviderSection(viewModel: viewModel)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.backgroundPrimary)
        .onAppear { viewModel.onAppear() }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("Manage your AI providers and preferences")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
        }
    }
}

// MARK: - AIProviderSection

/// The "AI Provider" settings card.
private struct AIProviderSection: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
            Divider()
                .background(Color.border)
            sectionBody
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 0.5)
                )
        )
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundColor(.accentLavender)
            Text("AI PROVIDER")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
                .tracking(0.5)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var sectionBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProviderPickerRow(viewModel: viewModel)

            if viewModel.selectedProvider.requiresAPIKey {
                Divider().background(Color.border)
                APIKeySection(viewModel: viewModel)
            }

            Divider().background(Color.border)
            ProviderStatusRow(viewModel: viewModel)

            Divider().background(Color.border)
            TestConnectionRow(viewModel: viewModel)
        }
        .padding(20)
    }
}

// MARK: - ProviderPickerRow

private struct ProviderPickerRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowLabel("Provider")

            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(LLMProviderOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.accentLavender)

            Text(viewModel.selectedProvider.providerDescription)
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - APIKeySection

private struct APIKeySection: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            rowLabel("API Key")

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

private struct APIKeyStatusBadge: View {

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

// MARK: - ProviderStatusRow

private struct ProviderStatusRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            rowLabel("Status")
            Spacer()
            providerStatusBadge
        }
    }

    @ViewBuilder
    private var providerStatusBadge: some View {
        switch viewModel.selectedProvider {
        case .mlx:
            StatusPill(
                label: viewModel.isMLXSupported ? "Available" : "Apple Silicon required",
                isPositive: viewModel.isMLXSupported
            )
        case .groq, .anthropic, .openai:
            StatusPill(
                label: viewModel.hasAPIKey ? "Key configured" : "API key required",
                isPositive: viewModel.hasAPIKey
            )
        }
    }
}

// MARK: - TestConnectionRow

private struct TestConnectionRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                rowLabel("Test Connection")
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

// MARK: - StatusPill

private struct StatusPill: View {

    let label: String
    let isPositive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isPositive ? .accentLavender : .textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isPositive ? Color.accentPrimary.opacity(0.15) : Color.backgroundSecondary)
                    .overlay(
                        Capsule()
                            .stroke(isPositive ? Color.accentPrimary.opacity(0.3) : Color.border, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - SettingsActionButtonStyle

private enum SettingsActionButtonRole {
    case primary
    case destructive
}

private struct SettingsActionButtonStyle: ButtonStyle {

    let role: SettingsActionButtonRole

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(labelColor(pressed: configuration.isPressed))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor(pressed: configuration.isPressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: 0.5)
                    )
            )
    }

    private func labelColor(pressed: Bool) -> Color {
        switch role {
        case .primary:     return pressed ? .textSecondary : .accentLavender
        case .destructive: return pressed ? .textSecondary : .accentWarm
        }
    }

    private func backgroundColor(pressed: Bool) -> Color {
        switch role {
        case .primary:     return pressed ? Color.accentPrimary.opacity(0.2) : Color.accentPrimary.opacity(0.12)
        case .destructive: return pressed ? Color.accentWarm.opacity(0.2) : Color.accentWarm.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary:     return Color.accentPrimary.opacity(0.3)
        case .destructive: return Color.accentWarm.opacity(0.3)
        }
    }
}

// MARK: - Helpers

/// Shared label style for settings row titles.
private func rowLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.textSecondary)
}

// MARK: - Previews

#Preview {
    SettingsView()
        .frame(width: 700, height: 600)
}
