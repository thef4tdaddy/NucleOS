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
    func generate() async throws -> String
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

    // MARK: Private

    private let provider: any LLMProvider

    // MARK: Init

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    // MARK: AIBriefingServiceProtocol

    var hasAvailableProvider: Bool { provider.isAvailable }

    /// Generates a daily briefing by sending a prompt to the active ``LLMProvider``.
    ///
    /// - Throws: ``AIBriefingError/noProviderAvailable`` when `hasAvailableProvider` is `false`.
    func generate() async throws -> String {
        guard provider.isAvailable else {
            throw AIBriefingError.noProviderAvailable
        }
        let prompt = """
            You are a helpful life-dashboard assistant. \
            Generate a concise, friendly daily briefing in 2–4 sentences. \
            Focus on what the user should be aware of or prioritise today. \
            Keep the tone positive and the response brief.
            """
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
    /// - Throws: ``AIBriefingError/noProviderAvailable`` when `hasAvailableProvider` is `false`.
    func generate() async throws -> String {
        guard hasAvailableProvider else {
            throw AIBriefingError.noProviderAvailable
        }
        return MockData.aiBriefing
    }
}
