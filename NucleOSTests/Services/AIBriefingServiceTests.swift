//
//  AIBriefingServiceTests.swift
//  NucleOSTests/Services
//
//  Swift Testing suite for AIBriefingService — mock-only, zero real LLM calls.
//

import Testing
@testable import NucleOS

@Suite("AI Briefing Service")
struct AIBriefingServiceTests {

    // MARK: - MockAIBriefingService — hasAvailableProvider

    @Test("MockAIBriefingService.hasAvailableProvider is true by default")
    func mockHasAvailableProviderDefault() {
        let service = MockAIBriefingService()
        #expect(service.hasAvailableProvider)
    }

    @Test("MockAIBriefingService.hasAvailableProvider honours init parameter")
    func mockHasAvailableProviderFalse() {
        let service = MockAIBriefingService(hasAvailableProvider: false)
        #expect(!service.hasAvailableProvider)
    }

    // MARK: - MockAIBriefingService — generate

    @Test("generate returns non-empty string when provider is available")
    func generateReturnsNonEmpty() async throws {
        let service = MockAIBriefingService()
        let result = try await service.generate()
        #expect(!result.isEmpty)
    }

    @Test("generate returns MockData.aiBriefing content")
    func generateReturnsMockData() async throws {
        let service = MockAIBriefingService()
        let result = try await service.generate()
        #expect(result == MockData.aiBriefing)
    }

    @Test("generate throws noProviderAvailable when provider unavailable")
    func generateThrowsWhenUnavailable() async {
        let service = MockAIBriefingService(hasAvailableProvider: false)
        await #expect(throws: AIBriefingError.noProviderAvailable) {
            _ = try await service.generate()
        }
    }

    // MARK: - Protocol conformance

    @Test("MockAIBriefingService conforms to AIBriefingServiceProtocol")
    func mockConformsToProtocol() {
        let service: any AIBriefingServiceProtocol = MockAIBriefingService()
        #expect(service.hasAvailableProvider)
    }

    // MARK: - AIBriefingService — hasAvailableProvider

    @Test("AIBriefingService.hasAvailableProvider reflects provider.isAvailable")
    func realServiceHasAvailableProviderMatchesProvider() {
        let provider = MockLLMProvider()
        let service = AIBriefingService(provider: provider)
        #expect(service.hasAvailableProvider == provider.isAvailable)
    }

    // MARK: - AIBriefingService — generate

    @Test("AIBriefingService.generate returns provider completion")
    func realServiceGenerateReturnsCompletion() async throws {
        let provider = MockLLMProvider()
        let service = AIBriefingService(provider: provider)
        let result = try await service.generate()
        #expect(result == MockLLMProvider.hardcodedResponse)
    }

    // MARK: - AIBriefingError

    @Test("AIBriefingError.noProviderAvailable has non-empty description")
    func errorDescriptionNonEmpty() {
        let error = AIBriefingError.noProviderAvailable
        #expect(!(error.errorDescription?.isEmpty ?? true))
    }
}
