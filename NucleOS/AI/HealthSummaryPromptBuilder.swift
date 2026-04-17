//
//  HealthSummaryPromptBuilder.swift
//  NucleOS
//
//  Protocol stub for building health-context prompts consumed by LLMProvider.
//  Implementation is deferred to milestone 0.4.0.
//
//  OVERVIEW
//  ========
//  `HealthSummaryPromptBuilder` sits between `HealthSnapshot` and any `LLMProvider`.
//  It accepts an aggregate `HealthSnapshot` and produces a plain-text prompt string
//  that any provider can execute.  It is intentionally separate from the provider so
//  that the privacy rules and framing rules below are enforced in one place,
//  regardless of which backend (MLX, Groq, Claude, OpenAI) ultimately processes the
//  prompt.
//
//  PRIVACY RULES  (must be enforced by every conforming type)
//  ===========================================================
//  1. Only the aggregate values already present on `HealthSnapshot` may appear in
//     the prompt — steps, stepGoal, heartRate, sleepDuration, sleepGoal,
//     activeCalories, calorieGoal.  No raw `HKSample` data, timestamps of
//     individual samples, or any HealthKit type not surfaced by `HealthSnapshot`.
//  2. Heart rate variability (HRV), blood oxygen (SpO₂), and all clinical or
//     diagnostic data are permanently excluded from prompts.
//  3. No population-comparison language — prompts must not include phrases such as
//     "for your age", "below average", or "higher than typical".
//  4. No trend language that implies medical significance — avoid "declining",
//     "worsening", "abnormal", or similar terms.
//  5. The caller is responsible for verifying user opt-in before invoking `build`.
//     This type must not be called if the user has not explicitly enabled health
//     context in AI prompts.
//  6. On-device AI (MLX + Phi-3 mini) is strongly preferred for health prompts.
//     A user-provided API key must be present before a cloud-backed `LLMProvider`
//     receives the output of `build`.
//
//  SAFE OUTPUT FRAMING  (must be enforced by every conforming type)
//  =================================================================
//  • Observations only — never advice.
//    ✅ "You got 7h 23m of sleep last night."
//    ❌ "You should try to sleep more."
//  • Celebratory when a goal is met:
//    ✅ "Steps goal hit today 🎉"
//  • Neutral when not met:
//    ✅ "1,766 steps remaining to hit your goal."
//    ❌ "You barely moved today."
//
//  IMPLEMENTATION NOTES  (for milestone 0.4.0)
//  ============================================
//  A concrete `DefaultHealthSummaryPromptBuilder` should:
//  - Format `HealthSnapshot` fields into a structured context block.
//  - Append a system instruction enforcing the framing rules above.
//  - Return a single `String` ready to be passed to `LLMProvider.complete(_:)`.
//  The resulting one-sentence observation is displayed in `AIBriefingPanelView`
//  as a `BriefingBullet` (see AIBriefingComponents.swift).
//

import Foundation

// MARK: - HealthSummaryPromptBuilder

/// Converts an aggregate `HealthSnapshot` into a plain-text prompt for an
/// `LLMProvider`.  Conforming types must enforce all privacy and framing rules
/// documented in this file.  No user-facing health advice may be included in
/// the generated prompt or expected in the provider's response.
///
/// **Usage (milestone 0.4.0+):**
/// ```swift
/// let prompt = builder.build(from: snapshot)
/// do {
///     let summary = try await provider.complete(prompt)
///     // Display `summary` as a BriefingBullet in AIBriefingPanelView
/// } catch {
///     // Fail silently — health summary is non-critical; do not surface errors to the user
/// }
/// ```
protocol HealthSummaryPromptBuilder {

    /// Builds a prompt string from the given `HealthSnapshot`.
    ///
    /// - Parameter snapshot: The aggregate health metrics for the current day.
    ///   Raw HealthKit types must never be passed — use `HealthSnapshot` exclusively.
    /// - Returns: A prompt string safe to send to any `LLMProvider`.
    ///
    /// - Important: The caller must confirm user opt-in before invoking this method.
    func build(from snapshot: HealthSnapshot) -> String
}
