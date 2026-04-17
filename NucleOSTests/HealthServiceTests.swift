//
//  HealthServiceTests.swift
//  NucleOSTests
//
//  Tests for HealthService changes in this PR:
//  - MockHealthService now returns hardcoded values instead of MockData references
//  - Specific values: steps=8432, heartRate=72.0, sleep=26580s (7h23m), calories=487.0
//

import XCTest
@testable import NucleOS

final class HealthServiceTests: XCTestCase {

    // MARK: - MockHealthService Tests

    func testFetchStepsReturnsExpectedValue() async throws {
        let service = MockHealthService()
        let steps = try await service.fetchSteps()
        XCTAssertEqual(steps, 8_432)
    }

    func testFetchHeartRateReturnsExpectedValue() async throws {
        let service = MockHealthService()
        let heartRate = try await service.fetchHeartRate()
        XCTAssertEqual(heartRate, 72.0, accuracy: 0.01)
    }

    func testFetchSleepReturnsExpectedDuration() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        // 7 hours 23 minutes = (7 * 60 + 23) * 60 = 26580 seconds
        let expected: TimeInterval = (7 * 60 + 23) * 60
        XCTAssertEqual(sleep, expected, accuracy: 1.0)
    }

    func testFetchSleepDurationInHours() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        let hours = sleep / 3600
        // Should be between 7 and 8 hours
        XCTAssertGreaterThanOrEqual(hours, 7.0)
        XCTAssertLessThan(hours, 8.0)
    }

    func testFetchSleepDurationExactSeconds() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        XCTAssertEqual(sleep, 26580, accuracy: 0.001)
    }

    func testFetchCaloriesReturnsExpectedValue() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        XCTAssertEqual(calories, 487.0, accuracy: 0.01)
    }

    func testFetchStepsIsPositive() async throws {
        let service = MockHealthService()
        let steps = try await service.fetchSteps()
        XCTAssertGreaterThan(steps, 0)
    }

    func testFetchHeartRateIsPhysiologicallyReasonable() async throws {
        let service = MockHealthService()
        let heartRate = try await service.fetchHeartRate()
        // Normal resting heart rate: 60-100 bpm
        XCTAssertGreaterThanOrEqual(heartRate, 40.0)
        XCTAssertLessThanOrEqual(heartRate, 200.0)
    }

    func testFetchCaloriesIsPositive() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        XCTAssertGreaterThan(calories, 0.0)
    }

    func testMockHealthServiceConformsToProtocol() {
        let service: HealthServiceProtocol = MockHealthService()
        XCTAssertNotNil(service)
    }

    // MARK: - Multiple calls return consistent values

    func testFetchStepsIsIdempotent() async throws {
        let service = MockHealthService()
        let steps1 = try await service.fetchSteps()
        let steps2 = try await service.fetchSteps()
        XCTAssertEqual(steps1, steps2)
    }

    func testFetchHeartRateIsIdempotent() async throws {
        let service = MockHealthService()
        let rate1 = try await service.fetchHeartRate()
        let rate2 = try await service.fetchHeartRate()
        XCTAssertEqual(rate1, rate2, accuracy: 0.001)
    }

    func testFetchSleepIsIdempotent() async throws {
        let service = MockHealthService()
        let sleep1 = try await service.fetchSleep()
        let sleep2 = try await service.fetchSleep()
        XCTAssertEqual(sleep1, sleep2, accuracy: 0.001)
    }

    func testFetchCaloriesIsIdempotent() async throws {
        let service = MockHealthService()
        let cal1 = try await service.fetchCalories()
        let cal2 = try await service.fetchCalories()
        XCTAssertEqual(cal1, cal2, accuracy: 0.001)
    }

    // MARK: - HealthServiceError Tests

    func testNotImplementedErrorDescription() {
        let error = HealthServiceError.notImplemented
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty == true)
    }

    func testHealthServiceErrorConformsToLocalizedError() {
        let error: LocalizedError = HealthServiceError.notImplemented
        XCTAssertNotNil(error.errorDescription)
    }
}