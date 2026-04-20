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

/// Concrete implementation that routes briefing requests to the first available ``LLMProvider``.
///
/// Providers are evaluated in the order they appear in the `providers` array.  The service
/// picks the first one where `isAvailable == true` at call time, so availability is
/// re-evaluated on every call — no caching or manual re-configuration required.
///
/// **Priority order (default production init)**
/// 1. MLX · Phi-3 mini — on-device, zero network, Apple Silicon only
/// 2. Groq — cloud, free tier, requires Keychain API key
/// 3. Claude — cloud, premium, requires Keychain API key
/// 4. OpenAI — cloud, requires Keychain API key
///
/// **Injection (tests & previews)**
/// ```swift
/// let service = AIBriefingService(providers: [MockLLMProvider()])
/// // or single-provider convenience:
/// let service = AIBriefingService(provider: MockLLMProvider())
/// ```
struct AIBriefingService: AIBriefingServiceProtocol {

    // MARK: Constants

    /// UserDefaults key for the user's chosen LLM provider.
    /// Value type: `String` — raw value of ``LLMProviderOption``.
    /// Defaults to ``LLMProviderOption/mlx`` when absent.
    static let selectedProviderKey = "selectedLLMProvider"

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

    private let providers: [any LLMProvider]
    private let promptBuilder: any HealthSummaryPromptBuilder

    // MARK: Init

    /// Default production init.
    ///
    /// Configures all four providers in priority order:
    /// MLX (on-device) → Groq → Claude → OpenAI.
    /// The service automatically selects the first provider where `isAvailable == true`.
    init(promptBuilder: any HealthSummaryPromptBuilder = DefaultHealthSummaryPromptBuilder()) {
        self.providers = [MLXProvider(), GroqProvider(), ClaudeProvider(), OpenAIProvider()]
        self.promptBuilder = promptBuilder
    }

    /// Creates an instance with an explicit ordered list of providers.
    ///
    /// The service selects the first provider where `isAvailable == true`.
    /// Pass providers in descending priority order (most preferred first).
    /// An empty array is valid and will always produce ``AIBriefingError/noProviderAvailable``.
    ///
    /// - Parameters:
    ///   - providers: Ordered list of providers. The service picks the first available one.
    ///   - promptBuilder: Converts a ``HealthSnapshot`` into a safe prompt string.
    init(
        providers: [any LLMProvider],
        promptBuilder: any HealthSummaryPromptBuilder = DefaultHealthSummaryPromptBuilder()
    ) {
        self.providers = providers
        self.promptBuilder = promptBuilder
    }

    /// Convenience init for a single provider. Wraps `provider` in a one-element array.
    init(
        provider: any LLMProvider,
        promptBuilder: any HealthSummaryPromptBuilder = DefaultHealthSummaryPromptBuilder()
    ) {
        self.providers = [provider]
        self.promptBuilder = promptBuilder
    }

    // MARK: Routing

    /// Returns the provider matching the user's UserDefaults selection when it is available.
    /// Falls back to the first available provider in priority order when the selected
    /// provider is unavailable (e.g. no API key, MLX not installed).
    private var activeProvider: (any LLMProvider)? {
        if let selected = userSelectedProvider, selected.isAvailable {
            return selected
        }
        return providers.first { $0.isAvailable }
    }

    /// Returns the provider instance that corresponds to the user's persisted
    /// ``LLMProviderOption`` selection, or `nil` when no preference is stored.
    private var userSelectedProvider: (any LLMProvider)? {
        let raw = UserDefaults.standard.string(forKey: AIBriefingService.selectedProviderKey) ?? ""
        guard let option = LLMProviderOption(rawValue: raw) else { return nil }
        switch option {
        case .mlx:       return providers.first { $0 is MLXProvider }
        case .groq:      return providers.first { $0 is GroqProvider }
        case .anthropic: return providers.first { $0 is ClaudeProvider }
        case .openai:    return providers.first { $0 is OpenAIProvider }
        }
    }

    // MARK: AIBriefingServiceProtocol

    /// `true` when at least one provider in the ordered list is available.
    var hasAvailableProvider: Bool { activeProvider != nil }

    /// Generates a daily briefing by routing the request to the first available ``LLMProvider``.
    ///
    /// Provider availability is evaluated at call time so a provider that becomes available
    /// after the service is initialised is picked up automatically on the next call.
    ///
    /// When `healthSnapshot` is non-nil, the prompt includes privacy-safe health context
    /// produced by the ``HealthSummaryPromptBuilder``. The caller is responsible for
    /// verifying user opt-in before passing a non-nil snapshot.
    ///
    /// - Parameter healthSnapshot: Optional aggregate health metrics to include as context.
    ///   Only aggregate values from ``HealthSnapshot`` ever reach the LLM —
    ///   raw HealthKit types are never forwarded.
    /// - Throws: ``AIBriefingError/noProviderAvailable`` when no provider is available.
    func generate(healthSnapshot: HealthSnapshot?) async throws -> String {
        guard let provider = activeProvider else {
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
