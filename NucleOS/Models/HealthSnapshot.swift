//
//  HealthSnapshot.swift
//  NucleOS
//
//  Data model representing a point-in-time snapshot of health metrics
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
