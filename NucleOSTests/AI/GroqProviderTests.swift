//
//  GroqProviderTests.swift
//  NucleOSTests/AI
//
//  Swift Testing suite for GroqProvider.
//  Tests availability checks and constants without requiring a live API key
//  or network access.
//

import Testing
import Foundation
@testable import NucleOS

@Suite("Groq Provider")
struct GroqProviderTests {

    // MARK: - Helpers

    private func makeProvider() -> GroqProvider {
        GroqProvider()
    }

    // MARK: - Constants

    @Test("defaultModel is the expected Groq model identifier")
    func defaultModelIsCorrect() {
        #expect(GroqProvider.defaultModel == "llama3-8b-8192")
    }

    // MARK: - Metadata

    @Test("name contains the default model identifier")
    func nameContainsDefaultModel() {
        let provider = makeProvider()
        #expect(provider.name.contains(GroqProvider.defaultModel))
    }

    @Test("name is non-empty")
    func nameIsNonEmpty() {
        let provider = makeProvider()
        #expect(!provider.name.isEmpty)
    }

    // MARK: - isAvailable

    @Test("isAvailable is false when no API key is in Keychain")
    func isAvailableFalseWhenNoKey() throws {
        try? KeychainHelper.delete(key: KeychainHelper.groqAPIKey)
        let provider = makeProvider()
        #expect(!provider.isAvailable)
    }

    @Test("isAvailable is true when a non-empty API key is in Keychain")
    func isAvailableTrueWhenKeyPresent() throws {
        try KeychainHelper.save(key: KeychainHelper.groqAPIKey, value: "test-key-12345")
        defer { try? KeychainHelper.delete(key: KeychainHelper.groqAPIKey) }
        let provider = makeProvider()
        #expect(provider.isAvailable)
    }

    @Test("isAvailable is false when Keychain key is an empty string")
    func isAvailableFalseWhenEmptyKey() throws {
        try KeychainHelper.save(key: KeychainHelper.groqAPIKey, value: "")
        defer { try? KeychainHelper.delete(key: KeychainHelper.groqAPIKey) }
        let provider = makeProvider()
        #expect(!provider.isAvailable)
    }

    @Test("isAvailable is false when Keychain key is only whitespace")
    func isAvailableFalseWhenWhitespaceKey() throws {
        try KeychainHelper.save(key: KeychainHelper.groqAPIKey, value: "   ")
        defer { try? KeychainHelper.delete(key: KeychainHelper.groqAPIKey) }
        let provider = makeProvider()
        #expect(!provider.isAvailable)
    }

    // MARK: - complete — error paths (no live network required)

    @Test("complete throws LLMProviderError.unavailable when no API key is present")
    func completeThrowsUnavailableWhenNoKey() async {
        try? KeychainHelper.delete(key: KeychainHelper.groqAPIKey)
        let provider = makeProvider()
        do {
            _ = try await provider.complete(prompt: "hello")
            Issue.record("Expected complete to throw when API key is absent")
        } catch let error as LLMProviderError {
            switch error {
            case .unavailable:
                break
            default:
                Issue.record("Expected .unavailable, got: \(error)")
            }
        } catch {
            Issue.record("Expected LLMProviderError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Protocol conformance

    @Test("GroqProvider can be used as any LLMProvider")
    func conformsToProtocol() {
        let provider: any LLMProvider = GroqProvider()
        #expect(!provider.name.isEmpty)
    }

    // MARK: - LLMProviderError new cases

    @Test("LLMProviderError.rateLimitExceeded has a non-empty description")
    func rateLimitExceededDescription() {
        let error = LLMProviderError.rateLimitExceeded
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription ?? "").isEmpty)
    }

    @Test("LLMProviderError.networkError has a non-empty description")
    func networkErrorDescription() {
        let underlying = URLError(.notConnectedToInternet)
        let error = LLMProviderError.networkError(underlying: underlying)
        #expect(error.errorDescription != nil)
        #expect(!(error.errorDescription ?? "").isEmpty)
    }
}
