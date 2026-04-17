//
//  HealthSnapshotTests.swift
//  NucleOSTests
//
//  Unit tests for HealthSnapshot computed properties and formatting.
//

import XCTest
@testable import NucleOS

final class HealthSnapshotTests: XCTestCase {

    // MARK: - stepsProgress

    func testStepsProgress_partialProgress() {
        let snapshot = HealthSnapshot(steps: 5_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepsProgress, 0.5, accuracy: 0.0001)
    }

    func testStepsProgress_goalMet() {
        let snapshot = HealthSnapshot(steps: 10_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepsProgress, 1.0, accuracy: 0.0001)
    }

    func testStepsProgress_exceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 15_000, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepsProgress, 1.0, accuracy: 0.0001)
    }

    func testStepsProgress_zeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 5_000, stepGoal: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepsProgress, 0.0)
    }

    func testStepsProgress_zeroSteps() {
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepsProgress, 0.0)
    }

    func testStepsProgress_oneStepBelowGoal() {
        let snapshot = HealthSnapshot(steps: 9_999, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertLessThan(snapshot.stepsProgress, 1.0)
        XCTAssertGreaterThan(snapshot.stepsProgress, 0.999)
    }

    // MARK: - sleepProgress

    func testSleepProgress_partialProgress() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 4 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepProgress, 0.5, accuracy: 0.0001)
    }

    func testSleepProgress_goalMet() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 8 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepProgress, 1.0, accuracy: 0.0001)
    }

    func testSleepProgress_exceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 10 * 3600, sleepGoal: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepProgress, 1.0, accuracy: 0.0001)
    }

    func testSleepProgress_zeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 7 * 3600, sleepGoal: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepProgress, 0.0)
    }

    func testSleepProgress_zeroSleep() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepProgress, 0.0)
    }

    // MARK: - caloriesProgress

    func testCaloriesProgress_partialProgress() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 1_100, calorieGoal: 2_200)
        XCTAssertEqual(snapshot.caloriesProgress, 0.5, accuracy: 0.0001)
    }

    func testCaloriesProgress_goalMet() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 2_200, calorieGoal: 2_200)
        XCTAssertEqual(snapshot.caloriesProgress, 1.0, accuracy: 0.0001)
    }

    func testCaloriesProgress_exceedsGoalClampedToOne() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 3_000, calorieGoal: 2_200)
        XCTAssertEqual(snapshot.caloriesProgress, 1.0, accuracy: 0.0001)
    }

    func testCaloriesProgress_zeroGoalReturnsZero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 500, calorieGoal: 0)
        XCTAssertEqual(snapshot.caloriesProgress, 0.0)
    }

    func testCaloriesProgress_zeroCalories() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0, calorieGoal: 2_200)
        XCTAssertEqual(snapshot.caloriesProgress, 0.0)
    }

    // MARK: - sleepFormatted

    func testSleepFormatted_hoursAndMinutes() {
        // 7h 23m = (7 * 60 + 23) * 60 seconds
        let sleepSeconds = TimeInterval((7 * 60 + 23) * 60)
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: sleepSeconds, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepFormatted, "7h 23m")
    }

    func testSleepFormatted_exactHours() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepFormatted, "8h 0m")
    }

    func testSleepFormatted_zero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepFormatted, "0h 0m")
    }

    func testSleepFormatted_lessOneHour() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 45 * 60, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepFormatted, "0h 45m")
    }

    func testSleepFormatted_oneMinute() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 60, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepFormatted, "0h 1m")
    }

    // MARK: - sleepGoalFormatted

    func testSleepGoalFormatted_exactHours() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 8 * 3600, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepGoalFormatted, "8h")
    }

    func testSleepGoalFormatted_hoursAndMinutes() {
        let goal = TimeInterval((7 * 60 + 30) * 60)
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: goal, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepGoalFormatted, "7h 30m")
    }

    func testSleepGoalFormatted_zero() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepGoalFormatted, "0h")
    }

    func testSleepGoalFormatted_minutesOnly() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, sleepGoal: 30 * 60, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepGoalFormatted, "0h 30m")
    }

    // MARK: - Default Goal Values

    func testDefaultStepGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.stepGoal, 10_000)
    }

    func testDefaultSleepGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.sleepGoal, 8 * 3600)
    }

    func testDefaultCalorieGoal() {
        let snapshot = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(snapshot.calorieGoal, 2_200)
    }

    // MARK: - Identifiable / Hashable

    func testIdentifiableUniqueness() {
        let s1 = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        let s2 = HealthSnapshot(steps: 0, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertNotEqual(s1.id, s2.id)
    }

    func testHashableWithSameIdEquals() {
        let id = UUID()
        let s1 = HealthSnapshot(id: id, steps: 100, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        let s2 = HealthSnapshot(id: id, steps: 100, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        XCTAssertEqual(s1, s2)
        XCTAssertEqual(s1.hashValue, s2.hashValue)
    }

    // MARK: - MockData snapshot consistency

    func testMockDataSnapshotProgressValues() {
        let snapshot = MockData.healthSnapshot
        // steps 8234 / 10000 = 0.8234
        XCTAssertEqual(snapshot.stepsProgress, 0.8234, accuracy: 0.0001)
        // sleep (7*60+23)*60 / (8*3600) = 26580 / 28800 ≈ 0.92291
        XCTAssertEqual(snapshot.sleepProgress, 0.9229, accuracy: 0.001)
        // calories 1847 / 2200 ≈ 0.83954
        XCTAssertEqual(snapshot.caloriesProgress, 0.8395, accuracy: 0.001)
    }

    func testMockDataSnapshotFormatting() {
        let snapshot = MockData.healthSnapshot
        XCTAssertEqual(snapshot.sleepFormatted, "7h 23m")
        XCTAssertEqual(snapshot.sleepGoalFormatted, "8h")
    }

    // MARK: - Boundary values

    func testAllProgressPropertiesClampedAboveZero() {
        // Negative values are not expected, but test clamp behavior at 0
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 1, heartRate: 0, sleepDuration: 0, sleepGoal: 1, activeCalories: 0, calorieGoal: 1)
        XCTAssertGreaterThanOrEqual(snapshot.stepsProgress, 0.0)
        XCTAssertGreaterThanOrEqual(snapshot.sleepProgress, 0.0)
        XCTAssertGreaterThanOrEqual(snapshot.caloriesProgress, 0.0)
    }

    func testAllProgressPropertiesClampedBelowOne() {
        let snapshot = HealthSnapshot(steps: 999_999, stepGoal: 1, heartRate: 0, sleepDuration: 999_999, sleepGoal: 1, activeCalories: 999_999, calorieGoal: 1)
        XCTAssertLessThanOrEqual(snapshot.stepsProgress, 1.0)
        XCTAssertLessThanOrEqual(snapshot.sleepProgress, 1.0)
        XCTAssertLessThanOrEqual(snapshot.caloriesProgress, 1.0)
    }
}