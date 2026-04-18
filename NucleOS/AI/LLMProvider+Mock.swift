//
//  LLMProvider+Mock.swift
//  NucleOS
//
//  Mock LLMProvider for SwiftUI previews and unit tests.
//  Must not be used in production code paths.
//

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
    static let hardcodedResponse = "This is a mock AI response for previews and tests."

    /// Returns `MockLLMProvider.hardcodedResponse` regardless of `prompt`.
    func complete(prompt: String) async throws -> String {
        MockLLMProvider.hardcodedResponse
    }
}
