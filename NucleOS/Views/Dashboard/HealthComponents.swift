//
//  HealthComponents.swift
//  NucleOS
//
//  Health strip and health metric cards used on the main dashboard
//

import SwiftUI

struct HealthStripView: View {
    let snapshot: HealthSnapshot

    init(snapshot: HealthSnapshot = MockData.healthSnapshot) {
        self.snapshot = snapshot
    }

    var body: some View {
        HStack(spacing: 16) {
            HealthMetricCard(
                icon: "figure.walk",
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
    }
}

struct HealthMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let goal: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

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
