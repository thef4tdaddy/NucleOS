//
//  AIBriefingViewModel.swift
//  NucleOS
//
//  Observable view model for the AI Briefing dashboard panel.
//  Owns all async generation logic and state, keeping the view layer thin.
//

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
}

// MARK: - AIBriefingViewModel

/// Drives the AI Briefing dashboard panel.
///
/// Inject a custom ``AIBriefingServiceProtocol`` conformance in previews and tests.
@MainActor
final class AIBriefingViewModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var state: AIBriefingState = .idle
    @Published private(set) var lastUpdated: Date?

    // MARK: Private

    private let service: any AIBriefingServiceProtocol
    /// Guards against concurrent generation calls. Safe to access on `@MainActor`.
    private var isGenerating = false

    // MARK: Init

    init(service: any AIBriefingServiceProtocol = AIBriefingService(provider: MLXProvider())) {
        self.service = service
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
        guard UserDefaults.standard.bool(forKey: AIBriefingService.autoGenerateKey) else {
            return
        }
        await generate()
    }

    // MARK: - Generation

    /// Requests a new briefing from the service.
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
            let briefing = try await service.generate()
            lastUpdated = Date()
            state = .loaded(briefing)
        } catch AIBriefingError.noProviderAvailable {
            state = .unavailable
        } catch {
            // Transient error — let the user retry if the provider is still available.
            state = service.hasAvailableProvider ? .idle : .unavailable
        }
    }
}
