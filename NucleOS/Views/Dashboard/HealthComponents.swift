//
//  HealthComponents.swift
//  NucleOS
//
//  Health strip and health metric cards used on the main dashboard
//

import SwiftUI

struct HealthStripView: View {
    let snapshot: HealthSnapshot?
    var isLoading: Bool

    init(snapshot: HealthSnapshot? = MockData.healthSnapshot, isLoading: Bool = false) {
        self.snapshot = snapshot
        self.isLoading = isLoading
    }

    var body: some View {
        if isLoading && snapshot == nil {
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in HealthMetricShimmerBlock() }
            }
        } else if let snapshot = snapshot {
            HStack(spacing: 16) {
                HealthMetricCard(
                    icon: "figure.walk",
                    assetIconName: "icon-steps",
                    label: "Steps",
                    value: snapshot.steps.formatted(),
                    goal: snapshot.stepGoal.formatted(),
                    progress: snapshot.stepsProgress,
                    color: .accentLavender
                )

                HealthMetricCard(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: "\(Int(snapshot.heartRate))",
                    goal: "avg",
                    progress: max(0, min(snapshot.heartRate / 100, 1.0)),
                    color: .accentPrimary
                )

                HealthMetricCard(
                    icon: "bed.double.fill",
                    assetIconName: "icon-sleep",
                    label: "Sleep",
                    value: snapshot.sleepFormatted,
                    goal: snapshot.sleepGoalFormatted,
                    progress: snapshot.sleepProgress,
                    color: .accentLight
                )

                HealthMetricCard(
                    icon: "flame.fill",
                    label: "Calories",
                    value: Int(snapshot.activeCalories).formatted(),
                    goal: Int(snapshot.calorieGoal).formatted(),
                    progress: snapshot.caloriesProgress,
                    color: .accentWarm
                )
            }
        } else {
            HStack(spacing: 16) {
                HealthMetricCard(
                    icon: "figure.walk",
                    assetIconName: "icon-steps",
                    label: "Steps",
                    value: "—",
                    goal: "—",
                    progress: 0,
                    color: .accentLavender.opacity(0.3)
                )

                HealthMetricCard(
                    icon: "heart.fill",
                    label: "Heart Rate",
                    value: "—",
                    goal: "—",
                    progress: 0,
                    color: .accentPrimary.opacity(0.3)
                )

                HealthMetricCard(
                    icon: "bed.double.fill",
                    assetIconName: "icon-sleep",
                    label: "Sleep",
                    value: "—",
                    goal: "—",
                    progress: 0,
                    color: .accentLight.opacity(0.3)
                )

                HealthMetricCard(
                    icon: "flame.fill",
                    label: "Calories",
                    value: "—",
                    goal: "—",
                    progress: 0,
                    color: .accentWarm.opacity(0.3)
                )
            }
        }
    }
}

struct HealthMetricCard: View {
    let icon: String
    let assetIconName: String?
    let label: String
    let value: String
    let goal: String
    let progress: Double
    let color: Color

    init(icon: String, assetIconName: String? = nil, label: String, value: String, goal: String, progress: Double, color: Color) {
        self.icon = icon
        self.assetIconName = assetIconName
        self.label = label
        self.value = value
        self.goal = goal
        self.progress = progress
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let assetName = assetIconName {
                    Image(assetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(color)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }

                Spacer()

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textMuted)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("/ \(goal)")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }

                // Progress bar
                GeometryReader(content: { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.border)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                })
                .frame(height: 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
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

#Preview {
    HealthStripView()
        .padding(32)
        .background(Color.backgroundPrimary)
}
