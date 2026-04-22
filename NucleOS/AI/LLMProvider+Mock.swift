//
//  LLMProvider+Mock.swift
//  NucleOS
//
//  Mock LLMProvider and mock HealthSummaryPromptBuilder for SwiftUI previews and unit tests.
//  Must not be used in production code paths.
//

#if DEBUG

// MARK: - MockLLMProvider

/// A test double for `LLMProvider` that returns a hardcoded completion string.
///
/// Use this in SwiftUI `#Preview` blocks and unit tests wherever an
/// `any LLMProvider` is required.  It never makes network calls and never
/// loads an on-device model, so it is safe to use in any test environment.
///
/// **Example (SwiftUI preview)**
/// ```swift
/// #Preview {
///     AIBriefingPanelView(provider: MockLLMProvider())
/// }
/// ```
///
/// **Example (unit test)**
/// ```swift
/// let provider = MockLLMProvider()
/// let result = try await provider.complete(prompt: "Hello")
/// #expect(result == MockLLMProvider.hardcodedResponse)
/// ```
struct MockLLMProvider: LLMProvider {

    // MARK: LLMProvider

    let name: String = "Mock Provider"

    var isAvailable: Bool { true }

    /// The fixed string returned by every call to `complete(prompt:)`.
    nonisolated static let hardcodedResponse = "This is a mock AI response for previews and tests."

    /// Returns `MockLLMProvider.hardcodedResponse` regardless of `prompt`.
    func complete(prompt: String) async throws -> String {
        MockLLMProvider.hardcodedResponse
    }
}

// MARK: - MockHealthSummaryPromptBuilder

/// A test double for `HealthSummaryPromptBuilder` that returns a hardcoded prompt string.
///
/// Use this in unit tests wherever an `any HealthSummaryPromptBuilder` is required.
/// It never accesses HealthKit and ignores the snapshot contents, making it safe
/// and deterministic in any test environment.
///
/// **Example (unit test)**
/// ```swift
/// let builder = MockHealthSummaryPromptBuilder()
/// let prompt = builder.build(from: MockData.healthSnapshot)
/// #expect(prompt == MockHealthSummaryPromptBuilder.hardcodedPrompt)
/// ```
struct MockHealthSummaryPromptBuilder: HealthSummaryPromptBuilder {

    /// The fixed string returned by every call to `build(from:)`.
    nonisolated static let hardcodedPrompt = "Mock health prompt for previews and tests."

    /// Returns `MockHealthSummaryPromptBuilder.hardcodedPrompt` regardless of snapshot contents.
    func build(from snapshot: HealthSnapshot) -> String {
        MockHealthSummaryPromptBuilder.hardcodedPrompt
    }
}

#endif
