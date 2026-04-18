// TODO: Implement full provider
//
//  OpenAIProvider.swift
//  NucleOS
//
//  Stub implementation of LLMProvider for OpenAI.
//  Not yet functional — establishes the conformance pattern and file location.
//  Full implementation is deferred to a later milestone.
//

import Foundation

// MARK: - OpenAIProvider

/// Stub LLM provider for OpenAI (provider #4 in NucleOS priority order).
///
/// This type conforms to `LLMProvider` but is not yet functional.
/// `isAvailable` always returns `false` and `complete(prompt:)` throws
/// `LLMProviderError.notImplemented`. No API keys are read or stored by this stub.
///
/// The Keychain service identifier for the OpenAI API key is ``keychainService``.
struct OpenAIProvider: LLMProvider {

    // MARK: - Constants

    /// Keychain service identifier used to store the OpenAI API key.
    static let keychainService = "com.f4tdaddy.nucleos.openai-api-key"

    // MARK: - LLMProvider

    nonisolated var name: String { "OpenAI" }

    /// Always `false` — provider is not yet implemented.
    nonisolated var isAvailable: Bool { false }

    /// Always throws `LLMProviderError.notImplemented`.
    nonisolated func complete(prompt: String) async throws -> String {
        throw LLMProviderError.notImplemented
    }
}
