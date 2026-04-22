//
//  HealthView.swift
//  NucleOS
//
//  Main Health section view — switches between permission states and live data.
//

import SwiftUI

struct HealthView: View {
    @StateObject private var viewModel = HealthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                HStack(spacing: 12) {
                    Image("icon-health-body")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.accentPrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Your daily metrics")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
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
        .task {
            await viewModel.evaluatePermissionState()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.permissionState {
        case .notDetermined:
            HealthRequestPermissionView {
                Task { await viewModel.requestAuthorization() }
            }
        case .unavailable:
            HealthUnavailableView()
        case .denied:
            HealthPermissionDeniedView()
        case .empty:
            HealthEmptyStateView()
        case .authorized:
            // Use live snapshot; fall back to mock data while the first fetch is in-flight.
            let displaySnapshot = viewModel.snapshot ?? MockData.healthSnapshot
            VStack(spacing: 24) {
                HealthStripView(snapshot: displaySnapshot)
                HealthDetailGridView(snapshot: displaySnapshot)
                HealthActivityView(snapshot: displaySnapshot)
            }
        }
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
