//
//  HealthSnapshot.swift
//  NucleOS
//
//  Data model representing a point-in-time snapshot of health metrics
//
//  AI PRIVACY BOUNDARY
//  ===================
//  `HealthSnapshot` is the single, well-defined boundary between HealthKit data and
//  every other system in NucleOS — including the AI layer.
//
//  Rules that MUST be enforced at this boundary:
//  • Only aggregate metrics cross this boundary (daily totals and averages).
//    Raw `HKSample`, `HKQuantitySample`, or `HKCategorySample` objects must NEVER
//    be passed to an `LLMProvider` or any other non-HealthKit service.
//  • Heart rate variability (HRV), blood oxygen (SpO₂), and any clinical/diagnostic
//    data are explicitly excluded from this struct and must never be added to it for
//    use in AI prompts.
//  • No population comparison data (e.g. "low for your age group") may be derived
//    from this struct and included in AI context.
//  • User must have explicitly opted in before a `HealthSnapshot` value is passed
//    to any `LLMProvider` implementation (see `HealthSummaryPromptBuilder`).
//  • On-device AI (MLX + Phi-3 mini) is preferred; a user-provided API key is
//    required before any cloud provider receives a snapshot.
//

import Foundation

struct HealthSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    var steps: Int
    var stepGoal: Int
    var heartRate: Double
    var sleepDuration: TimeInterval
    var sleepGoal: TimeInterval
    var activeCalories: Double
    var calorieGoal: Double
    var date: Date

    /// Progress towards the step goal, clamped to [0, 1].
    var stepsProgress: Double {
        guard stepGoal > 0 else { return 0 }
        let progress = Double(steps) / Double(stepGoal)
        return max(0.0, min(progress, 1.0))
    }

    /// Progress towards the sleep goal, clamped to [0, 1].
    var sleepProgress: Double {
        guard sleepGoal > 0 else { return 0 }
        let progress = sleepDuration / sleepGoal
        return max(0.0, min(progress, 1.0))
    }

    /// Progress towards the calorie goal, clamped to [0, 1].
    var caloriesProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        let progress = activeCalories / calorieGoal
        return max(0.0, min(progress, 1.0))
    }

    /// Sleep duration formatted as a human-readable string (e.g. "7h 23m").
    var sleepFormatted: String {
        let totalMinutes = Int(sleepDuration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    /// Sleep goal formatted as a human-readable string (e.g. "8h" or "7h 30m").
    var sleepGoalFormatted: String {
        let totalMinutes = Int(sleepGoal / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    init(
        id: UUID = UUID(),
        steps: Int,
        stepGoal: Int = 10_000,
        heartRate: Double,
        sleepDuration: TimeInterval,
        sleepGoal: TimeInterval = 8 * 3600,
        activeCalories: Double,
        calorieGoal: Double = 2_200,
        date: Date = Date()
    ) {
        self.id = id
        self.steps = steps
        self.stepGoal = stepGoal
        self.heartRate = heartRate
        self.sleepDuration = sleepDuration
        self.sleepGoal = sleepGoal
        self.activeCalories = activeCalories
        self.calorieGoal = calorieGoal
        self.date = date
    }
}
