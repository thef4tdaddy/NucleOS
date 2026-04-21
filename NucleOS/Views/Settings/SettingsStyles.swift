//
//  SettingsStyles.swift
//  NucleOS
//
//  Shared styles and helper components used across the Settings views:
//  SettingsActionButtonStyle, SettingsStatusPill, and settingsRowLabel.
//

import SwiftUI

// MARK: - SettingsActionButtonRole

/// Controls the colour scheme applied by `SettingsActionButtonStyle`.
enum SettingsActionButtonRole {
    case primary
    case destructive
}

// MARK: - SettingsActionButtonStyle

/// Compact pill-shaped button style used for Save / Clear / Test actions
/// in the Settings panel.
struct SettingsActionButtonStyle: ButtonStyle {

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

// MARK: - SettingsStatusPill

/// Capsule-shaped availability badge used in the Provider Status row.
struct SettingsStatusPill: View {

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

// MARK: - Row label helper

/// Shared label style for settings row titles.
func settingsRowLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.textSecondary)
}
