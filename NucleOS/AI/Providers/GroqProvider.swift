//
//  GroqProvider.swift
//  NucleOS
//
//  Cloud LLM provider powered by the Groq inference API.
//  This is provider #2 in NucleOS's priority order (after MLX on-device).
//  Cloud is strictly opt-in — GroqProvider is silent when no API key is present.
//
//  API KEY STORAGE
//  ===============
//  The API key lives exclusively in the system Keychain:
//    account: KeychainHelper.groqAPIKey ("com.nucleos.apikey.groq")
//  It must NEVER be stored in UserDefaults, source code, or any file
//  that could be committed to version control.
//
//  ERROR HANDLING
//  ==============
//  - No Keychain key → throws `LLMProviderError.unavailable`
//  - HTTP 429        → throws `LLMProviderError.rateLimitExceeded`
//  - Network failure → throws `LLMProviderError.networkError(underlying:)`
//  - Bad response    → throws `LLMProviderError.inferenceError(underlying:)`
//

import Foundation

// MARK: - GroqProvider

/// Cloud LLM provider using the Groq inference API (llama3-8b-8192).
///
/// This is provider #2 in NucleOS's priority order. It requires the user to
/// explicitly provide a Groq API key stored in the system Keychain. If the key
/// is absent, `isAvailable` returns `false` and no network activity is initiated.
///
/// **API Key Setup (via Settings UI)**
/// ```swift
/// try KeychainHelper.save(key: KeychainHelper.groqAPIKey, value: "<user's key>")
/// ```
struct GroqProvider: LLMProvider {

    // MARK: - Constants

    /// Default Groq model identifier used for all completions.
    static let defaultModel = "llama3-8b-8192"

    /// Groq OpenAI-compatible completions endpoint URL string.
    private static let apiURLString = "https://api.groq.com/openai/v1/chat/completions"

    /// Maximum tokens to request in each completion.
    private static let maxTokens = 512

    /// Network timeout for each completion request, in seconds.
    private static let timeoutInterval: TimeInterval = 30

    // MARK: - LLMProvider

    nonisolated var name: String { "Groq · \(GroqProvider.defaultModel)" }

    /// `true` when a non-empty Groq API key is present in Keychain.
    ///
    /// Returns `false` silently when the key is absent — no prompt, no crash.
    nonisolated var isAvailable: Bool {
        guard let rawKey = try? KeychainHelper.get(key: KeychainHelper.groqAPIKey),
              let key = rawKey,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }

    /// Sends `prompt` to the Groq completions API and returns the response text.
    ///
    /// - Parameter prompt: Plain-text prompt. Must not contain raw HealthKit samples.
    /// - Returns: The model's completion string.
    /// - Throws: `LLMProviderError.unavailable` when no API key is in Keychain,
    ///   `LLMProviderError.rateLimitExceeded` on HTTP 429,
    ///   `LLMProviderError.networkError` on transport failures,
    ///   `LLMProviderError.inferenceError` on parsing failures.
    nonisolated func complete(prompt: String) async throws -> String {
        let apiKey = try resolvedAPIKey()
        let request = try buildRequest(prompt: prompt, apiKey: apiKey)
        let data = try await executeRequest(request)
        return try parseResponse(data)
    }

    // MARK: - Private helpers

    /// Retrieves the Groq API key from Keychain and validates it is non-empty.
    ///
    /// Any `KeychainError` is mapped to `LLMProviderError.unavailable` so callers
    /// always receive a typed `LLMProviderError`.
    private func resolvedAPIKey() throws -> String {
        let raw: String?
        do {
            raw = try KeychainHelper.get(key: KeychainHelper.groqAPIKey)
        } catch {
            throw LLMProviderError.unavailable
        }
        guard let key = raw else {
            throw LLMProviderError.unavailable
        }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LLMProviderError.unavailable
        }
        return trimmed
    }

    /// Builds a POST request to the Groq completions endpoint.
    private func buildRequest(prompt: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: GroqProvider.apiURLString) else {
            throw LLMProviderError.inferenceError(underlying: URLError(.badURL))
        }
        var request = URLRequest(url: url, timeoutInterval: GroqProvider.timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": GroqProvider.defaultModel,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": GroqProvider.maxTokens
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw LLMProviderError.inferenceError(underlying: error)
        }
        return request
    }

    /// Executes the URL request and validates the HTTP status code.
    private func executeRequest(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMProviderError.networkError(underlying: error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299:
                break
            case 429:
                throw LLMProviderError.rateLimitExceeded
            default:
                throw LLMProviderError.networkError(underlying: URLError(.badServerResponse))
            }
        }

        return data
    }

    /// Decodes the Groq API JSON response and extracts the completion text.
    private func parseResponse(_ data: Data) throws -> String {
        do {
            let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content else {
                throw LLMProviderError.inferenceError(underlying: URLError(.cannotParseResponse))
            }
            return content
        } catch let error as LLMProviderError {
            throw error
        } catch {
            throw LLMProviderError.inferenceError(underlying: error)
        }
    }
}

// MARK: - Private Response Models

private struct GroqResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}
