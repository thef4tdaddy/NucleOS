//
//  AIBriefingComponents.swift
//  NucleOS
//
//  AI briefing panel wired to AIBriefingViewModel / AIBriefingService.
//
//  UI STATES  (driven by AIBriefingViewModel)
//  ==========================================
//  • idle       — provider available but briefing not yet requested; shows a generate button.
//  • loading    — LLM call in progress; shows a spinner.
//  • loaded     — briefing text returned by the service; shows prose output.
//  • unavailable — no LLM provider configured; shows a soft prompt to enable AI in Settings.
//
//  AUTO-GENERATE BEHAVIOUR
//  =======================
//  The panel fires a generation automatically only when the user has opted in via
//  `AIBriefingService.autoGenerateKey` (UserDefaults bool, default `false`).
//  All other invocations require an explicit tap of the "Generate Briefing" button.
//  This decision lives in ``AIBriefingViewModel/initialise()``.
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

// MARK: - Panel View

/// Dashboard panel that displays a real AI-generated daily briefing.
///
/// Inject a custom ``AIBriefingServiceProtocol`` via the view model initialiser
/// for previews and tests.
///
/// Pass a ``HealthSnapshot`` to include privacy-safe health context in the
/// generated briefing when the user has enabled AI health summaries in Settings.
@MainActor
struct AIBriefingPanelView: View {

    // MARK: View model

    @StateObject private var viewModel: AIBriefingViewModel

    // MARK: Health context

    /// The current health snapshot forwarded to the view model when it changes.
    var healthSnapshot: HealthSnapshot?

    // MARK: Init

    /// Creates the panel wired to the default production view model.
    ///
    /// Instantiates an ``AIBriefingViewModel`` backed by the real ``AIBriefingService``
    /// (MLX → Groq → Claude → OpenAI priority order). The model loads lazily on the
    /// first inference call.
    ///
    /// - Parameter healthSnapshot: Optional aggregate health metrics forwarded to the
    ///   view model. When non-nil and the user has enabled AI health summaries, these
    ///   values are forwarded (via ``DefaultHealthSummaryPromptBuilder``) to the active
    ///   ``LLMProvider`` as privacy-safe health context.
    init(healthSnapshot: HealthSnapshot? = nil) {
        let viewModel = AIBriefingViewModel()
        viewModel.healthSnapshot = healthSnapshot
        _viewModel = StateObject(wrappedValue: viewModel)
        self.healthSnapshot = healthSnapshot
    }

    /// Creates the panel with an injected view model — use in previews and tests.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that drives panel state.
    ///   - healthSnapshot: Optional aggregate health metrics passed to the view model.
    init(viewModel: AIBriefingViewModel, healthSnapshot: HealthSnapshot? = nil) {
        viewModel.healthSnapshot = healthSnapshot
        _viewModel = StateObject(wrappedValue: viewModel)
        self.healthSnapshot = healthSnapshot
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
            await viewModel.initialise()
        }
        .onChange(of: healthSnapshot) { _, newSnapshot in
            viewModel.healthSnapshot = newSnapshot
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

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .tint(.accentLavender)

            case .loaded:
                if let updated = viewModel.lastUpdated {
                    Text(updated, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Button(action: { Task { await viewModel.generate() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Regenerate briefing")
                .accessibilityHint("Generates a new AI briefing")

            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            idleView
        case .loading:
            loadingView
        case .loaded(let briefing):
            loadedView(briefing: briefing)
        case .unavailable:
            unavailableView
        case .error(let error):
            errorView(error: error)
        }
    }

    private var idleView: some View {
        Button(action: { Task { await viewModel.generate() } }) {
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

    private func errorView(error: Error) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Failed to generate: \(error.localizedDescription)")
                .font(.system(size: 13))
                .foregroundColor(.red)
            idleView
        }
    }

    // MARK: Helpers

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return "Updated \(relative)"
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

#Preview("Idle") {
    AIBriefingPanelView(viewModel: AIBriefingViewModel(service: MockAIBriefingService()))
        .padding()
        .background(Color.backgroundPrimary)
        .frame(width: 500)
}

#Preview("Unavailable") {
    AIBriefingPanelView(
        viewModel: AIBriefingViewModel(service: MockAIBriefingService(hasAvailableProvider: false))
    )
    .padding()
    .background(Color.backgroundPrimary)
    .frame(width: 500)
}
