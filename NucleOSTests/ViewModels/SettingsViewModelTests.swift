//
//  SettingsViewModelTests.swift
//  NucleOSTests/ViewModels
//
//  Swift Testing suite for SettingsViewModel — no real Keychain or network calls.
//  All tests run on @MainActor to match SettingsViewModel's isolation.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Settings ViewModel")
@MainActor
struct SettingsViewModelTests {

    // MARK: - Helpers

    /// Removes the selected-provider UserDefaults key so each test starts clean.
    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: SettingsViewModel.selectedProviderKey)
    }

    // MARK: - Initial state

    @Test("Initial selectedProvider defaults to .mlx when no UserDefaults value is set")
    func initialProviderDefaultsToMLX() {
        clearDefaults()
        let vm = SettingsViewModel()
        #expect(vm.selectedProvider == .mlx)
    }

    @Test("Initial selectedProvider reflects stored UserDefaults value")
    func initialProviderReflectsStoredValue() {
        UserDefaults.standard.set(LLMProviderOption.groq.rawValue, forKey: SettingsViewModel.selectedProviderKey)
        defer { clearDefaults() }
        let vm = SettingsViewModel()
        #expect(vm.selectedProvider == .groq)
    }

    @Test("Initial apiKeyInput is empty")
    func initialAPIKeyInputIsEmpty() {
        clearDefaults()
        let vm = SettingsViewModel()
        #expect(vm.apiKeyInput.isEmpty)
    }

    @Test("Initial testConnectionState is .idle")
    func initialTestConnectionStateIsIdle() {
        clearDefaults()
        let vm = SettingsViewModel()
        if case .idle = vm.testConnectionState {
            // Expected
        } else {
            Issue.record("Expected .idle, got \(vm.testConnectionState)")
        }
    }

    // MARK: - Provider selection persistence

    @Test("Changing selectedProvider persists to UserDefaults")
    func changingProviderPersistsToUserDefaults() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .groq
        let stored = UserDefaults.standard.string(forKey: SettingsViewModel.selectedProviderKey)
        #expect(stored == LLMProviderOption.groq.rawValue)
        clearDefaults()
    }

    @Test("Changing selectedProvider resets apiKeyInput")
    func changingProviderResetsAPIKeyInput() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.apiKeyInput = "some-key"
        vm.selectedProvider = .groq
        #expect(vm.apiKeyInput.isEmpty)
        clearDefaults()
    }

    @Test("Changing selectedProvider resets testConnectionState to idle")
    func changingProviderResetsTestConnectionState() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .anthropic
        if case .idle = vm.testConnectionState {
            // Expected
        } else {
            Issue.record("Expected .idle after provider change")
        }
        clearDefaults()
    }

    // MARK: - LLMProviderOption metadata

    @Test("MLX provider does not require an API key")
    func mlxDoesNotRequireAPIKey() {
        #expect(!LLMProviderOption.mlx.requiresAPIKey)
    }

    @Test("Cloud providers require an API key")
    func cloudProvidersRequireAPIKey() {
        #expect(LLMProviderOption.groq.requiresAPIKey)
        #expect(LLMProviderOption.anthropic.requiresAPIKey)
        #expect(LLMProviderOption.openai.requiresAPIKey)
    }

    @Test("MLX keychainKey is nil")
    func mlxKeychainKeyIsNil() {
        #expect(LLMProviderOption.mlx.keychainKey == nil)
    }

    @Test("Groq keychainKey matches KeychainHelper constant")
    func groqKeychainKeyMatchesConstant() {
        #expect(LLMProviderOption.groq.keychainKey == KeychainHelper.groqAPIKey)
    }

    @Test("Anthropic keychainKey matches KeychainHelper constant")
    func anthropicKeychainKeyMatchesConstant() {
        #expect(LLMProviderOption.anthropic.keychainKey == KeychainHelper.anthropicAPIKey)
    }

    @Test("OpenAI keychainKey matches KeychainHelper constant")
    func openAIKeychainKeyMatchesConstant() {
        #expect(LLMProviderOption.openai.keychainKey == KeychainHelper.openAIAPIKey)
    }

    // MARK: - saveAPIKey no-op paths

    @Test("saveAPIKey no-ops when provider does not require a key (MLX)")
    func saveAPIKeyNoOpsForMLX() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .mlx
        vm.apiKeyInput = "should-be-ignored"
        vm.saveAPIKey()
        // hasAPIKey should remain false — MLX has no keychainKey
        #expect(!vm.hasAPIKey)
    }

    @Test("saveAPIKey no-ops when apiKeyInput is blank")
    func saveAPIKeyNoOpsForBlankInput() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .groq
        vm.apiKeyInput = "   "
        let wasBefore = vm.hasAPIKey
        vm.saveAPIKey()
        #expect(vm.hasAPIKey == wasBefore)
    }

    // MARK: - clearAPIKey

    @Test("clearAPIKey sets hasAPIKey to false")
    func clearAPIKeySetsHasAPIKeyFalse() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .groq
        vm.clearAPIKey()
        #expect(!vm.hasAPIKey)
    }

    @Test("clearAPIKey resets testConnectionState to idle")
    func clearAPIKeyResetsTestState() {
        clearDefaults()
        let vm = SettingsViewModel()
        vm.selectedProvider = .groq
        vm.clearAPIKey()
        if case .idle = vm.testConnectionState {
            // Expected
        } else {
            Issue.record("Expected .idle after clearAPIKey")
        }
    }

    // MARK: - selectedProviderKey constant

    @Test("SettingsViewModel.selectedProviderKey matches AIBriefingService.selectedProviderKey")
    func selectedProviderKeyMatchesAIBriefingService() {
        #expect(SettingsViewModel.selectedProviderKey == AIBriefingService.selectedProviderKey)
    }

    // MARK: - All cases have non-empty display names and descriptions

    @Test("All LLMProviderOption cases have non-empty displayName")
    func allCasesHaveNonEmptyDisplayName() {
        for option in LLMProviderOption.allCases {
            #expect(!option.displayName.isEmpty, "displayName empty for \(option.rawValue)")
        }
    }

    @Test("All LLMProviderOption cases have non-empty providerDescription")
    func allCasesHaveNonEmptyDescription() {
        for option in LLMProviderOption.allCases {
            #expect(!option.providerDescription.isEmpty, "description empty for \(option.rawValue)")
        }
    }
}
