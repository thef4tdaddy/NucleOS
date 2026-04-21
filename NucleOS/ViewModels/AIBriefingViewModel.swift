//
//  AIBriefingViewModel.swift
//  NucleOS
//
//  Observable view model for the AI Briefing dashboard panel.
//  Owns all async generation logic and state, keeping the view layer thin.
//

import Combine
import Foundation

// MARK: - AIBriefingState

/// Represents every possible UI state of the AI Briefing panel.
enum AIBriefingState {
    /// Provider is available but no briefing has been requested yet.
    case idle
    /// A generation call is in progress.
    case loading
    /// A briefing was successfully returned by the service.
    case loaded(String)
    /// No LLM provider is configured or available.
    case unavailable
    /// An error occurred during generation.
    case error(Error)
}

// MARK: - AIBriefingViewModel

/// Drives the AI Briefing dashboard panel.
///
/// Inject a custom ``AIBriefingServiceProtocol`` conformance in previews and tests.
/// Pass an optional ``HealthSnapshot`` to include health context in the generated
/// briefing when the user has enabled AI health summaries.
@MainActor
final class AIBriefingViewModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var state: AIBriefingState = .idle
    @Published private(set) var lastUpdated: Date?

    // MARK: Health context

    /// The latest health snapshot used to enrich the AI briefing.
    ///
    /// Set this to the current `HealthViewModel.snapshot` value. When non-nil
    /// and `isHealthSummaryEnabled` is `true`, the snapshot is forwarded (via
    /// `DefaultHealthSummaryPromptBuilder`) to the LLM provider as privacy-safe
    /// health context.  Raw HealthKit types never leave the `HealthSnapshot`
    /// privacy boundary.
    ///
    /// Non-@Published intentionally: this value is only read during generate()
    /// and changes do not need to trigger UI updates.
    var healthSnapshot: HealthSnapshot?

    /// `true` when the user has explicitly enabled AI health summaries in Settings.
    ///
    /// Reads `AIBriefingService.healthSummaryEnabledKey` from `UserDefaults`.
    /// Defaults to `false` — health data is never sent to an LLM provider until
    /// the user opts in.
    var isHealthSummaryEnabled: Bool {
        UserDefaults.standard.bool(forKey: AIBriefingService.healthSummaryEnabledKey)
    }

    // MARK: Private

    private let service: any AIBriefingServiceProtocol
    /// Guards against concurrent generation calls. Safe to access on `@MainActor`.
    private var isGenerating = false

    // MARK: Init

    init(
        service: any AIBriefingServiceProtocol = AIBriefingService(),
        healthSnapshot: HealthSnapshot? = nil
    ) {
        self.service = service
        self.healthSnapshot = healthSnapshot
    }

    // MARK: - Lifecycle

    /// Called when the panel appears. Sets unavailable state when no provider is
    /// configured, and auto-generates if the user has opted in via
    /// `AIBriefingService.autoGenerateKey`.
    ///
    /// SwiftUI's `.task` modifier re-runs this whenever the view is re-inserted
    /// into the hierarchy, so the availability check runs each time.
    func initialise() async {
        guard service.hasAvailableProvider else {
            state = .unavailable
            return
        }
        state = .idle
        guard UserDefaults.standard.bool(forKey: AIBriefingService.autoGenerateKey) else {
            return
        }
        await generate()
    }

    // MARK: - Generation

    /// Requests a new briefing from the service.
    ///
    /// When `isHealthSummaryEnabled` is `true` and a `healthSnapshot` is available,
    /// the snapshot is forwarded to the service so privacy-safe health context is
    /// included in the LLM prompt. When health summaries are disabled, `nil` is
    /// passed and health data is never sent to the provider.
    ///
    /// Guards against concurrent invocations — additional taps while a generation
    /// is in progress are ignored. Maps `noProviderAvailable` errors to
    /// `.unavailable` so the panel reflects the correct state rather than showing
    /// the "Generate" button for a provider that is no longer reachable.
    func generate() async {
        guard !isGenerating else { return }
        guard service.hasAvailableProvider else {
            state = .unavailable
            return
        }
        isGenerating = true
        state = .loading
        defer { isGenerating = false }
        do {
            let snapshot = isHealthSummaryEnabled ? healthSnapshot : nil
            let briefing = try await service.generate(healthSnapshot: snapshot)
            lastUpdated = Date()
            state = .loaded(briefing)
        } catch AIBriefingError.noProviderAvailable {
            state = .unavailable
        } catch {
            // Transient error — let the user retry if the provider is still available.
            state = .error(error)
        }
    }
}
