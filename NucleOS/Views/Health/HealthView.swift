//
//  HealthView.swift
//  NucleOS
//
//  Main Health section view — switches between permission states and live data.
//

import SwiftUI

struct HealthView: View {
    @State private var permissionState: HealthPermissionState = .notDetermined

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Your daily metrics")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)

                // State-driven content
                contentView
                    .padding(.horizontal, 32)

                Spacer(minLength: 32)
            }
        }
        .background(Color.backgroundPrimary)
        .onAppear(perform: evaluatePermissionState)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch permissionState {
        case .notDetermined:
            HealthRequestPermissionView(onRequest: evaluatePermissionState)
        case .unavailable:
            HealthUnavailableView()
        case .denied:
            HealthPermissionDeniedView()
        case .empty:
            HealthEmptyStateView()
        case .authorized:
            HealthStripView()
        }
    }

    // MARK: - Permission Evaluation

    private func evaluatePermissionState() {
        // HealthKit is not available on macOS without an Apple Silicon Mac
        // running macOS 13+ with the appropriate entitlement. We surface the
        // unavailable state here; the real check will be added when HealthKit
        // is fully integrated.
        permissionState = .unavailable
    }
}

// MARK: - Request Permission View

/// Shown when authorization has not yet been requested.
private struct HealthRequestPermissionView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentLavender.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "heart.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.accentLavender)
            }

            VStack(spacing: 8) {
                Text("Connect to Health")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Grant access to your health data so NucleOS can display your steps, heart rate, sleep, and calories.")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button(action: onRequest) {
                Label("Authorize Health Access", systemImage: "heart.fill")
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

// MARK: - Previews

#Preview("Unavailable") {
    HealthView()
        .frame(width: 900, height: 600)
}

#Preview("Denied — isolated") {
    HealthPermissionDeniedView()
        .frame(width: 900, height: 600)
        .background(Color.backgroundPrimary)
}

#Preview("Empty — isolated") {
    HealthEmptyStateView()
        .frame(width: 900, height: 600)
        .background(Color.backgroundPrimary)
}
