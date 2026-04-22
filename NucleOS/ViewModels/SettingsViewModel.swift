//
//  SettingsViewModel.swift
//  NucleOS
//
//  Observable view model for the Settings panel.
//  Owns provider selection (UserDefaults) and API key management (Keychain).
//

import SwiftUI
import Combine

// MARK: - TestConnectionState

/// Represents the lifecycle of a provider test-connection request.
enum TestConnectionState {
    /// No test has been initiated.
    case idle
    /// A test completion call is in flight.
    case testing
    /// The provider returned a non-empty response.
    case success(String)
    /// The provider threw an error.
    case failure(String)
}

// MARK: - SettingsViewModel

/// Drives the Settings view.
///
/// Responsibilities:
/// - Persists the selected ``LLMProviderOption`` to `UserDefaults`.
/// - Reads/writes API keys via ``KeychainHelper``.
/// - Runs a live test-connection against the active provider.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: UserDefaults key

    /// UserDefaults key for the user's chosen LLM provider.
    /// Matches `AIBriefingService.selectedProviderKey`.
    static let selectedProviderKey = AIBriefingService.selectedProviderKey

    // MARK: Published state

    /// The currently selected provider.  Changes are persisted to UserDefaults immediately.
    @Published var selectedProvider: LLMProviderOption {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Self.selectedProviderKey)
            refreshAPIKeyStatus()
            apiKeyInput = ""
            saveError = nil
            testConnectionState = .idle
        }
    }

    /// Scratch-pad text field bound to the API key entry field.
    @Published var apiKeyInput: String = ""

    /// `true` when a non-empty key is stored in the Keychain for the current provider.
    @Published private(set) var hasAPIKey: Bool = false

    /// Non-nil when the most recent `saveAPIKey()` call threw an error.
    /// Cleared automatically when a new save attempt begins or the provider changes.
    @Published private(set) var saveError: String?

    /// Reflects the result of the most recent test-connection attempt.
    @Published private(set) var testConnectionState: TestConnectionState = .idle

    // MARK: Platform availability

    /// `true` when running on a platform that supports the MLX stack (Apple Silicon + macOS 14+).
    var isMLXSupported: Bool {
        #if canImport(MLXLLM)
        return true
        #else
        return false
        #endif
    }

    // MARK: Init

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.selectedProviderKey) ?? ""
        self.selectedProvider = LLMProviderOption(rawValue: saved) ?? .mlx
        // Defer refreshAPIKeyStatus() to after init so self is fully initialised.
    }

    // MARK: Lifecycle

    /// Called by the view when it appears.  Refreshes Keychain-derived state.
    func onAppear() {
        refreshAPIKeyStatus()
    }

    // MARK: API Key Management

    /// Saves the trimmed contents of `apiKeyInput` to the Keychain for the current provider.
    ///
    /// No-ops when the provider does not require an API key or the field is blank.
    func saveAPIKey() {
        guard let keychainKey = selectedProvider.keychainKey else { return }
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveError = nil
        do {
            try KeychainHelper.save(key: keychainKey, value: trimmed)
            hasAPIKey = true
            apiKeyInput = ""
            testConnectionState = .idle
        } catch {
            saveError = error.localizedDescription
        }
    }

    /// Removes the stored API key from the Keychain for the current provider.
    func clearAPIKey() {
        guard let keychainKey = selectedProvider.keychainKey else { return }
        saveError = nil
        do {
            try KeychainHelper.delete(key: keychainKey)
            hasAPIKey = false
            testConnectionState = .idle
        } catch {
            saveError = error.localizedDescription
            refreshAPIKeyStatus()
        }
    }

    // MARK: Test Connection

    /// Sends a minimal test prompt to the selected provider and updates `testConnectionState`.
    ///
    /// Guards against concurrent invocations.  For providers that are not yet
    /// implemented (Claude, OpenAI stubs) the failure message surfaces the error
    /// description so the user understands the limitation.
    func testConnection() async {
        if case .testing = testConnectionState { return }
        testConnectionState = .testing
        let provider = makeProvider()
        do {
            let result = try await provider.complete(prompt: "Reply with only the word OK.")
            testConnectionState = .success(result.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            testConnectionState = .failure(error.localizedDescription)
        }
    }

    // MARK: Private helpers

    /// Cached provider instances keyed by `LLMProviderOption`.
    ///
    /// Lazily populated on first use.  Reusing the same instance is critical for
    /// `MLXProvider`, which is an actor that caches the loaded model container —
    /// returning a fresh instance on every call would defeat that caching and cause
    /// repeated model loads each time the user presses "Test".
    private var cachedProviders: [LLMProviderOption: any LLMProvider] = [:]

    /// Returns the cached `LLMProvider` for the current selection, creating it on first access.
    private func makeProvider() -> any LLMProvider {
        if let cached = cachedProviders[selectedProvider] {
            return cached
        }
        let provider: any LLMProvider = switch selectedProvider {
        case .mlx:       MLXProvider()
        case .groq:      GroqProvider()
        case .anthropic: ClaudeProvider()
        case .openai:    OpenAIProvider()
        }
        cachedProviders[selectedProvider] = provider
        return provider
    }

    /// Refreshes `hasAPIKey` by reading the Keychain for the current provider.
    /// Trims the stored value and treats whitespace-only keys as absent, matching
    /// the same validation `GroqProvider` (and future cloud providers) apply in `isAvailable`.
    private func refreshAPIKeyStatus() {
        guard let keychainKey = selectedProvider.keychainKey else {
            hasAPIKey = false
            return
        }
        guard let apiKey = try? KeychainHelper.get(key: keychainKey) else {
            hasAPIKey = false
            return
        }
        hasAPIKey = !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
