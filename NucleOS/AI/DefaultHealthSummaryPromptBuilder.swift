//
//  DefaultHealthSummaryPromptBuilder.swift
//  NucleOS
//
//  Concrete implementation of HealthSummaryPromptBuilder.
//  Formats a HealthSnapshot into a privacy-safe prompt for any LLMProvider.
//

import Foundation

// MARK: - DefaultHealthSummaryPromptBuilder

/// Concrete implementation of ``HealthSummaryPromptBuilder``.
///
/// Formats the aggregate values from ``HealthSnapshot`` into a structured
/// context block, then appends a system instruction that enforces the output
/// framing rules. All privacy rules documented in ``HealthSummaryPromptBuilder``
/// are enforced here — only aggregate metrics appear in the prompt.
///
/// Inject ``MockHealthSummaryPromptBuilder`` in tests and previews.
struct DefaultHealthSummaryPromptBuilder: HealthSummaryPromptBuilder {

    // MARK: HealthSummaryPromptBuilder

    /// Builds a privacy-safe prompt from the given `HealthSnapshot`.
    ///
    /// Only aggregate values from `HealthSnapshot` are included:
    /// steps, stepGoal, heartRate, sleepDuration, sleepGoal, activeCalories,
    /// calorieGoal. No raw HealthKit types, individual sample timestamps, or
    /// clinical data are ever included.
    ///
    /// - Parameter snapshot: Today's aggregate health metrics.
    /// - Returns: A structured prompt string safe to pass to any `LLMProvider`.
    func build(from snapshot: HealthSnapshot) -> String {
        var lines: [String] = []

        // Structured context block — aggregate values only.
        // Raw HKSample data, HRV, SpO₂, and clinical data are never included.
        lines.append("Health data for today (aggregate metrics only):")
        lines.append("- Steps: \(snapshot.steps) of \(snapshot.stepGoal) goal")

        if snapshot.heartRate > 0 {
            lines.append("- Average heart rate: \(Int(snapshot.heartRate)) bpm")
        }

        lines.append("- Sleep: \(snapshot.sleepFormatted) of \(snapshot.sleepGoalFormatted) goal")

        if snapshot.activeCalories > 0 {
            lines.append("- Active calories: \(Int(snapshot.activeCalories)) of \(Int(snapshot.calorieGoal)) goal")
        }

        // System instruction — enforces output framing rules.
        lines.append("")
        lines.append("Using only the health data above, write one brief, friendly observation (one sentence).")
        lines.append("Rules:")
        lines.append("- Observations only. Never give advice or recommendations.")
        lines.append("- Be celebratory when a goal is met (e.g. \"Steps goal hit today 🎉\").")
        lines.append("- Be neutral when a goal is not met (e.g. \"1,766 steps remaining to hit your goal.\").")
        lines.append("- No population comparisons or statistical benchmarks.")
        lines.append("- No trend language that implies medical significance.")
        lines.append("- One sentence only.")

        return lines.joined(separator: "\n")
    }
}
