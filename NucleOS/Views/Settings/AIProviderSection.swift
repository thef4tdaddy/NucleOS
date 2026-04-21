//
//  AIProviderSection.swift
//  NucleOS
//
//  Settings card for the AI Provider section, including the provider picker
//  and sub-rows for API key, status, and test connection.
//

import SwiftUI

// MARK: - AIProviderSection

/// The "AI Provider" settings card.
struct AIProviderSection: View {

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

/// Provider picker and description text.
struct ProviderPickerRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsRowLabel("Provider")

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

// MARK: - ProviderStatusRow

/// Displays the availability status pill for the selected provider.
struct ProviderStatusRow: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            settingsRowLabel("Status")
            Spacer()
            providerStatusBadge
        }
    }

    @ViewBuilder
    private var providerStatusBadge: some View {
        switch viewModel.selectedProvider {
        case .mlx:
            SettingsStatusPill(
                label: viewModel.isMLXSupported ? "Available" : "Apple Silicon required",
                isPositive: viewModel.isMLXSupported
            )
        case .groq, .anthropic, .openai:
            SettingsStatusPill(
                label: viewModel.hasAPIKey ? "Key configured" : "API key required",
                isPositive: viewModel.hasAPIKey
            )
        }
    }
}
