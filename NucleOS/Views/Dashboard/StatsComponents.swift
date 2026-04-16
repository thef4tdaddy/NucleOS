//
//  StatsComponents.swift
//  NucleOS
//
//  Stats row and stat cards
//

import SwiftUI

struct StatsRowView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(label: "Tasks Today", value: "7", subtitle: "3 completed")
            StatCard(label: "Events", value: "4", subtitle: "2 upcoming")
            StatCard(label: "Completed This Week", value: "23", subtitle: "+5 from last week")
            StatCard(label: "Focus Time", value: "3h 12m", subtitle: "Today")
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textMuted)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
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
