//
//  HealthStateViews.swift
//  NucleOS
//
//  Reusable empty, permission-denied, and unavailable state views for HealthKit surfaces.
//

import SwiftUI

// MARK: - Empty State

/// Shown when HealthKit is authorized but no data is available yet.
struct HealthEmptyStateView: View {
    var body: some View {
        HealthStateContainer {
            HealthStateIcon(
                systemName: "heart.text.square",
                color: .accentLavender
            )

            HealthStateText(
                title: "No Health Data Yet",
                description: "Start moving and your stats will appear here. Sync your Apple Watch or open the Health app to get started."
            )
        }
    }
}

// MARK: - Permission Denied State

/// Shown when the user has denied HealthKit access.
struct HealthPermissionDeniedView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HealthStateContainer {
            HealthStateIcon(
                systemName: "heart.slash.fill",
                color: .accentPrimary
            )

            HealthStateText(
                title: "Health Access Denied",
                description: "NucleOS needs permission to read your health data. Open System Settings to grant access."
            )

            Button(action: openHealthPrivacySettings) {
                Label("Open System Settings", systemImage: "gear")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentPrimary)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func openHealthPrivacySettings() {
#if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Health") {
            openURL(url)
        }
#else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
#endif
    }
}

// MARK: - Unavailable State

/// Shown when HealthKit is not available on the current device or OS.
struct HealthUnavailableView: View {
    var body: some View {
        HealthStateContainer {
            HealthStateIcon(
                systemName: "heart.slash.circle",
                color: .textMuted
            )

            HealthStateText(
                title: "Health Unavailable",
                description: "HealthKit is not supported on this device. Connect an iPhone or Apple Watch to access your health metrics."
            )
        }
    }
}

// MARK: - Shared Subviews

private struct HealthStateContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 20) {
            content()
        }
        .frame(maxWidth: 380)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HealthStateIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 72, height: 72)

            Image(systemName: systemName)
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(color)
        }
    }
}

private struct HealthStateText: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    HealthEmptyStateView()
        .frame(width: 600, height: 400)
        .background(Color.backgroundPrimary)
}

#Preview("Permission Denied") {
    HealthPermissionDeniedView()
        .frame(width: 600, height: 400)
        .background(Color.backgroundPrimary)
}

#Preview("Unavailable") {
    HealthUnavailableView()
        .frame(width: 600, height: 400)
        .background(Color.backgroundPrimary)
}
