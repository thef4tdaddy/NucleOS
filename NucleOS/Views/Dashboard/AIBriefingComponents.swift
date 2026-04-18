//
//  AIBriefingComponents.swift
//  NucleOS
//
//  AI briefing panel wired to AIBriefingService.
//
//  UI STATES
//  =========
//  • idle       — provider available but briefing not yet requested; shows a generate button.
//  • loading    — LLM call in progress; shows a spinner.
//  • loaded     — briefing text returned by the service; shows prose output.
//  • unavailable — no LLM provider configured; shows a soft prompt to enable AI in Settings.
//
//  AUTO-GENERATE BEHAVIOUR
//  =======================
//  The panel fires a generation on `.task` only when the user has opted in via
//  `AIBriefingService.autoGenerateKey` (UserDefaults bool, default `false`).
//  All other invocations require an explicit tap of the "Generate Briefing" button.
//
//  HEALTH SUMMARY SURFACE
//  ======================
//  `AIBriefingPanelView` is the designated UI destination for AI-generated health
//  summaries.  When the `HealthSummaryPromptBuilder` + `LLMProvider` pipeline is
//  fully integrated (milestone 0.4.0+), its one-sentence observation should be
//  surfaced here alongside calendar and tasks context.
//
//  Output framing rules that MUST be respected when health bullets are added:
//  • Observations only — never advice. "You got 7h 23m of sleep" not "Sleep more."
//  • Celebratory when a goal is met: "Steps goal hit today 🎉"
//  • Neutral when not: "1,766 steps remaining to hit your goal"
//  • No trend language that implies medical significance ("declining", "worrying").
//

import SwiftUI

// MARK: - State

private enum AIBriefingState {
    case idle
    case loading
    case loaded(String)
    case unavailable
}

// MARK: - Panel View

/// Dashboard panel that displays a real AI-generated daily briefing.
///
/// Inject a custom ``AIBriefingServiceProtocol`` for previews and tests.
struct AIBriefingPanelView: View {

    // MARK: Dependencies

    private let service: any AIBriefingServiceProtocol

    // MARK: State

    @State private var state: AIBriefingState = .idle
    @State private var lastUpdated: Date?

    // MARK: Init

    init(service: any AIBriefingServiceProtocol = AIBriefingService(provider: MLXProvider())) {
        self.service = service
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            contentView
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
        .task {
            await initialise()
        }
    }

    // MARK: Subviews

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.accentLavender)

            Text("AI Briefing")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)

            Spacer()

            switch state {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .tint(.accentLavender)

            case .loaded:
                if let updated = lastUpdated {
                    Text(relativeTime(from: updated))
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Button(action: { Task { await generate() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                .buttonStyle(.plain)

            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .idle:
            idleView
        case .loading:
            loadingView
        case .loaded(let briefing):
            loadedView(briefing: briefing)
        case .unavailable:
            unavailableView
        }
    }

    private var idleView: some View {
        Button(action: { Task { await generate() } }) {
            Label("Generate Briefing", systemImage: "sparkles")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.accentPrimary)
        }
        .buttonStyle(.plain)
    }

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(.accentLavender)
            Text("Generating your briefing…")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
    }

    private func loadedView(briefing: String) -> some View {
        Text(briefing)
            .font(.system(size: 13))
            .foregroundColor(.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var unavailableView: some View {
        Text("Enable AI in Settings to see your briefing.")
            .font(.system(size: 13))
            .foregroundColor(.textMuted)
    }

    // MARK: Actions

    /// Called once on `.task`: sets unavailable state or auto-generates if opted in.
    private func initialise() async {
        guard service.hasAvailableProvider else {
            state = .unavailable
            return
        }
        guard UserDefaults.standard.bool(forKey: AIBriefingService.autoGenerateKey) else {
            return
        }
        await generate()
    }

    /// Triggers a generation regardless of current state.
    private func generate() async {
        state = .loading
        do {
            let briefing = try await service.generate()
            lastUpdated = Date()
            state = .loaded(briefing)
        } catch {
            // On error, return to idle so the user can retry.
            state = .idle
        }
    }

    // MARK: Helpers

    private func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "Updated just now" }
        if seconds < 3600 { return "Updated \(seconds / 60)m ago" }
        return "Updated \(seconds / 3600)h ago"
    }
}

// MARK: - Briefing Bullet

/// A single bullet point in the AI briefing panel.
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

// MARK: - Previews

#Preview("Loaded") {
    AIBriefingPanelView(service: MockAIBriefingService())
        .padding()
        .background(Color.backgroundPrimary)
        .frame(width: 500)
}

#Preview("Unavailable") {
    AIBriefingPanelView(service: MockAIBriefingService(hasAvailableProvider: false))
        .padding()
        .background(Color.backgroundPrimary)
        .frame(width: 500)
}
