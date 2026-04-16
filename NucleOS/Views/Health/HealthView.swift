//
//  HealthView.swift
//  NucleOS
//
//  Full-page health section with metric cards and summary layouts
//

import SwiftUI

// MARK: - Main View

struct HealthView: View {
    private let snapshot = MockData.healthSnapshot

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HealthPageHeader()
                    .padding(.horizontal, 32)
                    .padding(.top, 32)

                HealthStripView(snapshot: snapshot)
                    .padding(.horizontal, 32)

                HealthDetailGridView(snapshot: snapshot)
                    .padding(.horizontal, 32)

                HealthWeeklyStepsCard()
                    .padding(.horizontal, 32)

                HealthSleepCard(snapshot: snapshot)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Page Header

private struct HealthPageHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Health")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentLavender)

                    Text("Synced from Apple Health")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()
        }
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
                // TODO: Compute delta from HealthKit history once wired up
                trend: "+12% from yesterday",
                color: .accentLavender
            )

            HealthDetailCard(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "\(Int(snapshot.heartRate))",
                goal: "60–100",
                unit: "bpm",
                progress: min(snapshot.heartRate / 100, 1.0),
                trend: "Resting average",
                color: .accentPrimary
            )

            HealthDetailCard(
                icon: "bed.double.fill",
                label: "Sleep",
                value: snapshot.sleepFormatted,
                goal: snapshot.sleepGoalFormatted,
                unit: "duration",
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
                // TODO: Compute delta from HealthKit history once wired up
                trend: "+5% from yesterday",
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

                    Text(unit)
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
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

#Preview {
    HealthView()
}
