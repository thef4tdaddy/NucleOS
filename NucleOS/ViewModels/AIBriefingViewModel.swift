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

    private static let cacheTextKey = "nucleos.ai.briefing.cache"
    private static let cacheTimestampKey = "nucleos.ai.briefing.timestamp"
    private static let cacheTTL: TimeInterval = 4 * 60 * 60

    // MARK: Init

    init(
        service: (any AIBriefingServiceProtocol)? = nil,
        healthSnapshot: HealthSnapshot? = nil
    ) {
        self.service = service ?? AIBriefingService()
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
            print("[AIBriefing] No provider available — configure MLX model path or add a cloud API key in Settings.")
            state = .unavailable
            return
        }

        if let (cached, cachedAt) = loadCachedBriefing() {
            lastUpdated = cachedAt
            state = .loaded(cached)
            let age = Date().timeIntervalSince(cachedAt)
            guard age >= Self.cacheTTL else { return }
        } else {
            state = .idle
        }

        guard UserDefaults.standard.bool(forKey: AIBriefingService.autoGenerateKey) else {
            return
        }
        await generate()
    }

    // MARK: - Cache

    /// Returns the cached briefing text and its timestamp, or `nil` if no cache exists.
    private func loadCachedBriefing() -> (String, Date)? {
        guard
            let text = UserDefaults.standard.string(forKey: Self.cacheTextKey),
            !text.isEmpty
        else { return nil }
        let ts = UserDefaults.standard.double(forKey: Self.cacheTimestampKey)
        guard ts > 0 else { return nil }
        return (text, Date(timeIntervalSinceReferenceDate: ts))
    }

    private func saveCachedBriefing(_ text: String, at date: Date) {
        UserDefaults.standard.set(text, forKey: Self.cacheTextKey)
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: Self.cacheTimestampKey)
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
            print("[AIBriefing] generate() called but no provider is available.")
            state = .unavailable
            return
        }
        isGenerating = true
        state = .loading
        defer { isGenerating = false }
        do {
            let snapshot = isHealthSummaryEnabled ? healthSnapshot : nil
            let briefing = try await service.generate(healthSnapshot: snapshot)
            let now = Date()
            lastUpdated = now
            saveCachedBriefing(briefing, at: now)
            state = .loaded(briefing)
        } catch AIBriefingError.noProviderAvailable {
            print("[AIBriefing] Generation failed: no provider available.")
            state = .unavailable
        } catch {
            print("[AIBriefing] Generation failed: \(error)")
            state = .error(error)
        }
    }
}
