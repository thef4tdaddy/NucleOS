//
//  LLMProviderTests.swift
//  NucleOSTests/AI
//
//  Swift Testing suite for MockLLMProvider — verifies protocol conformance
//  and the hardcoded response contract used in previews and other tests.
//

import Testing
@testable import NucleOS

@Suite("LLM Provider")
struct LLMProviderTests {

    // MARK: - MockLLMProvider metadata

    @Test("MockLLMProvider.name is non-empty")
    func mockNameIsNonEmpty() {
        let provider = MockLLMProvider()
        #expect(!provider.name.isEmpty)
    }

    @Test("MockLLMProvider.isAvailable is true")
    func mockIsAvailable() {
        let provider = MockLLMProvider()
        #expect(provider.isAvailable)
    }

    // MARK: - MockLLMProvider.complete

    @Test("complete returns hardcoded response regardless of prompt")
    func completeReturnsHardcodedResponse() async throws {
        let provider = MockLLMProvider()
        let result = try await provider.complete(prompt: "Tell me about my day")
        #expect(result == MockLLMProvider.hardcodedResponse)
    }

    @Test("complete returns hardcoded response for empty prompt")
    func completeReturnsHardcodedResponseForEmptyPrompt() async throws {
        let provider = MockLLMProvider()
        let result = try await provider.complete(prompt: "")
        #expect(result == MockLLMProvider.hardcodedResponse)
    }

    @Test("hardcodedResponse is non-empty")
    func hardcodedResponseIsNonEmpty() {
        #expect(!MockLLMProvider.hardcodedResponse.isEmpty)
    }

    // MARK: - Protocol conformance

    @Test("MockLLMProvider can be used as any LLMProvider")
    func mockConformsToProtocol() async throws {
        let provider: any LLMProvider = MockLLMProvider()
        #expect(!provider.name.isEmpty)
        #expect(provider.isAvailable)
        let result = try await provider.complete(prompt: "Hello")
        #expect(!result.isEmpty)
    }
}
