// TODO: Implement full provider
//
//  ClaudeProvider.swift
//  NucleOS
//
//  Stub implementation of LLMProvider for Anthropic Claude.
//  Not yet functional — establishes the conformance pattern and file location.
//  Full implementation is deferred to a later milestone.
//

import Foundation

// MARK: - ClaudeProvider

/// Stub LLM provider for Anthropic Claude (provider #3 in NucleOS priority order).
///
/// This type conforms to `LLMProvider` but is not yet functional.
/// `isAvailable` always returns `false` and `complete(prompt:)` throws
/// `LLMProviderError.notImplemented`. No API keys are read or stored by this stub.
///
/// The Keychain service identifier for the Claude API key is ``keychainService``.
struct ClaudeProvider: LLMProvider {

    // MARK: - Constants

    /// Keychain service identifier used to store the Claude API key.
    static let keychainService = "com.f4tdaddy.nucleos.claude-api-key"

    // MARK: - LLMProvider

    nonisolated var name: String { "Claude" }

    /// Always `false` — provider is not yet implemented.
    nonisolated var isAvailable: Bool { false }

    /// Always throws `LLMProviderError.notImplemented`.
    nonisolated func complete(prompt: String) async throws -> String {
        throw LLMProviderError.notImplemented
    }
}
