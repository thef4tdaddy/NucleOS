//
//  MLXProviderTests.swift
//  NucleOSTests/AI
//
//  Swift Testing suite for MLXProvider.
//  Covers UserDefaults-driven availability, the modelPathKey constant,
//  protocol conformance, and error-path behaviour — all without requiring
//  a physical model on disk or Apple Silicon.
//

import Testing
import Foundation
@testable import NucleOS

@Suite("MLX Provider")
struct MLXProviderTests {

    // MARK: - Helpers

    /// Creates a fresh MLXProvider after resetting the configured model path key
    /// in UserDefaults for this test setup.
    private func makeProvider(path: String? = nil) -> MLXProvider {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        UserDefaults.standard.removeObject(forKey: MLXProvider.modelPathKey)
        if let path {
            userDefaults.set(path, forKey: MLXProvider.modelPathKey)
        }
        return MLXProvider(userDefaults: userDefaults)
    }

    // MARK: - Metadata

    @Test("name is the expected display string")
    func nameIsCorrect() {
        let provider = MLXProvider()
        #expect(provider.name == "MLX · Phi-3 mini")
    }

    @Test("modelPathKey is the expected UserDefaults key")
    func modelPathKeyIsCorrect() {
        #expect(MLXProvider.modelPathKey == "mlxModelPath")
    }

    // MARK: - isAvailable

    @Test("isAvailable is false when modelPathKey is not set")
    func isAvailableFalseWhenNoPath() {
        let provider = makeProvider()
        #expect(!provider.isAvailable)
    }

    @Test("isAvailable is false when modelPathKey is an empty string")
    func isAvailableFalseWhenEmptyPath() {
        let provider = makeProvider(path: "")
        #expect(!provider.isAvailable)
    }

    @Test("isAvailable is false when modelPathKey is only whitespace")
    func isAvailableFalseWhenWhitespacePath() {
        let provider = makeProvider(path: "   ")
        #expect(!provider.isAvailable)
    }

    // MARK: - complete — error paths (no model on disk)

    @Test("complete throws unavailable when no path is configured")
    func completeThrowsUnavailableWhenNoPath() async {
        let provider = makeProvider()
        await #expect(throws: LLMProviderError.self) {
            _ = try await provider.complete(prompt: "hello")
        }
    }

    @Test("complete throws a typed LLMProviderError when path is missing from disk")
    func completeThrowsTypedErrorForMissingPath() async {
        let provider = makeProvider(path: "/nonexistent/path/to/phi3")
        do {
            _ = try await provider.complete(prompt: "hello")
            Issue.record("Expected complete to throw for a missing model path")
        } catch let error as LLMProviderError {
            // Acceptable errors: unavailable (non-Apple-Silicon CI) or modelNotFound
            switch error {
            case .unavailable, .modelNotFound:
                break
            default:
                Issue.record("Unexpected LLMProviderError case: \(error)")
            }
        } catch {
            Issue.record("Expected LLMProviderError, got \(type(of: error)): \(error)")
        }
    }

    // MARK: - Protocol conformance

    @Test("MLXProvider can be used as any LLMProvider without type error")
    func conformsToProtocol() {
        // Verify that MLXProvider is assignable to `any LLMProvider`.
        // If this compiles and runs, the conformance is correct.
        let provider: any LLMProvider = MLXProvider()
        _ = provider // suppress unused-variable warning
    }

    @Test("MLXProvider.name is non-empty")
    func nameIsNonEmpty() {
        let provider = MLXProvider()
        #expect(!provider.name.isEmpty)
    }
}
