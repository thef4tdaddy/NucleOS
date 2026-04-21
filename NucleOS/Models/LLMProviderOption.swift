//
//  LLMProviderOption.swift
//  NucleOS
//
//  Enumeration of all LLM provider choices available in Settings.
//  Provider selection is stored in UserDefaults (non-sensitive).
//  API keys are stored separately in the Keychain via KeychainHelper.
//

import Foundation

// MARK: - LLMProviderOption

/// The set of LLM backends the user can select in Settings.
///
/// Each case maps to a concrete `LLMProvider` implementation and carries
/// the metadata (display name, description, Keychain key) needed by the
/// Settings UI and by `AIBriefingService` when routing completions.
enum LLMProviderOption: String, CaseIterable, Identifiable {

    /// On-device MLX + Phi-3 mini.  No network.  Apple Silicon only.
    case mlx = "mlx"

    /// Groq cloud inference API.  Free tier.  Requires API key.
    case groq = "groq"

    /// Anthropic Claude.  Premium cloud.  Requires API key.
    case anthropic = "anthropic"

    /// OpenAI GPT models.  Requires API key.
    case openai = "openai"

    // MARK: Identifiable

    var id: String { rawValue }

    // MARK: Display

    /// Human-readable name shown in the provider picker.
    var displayName: String {
        switch self {
        case .mlx:       return "On-device (MLX)"
        case .groq:      return "Groq"
        case .anthropic: return "Anthropic (Claude)"
        case .openai:    return "OpenAI"
        }
    }

    /// One-line description shown beneath the picker.
    var providerDescription: String {
        switch self {
        case .mlx:
            return "Private, on-device AI. No internet required. Requires Apple Silicon."
        case .groq:
            return "Free cloud AI. Fast responses. Get a free API key at groq.com"
        case .anthropic:
            return "Claude AI. Premium quality. Use your existing Claude subscription API key."
        case .openai:
            return "GPT models. Use your existing OpenAI API key."
        }
    }

    // MARK: API Key

    /// `true` when this provider requires a user-supplied API key.
    var requiresAPIKey: Bool {
        switch self {
        case .mlx:                  return false
        case .groq, .anthropic, .openai: return true
        }
    }

    /// The Keychain account key used to store/retrieve this provider's API key,
    /// or `nil` for providers that do not use an API key.
    var keychainKey: String? {
        switch self {
        case .mlx:       return nil
        case .groq:      return KeychainHelper.groqAPIKey
        case .anthropic: return KeychainHelper.anthropicAPIKey
        case .openai:    return KeychainHelper.openAIAPIKey
        }
    }
}
