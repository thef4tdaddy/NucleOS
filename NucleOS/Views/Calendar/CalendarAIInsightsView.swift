//
//  CalendarAIInsightsView.swift
//  NucleOS
//
//  AI-powered calendar insights panel
//

import SwiftUI

/// Panel showing AI-generated calendar insights and analysis.
struct CalendarAIInsightsView: View {
    let events: [NucleEvent]
    @StateObject private var aiService = CalendarAIService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.accentPrimary)

                Text("AI Insights")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                if aiService.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: { Task { await aiService.generateDailyBriefing(events: events) } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let insight = aiService.lastInsight {
                Text(insight)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(4)
            } else if let error = aiService.error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            } else {
                Text("Tap refresh to generate AI insights about your schedule.")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
        .task {
            if !events.isEmpty {
                await aiService.generateDailyBriefing(events: events)
            }
        }
    }
}

#Preview {
    CalendarAIInsightsView(events: MockData.events)
        .padding()
        .background(Color.backgroundPrimary)
}