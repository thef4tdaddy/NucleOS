//
//  HealthSnapshotTests.swift
//  NucleOSTests
//
//  Unit tests for HealthSnapshot computed properties and formatting.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Health Snapshot")
struct HealthSnapshotTests {

    // MARK: - stepsProgress

    @Test("stepsProgress is 0.5 at half goal")
    func stepsProgressPartialProgress() {
        let snapshot = HealthSnapshot(steps: 5_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(abs(snapshot.stepsProgress - 0.5) <= 0.0001)
    }

    @Test("stepsProgress is 1.0 when goal met")
    func stepsProgressGoalMet() {
        let snapshot = HealthSnapshot(steps: 10_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(abs(snapshot.stepsProgress - 1.0) <= 0.0001)
    }

    @Test("stepsProgress is clamped to 1.0 when exceeding goal")
    func stepsProgressExceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 15_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(abs(snapshot.stepsProgress - 1.0) <= 0.0001)
    }

    @Test("stepsProgress is 0.0 when goal is zero")
    func stepsProgressZeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 5_000, stepGoal: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.stepsProgress == 0.0)
    }

    @Test("stepsProgress is 0.0 when steps are zero")
    func stepsProgressZeroSteps() {
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.stepsProgress == 0.0)
    }

    @Test("stepsProgress is just under 1.0 one step below goal")
    func stepsProgressOneStepBelowGoal() {
        let snapshot = HealthSnapshot(steps: 9_999, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.stepsProgress < 1.0)
        #expect(snapshot.stepsProgress > 0.999)
    }

    // MARK: - sleepProgress

    @Test("sleepProgress is 0.5 at half goal")
    func sleepProgressPartialProgress() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 4 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        #expect(abs(snapshot.sleepProgress - 0.5) <= 0.0001)
    }

    @Test("sleepProgress is 1.0 when goal met")
    func sleepProgressGoalMet() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 8 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        #expect(abs(snapshot.sleepProgress - 1.0) <= 0.0001)
    }

    @Test("sleepProgress is clamped to 1.0 when exceeding goal")
    func sleepProgressExceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 10 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        #expect(abs(snapshot.sleepProgress - 1.0) <= 0.0001)
    }

    @Test("sleepProgress is 0.0 when goal is zero")
    func sleepProgressZeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 7 * 3600, sleepGoal: 0, activeCalories: 0)
        #expect(snapshot.sleepProgress == 0.0)
    }

    @Test("sleepProgress is 0.0 when sleep is zero")
    func sleepProgressZeroSleep() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 8 * 3600, activeCalories: 0)
        #expect(snapshot.sleepProgress == 0.0)
    }

    // MARK: - caloriesProgress

    @Test("caloriesProgress is 0.5 at half goal")
    func caloriesProgressPartialProgress() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 1_100, calorieGoal: 2_200)
        #expect(abs(snapshot.caloriesProgress - 0.5) <= 0.0001)
    }

    @Test("caloriesProgress is 1.0 when goal met")
    func caloriesProgressGoalMet() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 2_200, calorieGoal: 2_200)
        #expect(abs(snapshot.caloriesProgress - 1.0) <= 0.0001)
    }

    @Test("caloriesProgress is clamped to 1.0 when exceeding goal")
    func caloriesProgressExceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 3_000, calorieGoal: 2_200)
        #expect(abs(snapshot.caloriesProgress - 1.0) <= 0.0001)
    }

    @Test("caloriesProgress is 0.0 when goal is zero")
    func caloriesProgressZeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 500, calorieGoal: 0)
        #expect(snapshot.caloriesProgress == 0.0)
    }

    @Test("caloriesProgress is 0.0 when calories are zero")
    func caloriesProgressZeroCalories() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0, calorieGoal: 2_200)
        #expect(snapshot.caloriesProgress == 0.0)
    }

    // MARK: - sleepFormatted

    @Test("sleepFormatted shows hours and minutes")
    func sleepFormattedHoursAndMinutes() {
        let sleepSeconds = TimeInterval((7 * 60 + 23) * 60)
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: sleepSeconds, activeCalories: 0)
        #expect(snapshot.sleepFormatted == "7h 23m")
    }

    @Test("sleepFormatted shows exact hours with 0 minutes")
    func sleepFormattedExactHours() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 8 * 3600, activeCalories: 0)
        #expect(snapshot.sleepFormatted == "8h 0m")
    }

    @Test("sleepFormatted is 0h 0m when sleep is zero")
    func sleepFormattedZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.sleepFormatted == "0h 0m")
    }

    @Test("sleepFormatted shows 0h for sub-hour sleep")
    func sleepFormattedLessOneHour() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 45 * 60, activeCalories: 0)
        #expect(snapshot.sleepFormatted == "0h 45m")
    }

    @Test("sleepFormatted shows 1 minute correctly")
    func sleepFormattedOneMinute() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 60, activeCalories: 0)
        #expect(snapshot.sleepFormatted == "0h 1m")
    }

    // MARK: - sleepGoalFormatted

    @Test("sleepGoalFormatted shows exact hours")
    func sleepGoalFormattedExactHours() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 8 * 3600, activeCalories: 0)
        #expect(snapshot.sleepGoalFormatted == "8h")
    }

    @Test("sleepGoalFormatted shows hours and minutes")
    func sleepGoalFormattedHoursAndMinutes() {
        let goal = TimeInterval((7 * 60 + 30) * 60)
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: goal, activeCalories: 0)
        #expect(snapshot.sleepGoalFormatted == "7h 30m")
    }

    @Test("sleepGoalFormatted is 0h when goal is zero")
    func sleepGoalFormattedZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 0, activeCalories: 0)
        #expect(snapshot.sleepGoalFormatted == "0h")
    }

    @Test("sleepGoalFormatted shows minutes-only goal")
    func sleepGoalFormattedMinutesOnly() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 30 * 60, activeCalories: 0)
        #expect(snapshot.sleepGoalFormatted == "0h 30m")
    }

    // MARK: - Default Goal Values

    @Test("default stepGoal is 10000")
    func defaultStepGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.stepGoal == 10_000)
    }

    @Test("default sleepGoal is 8 hours")
    func defaultSleepGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.sleepGoal == 8 * 3600)
    }

    @Test("default calorieGoal is 2200")
    func defaultCalorieGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(snapshot.calorieGoal == 2_200)
    }

    // MARK: - Identifiable / Hashable

    @Test("two snapshots have unique IDs")
    func identifiableUniqueness() {
        let s1 = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        let s2 = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        #expect(s1.id != s2.id)
    }

    @Test("snapshots with same ID are equal")
    func hashableWithSameIdEquals() {
        let id = UUID()
        let date = Date()
        let s1 = HealthSnapshot(id: id, steps: 100, heartRate: 72, sleepDuration: 0, activeCalories: 0, date: date)
        let s2 = HealthSnapshot(id: id, steps: 100, heartRate: 72, sleepDuration: 0, activeCalories: 0, date: date)
        #expect(s1 == s2)
        #expect(s1.hashValue == s2.hashValue)
    }

    // MARK: - MockData snapshot consistency

    @Test("MockData snapshot progress values are correct")
    func mockDataSnapshotProgressValues() {
        let snapshot = MockData.healthSnapshot
        #expect(abs(snapshot.stepsProgress - 0.8234) <= 0.0001)
        #expect(abs(snapshot.sleepProgress - 0.9229) <= 0.001)
        #expect(abs(snapshot.caloriesProgress - 0.8395) <= 0.001)
    }

    @Test("MockData snapshot formats sleep correctly")
    func mockDataSnapshotFormatting() {
        let snapshot = MockData.healthSnapshot
        #expect(snapshot.sleepFormatted == "7h 23m")
        #expect(snapshot.sleepGoalFormatted == "8h")
    }

    // MARK: - Boundary values

    @Test("all progress properties are at least 0.0")
    func allProgressPropertiesClampedAboveZero() {
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 1, heartRate: 0, sleepDuration: 0, sleepGoal: 1, activeCalories: 0, calorieGoal: 1)
        #expect(snapshot.stepsProgress >= 0.0)
        #expect(snapshot.sleepProgress >= 0.0)
        #expect(snapshot.caloriesProgress >= 0.0)
    }

    @Test("all progress properties are at most 1.0")
    func allProgressPropertiesClampedBelowOne() {
        let snapshot = HealthSnapshot(steps: 999_999, stepGoal: 1, heartRate: 0, sleepDuration: 999_999, sleepGoal: 1, activeCalories: 999_999, calorieGoal: 1)
        #expect(snapshot.stepsProgress <= 1.0)
        #expect(snapshot.sleepProgress <= 1.0)
        #expect(snapshot.caloriesProgress <= 1.0)
    }
}
