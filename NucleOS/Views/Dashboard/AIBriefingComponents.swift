//
//  AIBriefingComponents.swift
//  NucleOS
//
//  AI briefing panel and briefing bullet
//
//  HEALTH SUMMARY SURFACE
//  ======================
//  `AIBriefingPanelView` is the designated UI destination for AI-generated health
//  summaries. When the `HealthSummaryPromptBuilder` + `LLMProvider` pipeline is
//  implemented (milestone 0.4.0+), its one-sentence observation (e.g. "You're on
//  track — 8,234 steps and 7h of sleep last night.") should be surfaced here as a
//  `BriefingBullet`, alongside the existing calendar and tasks bullets.
//
//  Output framing rules that MUST be respected when health bullets are added:
//  • Observations only — never advice. "You got 7h 23m of sleep" not "Sleep more."
//  • Celebratory when a goal is met: "Steps goal hit today 🎉"
//  • Neutral when not: "1,766 steps remaining to hit your goal"
//  • No trend language that implies medical significance ("declining", "worrying").
//

import SwiftUI

struct AIBriefingPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentLavender)

                Text("AI Briefing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("Updated 2m ago")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Good morning! Here's your daily briefing:")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)

                BriefingBullet(text: "You have 4 events today, including a design sync at 2pm")
                BriefingBullet(text: "You're 82% towards your step goal — consider a walk after lunch")
                BriefingBullet(text: "3 tasks are due today, 2 marked high priority")
                BriefingBullet(text: "Your sleep was 7h 23m last night, slightly below your 8h goal")
            }

            Button(action: {}, label: {
                Text("Ask AI a question")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentPrimary)
            })
            .buttonStyle(.plain)
        }
        .padding(20)
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

struct BriefingBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
        }
    }
}
