//
//  HealthComponents.swift
//  NucleOS
//
//  Health strip and health metric cards
//

import SwiftUI

struct HealthStripView: View {
    var body: some View {
        HStack(spacing: 16) {
            HealthMetricCard(
                icon: "figure.walk",
                label: "Steps",
                value: "8,234",
                goal: "10,000",
                progress: 0.82,
                color: .accentLavender
            )

            HealthMetricCard(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "72",
                goal: "avg",
                progress: 0.7,
                color: .accentPrimary
            )

            HealthMetricCard(
                icon: "bed.double.fill",
                label: "Sleep",
                value: "7h 23m",
                goal: "8h",
                progress: 0.92,
                color: .accentLight
            )

            HealthMetricCard(
                icon: "flame.fill",
                label: "Calories",
                value: "1,847",
                goal: "2,200",
                progress: 0.84,
                color: Color(hex: "ff6b6b")
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
