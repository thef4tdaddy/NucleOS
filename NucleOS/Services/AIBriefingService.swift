//
//  AIBriefingService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for AI-generated daily briefings.
//

import Foundation

// MARK: - Protocol

/// Declares the async interface for generating AI daily briefings.
protocol AIBriefingServiceProtocol {
    /// `true` when at least one `LLMProvider` is configured and ready.
    var hasAvailableProvider: Bool { get }
    /// Generates and returns a briefing string using the active LLM provider.
    ///
    /// - Parameter healthSnapshot: An optional aggregate health snapshot to include
    ///   as context in the briefing. Pass `nil` when the user has not opted in to
    ///   AI health summaries, or when no snapshot is available. The caller is
    ///   responsible for verifying user opt-in before passing a non-nil value.
    func generate(healthSnapshot: HealthSnapshot?) async throws -> String
}

// MARK: - Protocol Default

extension AIBriefingServiceProtocol {
    /// Generates a briefing without health context.
    ///
    /// Convenience overload — delegates to `generate(healthSnapshot:)` with `nil`.
    func generate() async throws -> String {
        try await generate(healthSnapshot: nil)
    }
}

// MARK: - Errors

/// Errors that can be thrown by ``AIBriefingServiceProtocol`` implementations.
enum AIBriefingError: Error, LocalizedError, Equatable {
    /// No LLM provider is configured or available.
    case noProviderAvailable

    var errorDescription: String? {
        switch self {
        case .noProviderAvailable:
            return "No AI provider is available. Enable one in Settings."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that delegates to any ``LLMProvider``.
struct AIBriefingService: AIBriefingServiceProtocol {

    // MARK: Constants

    /// UserDefaults key for the opt-in auto-generate-on-appear setting.
    /// When `true`, the AI briefing panel generates a briefing automatically on appear.
    /// Defaults to `false` — generation always requires an explicit user action unless opted in.
    static let autoGenerateKey = "aiAutoGenerateBriefing"

    /// UserDefaults key for the opt-in AI health summary setting.
    /// When `true`, a `HealthSnapshot` is included as context in generated briefings.
    /// Defaults to `false` — health context is never sent to an LLM provider unless
    /// the user has explicitly enabled this feature.
    static let healthSummaryEnabledKey = "aiHealthSummaryEnabled"

    // MARK: Private

    private let provider: any LLMProvider
    private let promptBuilder: any HealthSummaryPromptBuilder

    // MARK: Init

    init(
        provider: any LLMProvider,
        promptBuilder: any HealthSummaryPromptBuilder = DefaultHealthSummaryPromptBuilder()
    ) {
        self.provider = provider
        self.promptBuilder = promptBuilder
    }

    // MARK: AIBriefingServiceProtocol

    var hasAvailableProvider: Bool { provider.isAvailable }

    /// Generates a daily briefing by sending a prompt to the active ``LLMProvider``.
    ///
    /// When `healthSnapshot` is non-nil, the prompt includes privacy-safe health
    /// context produced by the ``HealthSummaryPromptBuilder``. The caller is
    /// responsible for verifying user opt-in before passing a non-nil snapshot.
    ///
    /// - Parameter healthSnapshot: Optional aggregate health metrics to include as
    ///   context. Only aggregate values from ``HealthSnapshot`` ever reach the LLM —
    ///   raw HealthKit types are never forwarded.
    /// - Throws: ``AIBriefingError/noProviderAvailable`` when `hasAvailableProvider` is `false`.
    func generate(healthSnapshot: HealthSnapshot?) async throws -> String {
        guard provider.isAvailable else {
            throw AIBriefingError.noProviderAvailable
        }

        var prompt = """
            You are a helpful life-dashboard assistant. \
            Generate a concise, friendly daily briefing in 2–4 sentences. \
            Focus on what the user should be aware of or prioritise today. \
            Keep the tone positive and the response brief.
            """

        if let snapshot = healthSnapshot {
            let healthContext = promptBuilder.build(from: snapshot)
            prompt += "\n\n\(healthContext)"
        }

        return try await provider.complete(prompt: prompt)
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by ``MockData`` for SwiftUI previews and unit tests.
struct MockAIBriefingService: AIBriefingServiceProtocol {

    /// Controls the simulated availability of the provider.
    var hasAvailableProvider: Bool

    init(hasAvailableProvider: Bool = true) {
        self.hasAvailableProvider = hasAvailableProvider
    }

    /// Returns ``MockData/aiBriefing`` when a provider is available.
    ///
    /// The `healthSnapshot` parameter is accepted but ignored — mock output is
    /// always the same regardless of health context.
    ///
    /// - Throws: ``AIBriefingError/noProviderAvailable`` when `hasAvailableProvider` is `false`.
    func generate(healthSnapshot: HealthSnapshot?) async throws -> String {
        guard hasAvailableProvider else {
            throw AIBriefingError.noProviderAvailable
        }
        return MockData.aiBriefing
    }
}
