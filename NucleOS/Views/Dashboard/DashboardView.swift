//
//  DashboardView.swift
//  NucleOS
//
//  Main dashboard with health, stats, tasks, calendar, and AI briefing
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView(content: {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning, Edward")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Thursday, April 16")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)

                // Health strip
                HealthStripView()
                    .padding(.horizontal, 32)

                // 4-column stat row
                StatsRowView()
                    .padding(.horizontal, 32)

                // 2-column grid: Tasks + Calendar
                HStack(spacing: 20) {
                    TasksPanelView()
                    CalendarPanelView()
                }
                .padding(.horizontal, 32)

                // AI Briefing panel
                AIBriefingPanelView()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        })
        .background(Color.backgroundPrimary)
    }
}

#Preview {
    DashboardView()
}
