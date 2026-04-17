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

// MARK: - Detail Grid

private struct HealthDetailGridView: View {
    let snapshot: HealthSnapshot

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            HealthDetailCard(
                icon: "figure.walk",
                label: "Steps",
                value: snapshot.steps.formatted(),
                goal: snapshot.stepGoal.formatted(),
                unit: "steps",
                progress: snapshot.stepsProgress,
                trend: "\(Int(snapshot.stepsProgress * 100))% of goal",
                color: .accentLavender
            )

            HealthDetailCard(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "\(Int(snapshot.heartRate))",
                goal: "60–100",
                unit: "bpm",
                progress: max(0, min(snapshot.heartRate / 100, 1.0)),
                trend: "Resting average",
                color: .accentPrimary
            )

            HealthDetailCard(
                icon: "bed.double.fill",
                label: "Sleep",
                value: snapshot.sleepFormatted,
                goal: snapshot.sleepGoalFormatted,
                unit: "",
                progress: snapshot.sleepProgress,
                trend: "Goal: \(snapshot.sleepGoalFormatted)",
                color: .accentLight
            )

            HealthDetailCard(
                icon: "flame.fill",
                label: "Calories",
                value: Int(snapshot.activeCalories).formatted(),
                goal: Int(snapshot.calorieGoal).formatted(),
                unit: "kcal",
                progress: snapshot.caloriesProgress,
                trend: "\(Int(snapshot.caloriesProgress * 100))% of goal",
                color: .accentWarm
            )
        }
    }
}

// MARK: - Detail Card

struct HealthDetailCard: View {
    let icon: String
    let label: String
    let value: String
    let goal: String
    let unit: String
    let progress: Double
    let trend: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HealthDetailCardHeader(icon: icon, label: label, color: color)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.textPrimary)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)
                    }
                }

                Text("/ \(goal)")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }

            MetricProgressBar(progress: progress, color: color, trend: trend)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
    }
}

private struct HealthDetailCardHeader: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Spacer()

            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textMuted)
                .tracking(0.5)
        }
    }
}

private struct MetricProgressBar: View {
    let progress: Double
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)

                Spacer()

                Text(trend)
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
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
