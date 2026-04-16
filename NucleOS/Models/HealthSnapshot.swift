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
        return min(Double(steps) / Double(stepGoal), 1.0)
    }

    /// Progress towards the sleep goal, clamped to [0, 1].
    var sleepProgress: Double {
        guard sleepGoal > 0 else { return 0 }
        return min(sleepDuration / sleepGoal, 1.0)
    }

    /// Progress towards the calorie goal, clamped to [0, 1].
    var caloriesProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(activeCalories / calorieGoal, 1.0)
    }

    /// Sleep duration formatted as a human-readable string (e.g. "7h 23m").
    var sleepFormatted: String {
        let totalMinutes = Int(sleepDuration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    /// Sleep goal formatted as a human-readable string (e.g. "8h").
    var sleepGoalFormatted: String {
        let hours = Int(sleepGoal / 3600)
        return "\(hours)h"
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
