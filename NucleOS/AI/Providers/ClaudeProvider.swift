// TODO: Implement full provider
//
//  ClaudeProvider.swift
//  NucleOS
//
//  Stub implementation of LLMProvider for Anthropic Claude.
//  Not yet functional — establishes the conformance pattern and file location.
//  Full implementation is deferred to a later milestone.
//

// MARK: - ClaudeProvider

/// Stub LLM provider for Anthropic Claude (provider #3 in NucleOS priority order).
///
/// This type conforms to `LLMProvider` but is not yet functional.
/// `isAvailable` always returns `false` and `complete(prompt:)` throws
/// `LLMProviderError.notImplemented`. No API keys are read or stored by this stub.
///
/// The Keychain account key for the Claude API key is ``keychainAccountKey``.
struct ClaudeProvider: LLMProvider {

    // MARK: - Constants

    /// Keychain account key used with the shared NucleOS Keychain service.
    static let keychainAccountKey = KeychainHelper.anthropicAPIKey

    // MARK: - LLMProvider

    nonisolated var name: String { "Claude" }

    /// Always `false` — provider is not yet implemented.
    nonisolated var isAvailable: Bool { false }

    /// Always throws `LLMProviderError.notImplemented`.
    nonisolated func complete(prompt: String) async throws -> String {
        throw LLMProviderError.notImplemented
    }
}
