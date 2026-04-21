//
//  SettingsView.swift
//  NucleOS
//
//  Root settings view.
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

// MARK: - Preview

#Preview {
    SettingsView()
        .frame(width: 700, height: 600)
}
