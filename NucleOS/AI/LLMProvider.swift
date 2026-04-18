//
//  LLMProvider.swift
//  NucleOS
//
//  Foundational protocol for all LLM backends (MLX, Groq, Claude, OpenAI).
//  All provider implementations live in separate files and conform to this protocol.
//
//  ACTOR ISOLATION
//  ===============
//  `LLMProvider` requirements are explicitly `nonisolated` so they do not inherit
//  the project's default `@MainActor` isolation. Individual conforming types
//  should apply `@MainActor` when they update UI state directly, or use
//  `await MainActor.run { … }` at the call site. Callers that update UI with
//  the result must hop back to `@MainActor` themselves. If work should start
//  away from the current actor, prefer `Task.detached { … }` over `Task { … }`.
//
//  No UI code belongs in this file or in any conforming implementation file.
//

import Foundation

// MARK: - LLMProvider

/// Abstraction over every AI backend that NucleOS can use.
///
/// Conforming types represent a single, swappable AI provider.  The rest of the
/// app only ever holds a reference to an `any LLMProvider`  — it never knows
/// which concrete backend is active.
///
/// **Minimal conformance**
/// ```swift
/// struct MyProvider: LLMProvider {
///     let name = "My Provider"
///     var isAvailable: Bool { true }
///
///     func complete(prompt: String) async throws -> String {
///         // call backend, return completion
///     }
/// }
/// ```
///
/// **Actor isolation:** All `LLMProvider` requirements are `nonisolated`, so
/// `complete(prompt:)` executes on whatever actor the caller is already on.
/// If the caller is `@MainActor`, the work begins on that actor; prefer
/// starting it from a detached task when you intentionally want background work.
protocol LLMProvider {

    // MARK: Metadata

    /// Human-readable display name shown in the Settings UI (e.g. "MLX · Phi-3 mini").
    nonisolated var name: String { get }

    /// `true` when the provider is ready to fulfil requests.
    ///
    /// Returns `false` when:
    /// - A required API key has not been entered by the user.
    /// - The on-device model has not finished loading.
    /// - The provider has been disabled in Settings.
    nonisolated var isAvailable: Bool { get }

    // MARK: Completion

    /// Sends `prompt` to the backend and returns the completed text.
    ///
    /// - Parameter prompt: The plain-text prompt to send.  Must not contain raw
    ///   `HKSample` data — use `HealthSummaryPromptBuilder` to produce safe prompts.
    /// - Returns: The provider's completion string.
    /// - Throws: Any error that prevents the provider from returning a completion
    ///   (e.g. network error, API key invalid, model not loaded).
    nonisolated func complete(prompt: String) async throws -> String
}
