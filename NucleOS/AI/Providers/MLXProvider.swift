//
//  MLXProvider.swift
//  NucleOS
//
//  On-device LLM provider powered by MLX + Phi-3 mini.
//  Runs fully offline on Apple Silicon. Makes ZERO network calls.
//
//  PRIVACY CONTRACT
//  ================
//  This file must never initiate any network activity under any circumstances.
//  Model weights are loaded exclusively from a user-configured local path stored
//  in UserDefaults. Any reviewers who spot a network call in this file must
//  reject the PR immediately.
//
//  USAGE
//  =====
//  1. User downloads a Phi-3 mini MLX model directory (e.g. from HuggingFace
//     via the CLI — that transfer happens outside the app).
//  2. User sets the path in Settings:
//        UserDefaults.standard.set("/path/to/model", forKey: MLXProvider.modelPathKey)
//  3. Instantiate and use:
//        let provider: any LLMProvider = MLXProvider()
//        let result = try await provider.complete(prompt: "…")
//
//  THREADING
//  =========
//  `MLXProvider` is an actor. The model container is cached in actor-isolated
//  state and reused across calls. `complete(prompt:)` is `nonisolated` per the
//  protocol contract; it hops to the actor to load/reuse the model and then
//  runs MLX inference on the model's own thread via `ModelContainer.perform`.
//

import Foundation

#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
#endif

// MARK: - MLXProvider

/// On-device LLM provider using Apple's MLX framework and Phi-3 mini.
///
/// This is provider #1 in NucleOS's priority order. It makes **zero** network
/// calls and works fully offline on Apple Silicon (M1+, macOS 14+).
///
/// Set the model directory path via UserDefaults before the first call:
/// ```swift
/// UserDefaults.standard.set("/path/to/phi-3-mini", forKey: MLXProvider.modelPathKey)
/// ```
///
/// If the key is absent or the path is empty, `isAvailable` returns `false`
/// and `complete(prompt:)` throws `LLMProviderError.unavailable`.
actor MLXProvider: LLMProvider {

    // MARK: - Constants

    /// UserDefaults key that stores the local model directory path.
    /// Value type: `String` (absolute file path).
    static let modelPathKey = "mlxModelPath"

    // MARK: - Cached state

    #if canImport(MLXLLM)
    /// The loaded model container, kept in memory after the first successful load.
    private var cachedContainer: ModelContainer?
    /// The path used to create `cachedContainer`, used to detect path changes.
    private var cachedModelPath: String?
    #endif

    // MARK: - LLMProvider

    nonisolated var name: String { "MLX · Phi-3 mini" }

    /// `true` when a non-empty model path is configured in UserDefaults
    /// **and** the current platform supports MLX (Apple Silicon, macOS 14+).
    nonisolated var isAvailable: Bool {
        guard let path = UserDefaults.standard.string(forKey: Self.modelPathKey),
              !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        #if canImport(MLXLLM)
        return true
        #else
        return false
        #endif
    }

    /// Sends `prompt` to the on-device Phi-3 mini model and returns its output.
    ///
    /// - Parameter prompt: Plain-text prompt (must not contain raw HealthKit samples).
    /// - Returns: The model's completion string.
    /// - Throws: `LLMProviderError.unavailable` if no model path is configured,
    ///   `LLMProviderError.modelNotFound` if the path does not exist on disk,
    ///   `LLMProviderError.modelLoadFailed` if the model cannot be loaded, or
    ///   `LLMProviderError.inferenceError` if inference itself fails.
    nonisolated func complete(prompt: String) async throws -> String {
        #if canImport(MLXLLM)
        return try await runInference(prompt: prompt)
        #else
        throw LLMProviderError.unavailable
        #endif
    }

    // MARK: - Private inference (Apple Silicon only)

    #if canImport(MLXLLM)

    /// Loads (or reuses) the model container, then runs inference.
    /// Actor-isolated — safe to access `cachedContainer` and `cachedModelPath`.
    private func runInference(prompt: String) async throws -> String {
        let container = try await loadModel()
        do {
            let output = try await container.perform { context in
                let userInput = UserInput(prompt: .text(prompt))
                let lmInput = try await context.processor.prepare(input: userInput)
                let result = try MLXLMCommon.generate(
                    input: lmInput,
                    parameters: GenerateParameters(maxTokens: 512),
                    context: context
                ) { (tokens: [Int]) in
                    let tokenCount = tokens.count
                    return tokenCount < 512 ? .more : .stop
                }
                return result.output
            }
            return output
        } catch let error as LLMProviderError {
            throw error
        } catch {
            throw LLMProviderError.inferenceError(underlying: error)
        }
    }

    /// Returns a cached `ModelContainer` or loads a fresh one from disk.
    ///
    /// Throws `LLMProviderError.modelNotFound` when the path does not exist and
    /// `LLMProviderError.modelLoadFailed` when MLXLLM cannot parse the weights.
    private func loadModel() async throws -> ModelContainer {
        guard let path = UserDefaults.standard.string(forKey: Self.modelPathKey),
              !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMProviderError.unavailable
        }

        // Return the cached container when the path hasn't changed.
        if let cached = cachedContainer, cachedModelPath == path {
            return cached
        }

        // Validate that the directory exists before handing the path to MLXLLM.
        let modelURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: modelURL.path(percentEncoded: false)) else {
            throw LLMProviderError.modelNotFound(path: path)
        }

        let configuration = ModelConfiguration(directory: modelURL)
        do {
            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: configuration
            )
            cachedContainer = container
            cachedModelPath = path
            return container
        } catch {
            throw LLMProviderError.modelLoadFailed(underlying: error)
        }
    }

    #endif
}
