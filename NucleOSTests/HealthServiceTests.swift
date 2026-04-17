//
//  HealthServiceTests.swift
//  NucleOSTests
//
//  Unit tests for HealthServiceError, HealthPermissionState, and MockHealthService.
//  Real HealthService requires a live HKHealthStore and cannot be unit-tested without
//  HealthKit entitlements; tests focus on the protocol surface and mock implementation.
//

import XCTest
@testable import NucleOS

final class HealthServiceTests: XCTestCase {

    // MARK: - HealthPermissionState Equatable

    func testPermissionStateEquatableNotDetermined() {
        XCTAssertEqual(HealthPermissionState.notDetermined, HealthPermissionState.notDetermined)
    }

    func testPermissionStateEquatableUnavailable() {
        XCTAssertEqual(HealthPermissionState.unavailable, HealthPermissionState.unavailable)
    }

    func testPermissionStateEquatableDenied() {
        XCTAssertEqual(HealthPermissionState.denied, HealthPermissionState.denied)
    }

    func testPermissionStateEquatableEmpty() {
        XCTAssertEqual(HealthPermissionState.empty, HealthPermissionState.empty)
    }

    func testPermissionStateEquatableAuthorized() {
        XCTAssertEqual(HealthPermissionState.authorized, HealthPermissionState.authorized)
    }

    func testPermissionStateNotEqualNotDeterminedVsAuthorized() {
        XCTAssertNotEqual(HealthPermissionState.notDetermined, HealthPermissionState.authorized)
    }

    func testPermissionStateNotEqualEmptyVsDenied() {
        XCTAssertNotEqual(HealthPermissionState.empty, HealthPermissionState.denied)
    }

    func testAllPermissionStateCasesDistinct() {
        let all: [HealthPermissionState] = [.notDetermined, .unavailable, .denied, .empty, .authorized]
        let unique = Set(all.map { "\($0)" })
        XCTAssertEqual(unique.count, 5, "All 5 permission states should be distinct")
    }

    // MARK: - HealthServiceError errorDescription

    func testErrorDescriptionUnavailable() {
        let error = HealthServiceError.unavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("healthkit") ||
                      error.errorDescription!.lowercased().contains("available"))
    }

    func testErrorDescriptionUnauthorized() {
        let error = HealthServiceError.unauthorized
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("denied") ||
                      error.errorDescription!.lowercased().contains("settings"))
    }

    func testErrorDescriptionNoData() {
        let error = HealthServiceError.noData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("no health data") ||
                      error.errorDescription!.lowercased().contains("no") ||
                      error.errorDescription!.lowercased().contains("data"))
    }

    func testErrorDescriptionQueryFailed() {
        let underlying = NSError(domain: "com.test", code: 42, userInfo: [NSLocalizedDescriptionKey: "test failure"])
        let error = HealthServiceError.queryFailed(underlying)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.contains("test failure"))
    }

    func testHealthServiceErrorIsLocalizedError() {
        let error: LocalizedError = HealthServiceError.unavailable
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - HealthServiceError pattern matching

    func testHealthServiceErrorCatchUnavailable() async {
        let service = ThrowingMockHealthService(result: .failure(HealthServiceError.unavailable))
        do {
            _ = try await service.fetchSnapshot()
            XCTFail("Expected error to be thrown")
        } catch HealthServiceError.unavailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHealthServiceErrorCatchUnauthorized() async {
        let service = ThrowingMockHealthService(result: .failure(HealthServiceError.unauthorized))
        do {
            _ = try await service.fetchSnapshot()
            XCTFail("Expected error to be thrown")
        } catch HealthServiceError.unauthorized {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHealthServiceErrorCatchNoData() async {
        let service = ThrowingMockHealthService(result: .failure(HealthServiceError.noData))
        do {
            _ = try await service.fetchSnapshot()
            XCTFail("Expected error to be thrown")
        } catch HealthServiceError.noData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHealthServiceErrorCatchQueryFailed() async {
        let underlying = NSError(domain: "com.test", code: 1)
        let service = ThrowingMockHealthService(result: .failure(HealthServiceError.queryFailed(underlying)))
        do {
            _ = try await service.fetchSnapshot()
            XCTFail("Expected error to be thrown")
        } catch HealthServiceError.queryFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - MockHealthService: requestAuthorization

    func testMockRequestAuthorizationDoesNotThrow() async {
        let service = MockHealthService()
        await XCTAssertNoThrowAsync(try await service.requestAuthorization())
    }

    // MARK: - MockHealthService: fetchSteps

    func testMockFetchStepsReturnsMockDataValue() async throws {
        let service = MockHealthService()
        let steps = try await service.fetchSteps()
        XCTAssertEqual(steps, MockData.healthSnapshot.steps)
    }

    func testMockFetchStepsIsPositive() async throws {
        let service = MockHealthService()
        let steps = try await service.fetchSteps()
        XCTAssertGreaterThan(steps, 0)
    }

    // MARK: - MockHealthService: fetchHeartRate

    func testMockFetchHeartRateReturnsMockDataValue() async throws {
        let service = MockHealthService()
        let hr = try await service.fetchHeartRate()
        XCTAssertEqual(hr, MockData.healthSnapshot.heartRate, accuracy: 0.001)
    }

    func testMockFetchHeartRateIsPositive() async throws {
        let service = MockHealthService()
        let hr = try await service.fetchHeartRate()
        XCTAssertGreaterThan(hr, 0)
    }

    // MARK: - MockHealthService: fetchSleep

    func testMockFetchSleepReturnsMockDataValue() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        XCTAssertEqual(sleep, MockData.healthSnapshot.sleepDuration, accuracy: 1.0)
    }

    func testMockFetchSleepIsPositive() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        XCTAssertGreaterThan(sleep, 0)
    }

    // MARK: - MockHealthService: fetchCalories

    func testMockFetchCaloriesReturnsMockDataValue() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        XCTAssertEqual(calories, MockData.healthSnapshot.activeCalories, accuracy: 0.001)
    }

    func testMockFetchCaloriesIsPositive() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        XCTAssertGreaterThan(calories, 0)
    }

    // MARK: - MockHealthService: fetchSnapshot

    func testMockFetchSnapshotReturnsMockData() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        XCTAssertEqual(snapshot.steps, MockData.healthSnapshot.steps)
        XCTAssertEqual(snapshot.heartRate, MockData.healthSnapshot.heartRate, accuracy: 0.001)
        XCTAssertEqual(snapshot.sleepDuration, MockData.healthSnapshot.sleepDuration, accuracy: 1.0)
        XCTAssertEqual(snapshot.activeCalories, MockData.healthSnapshot.activeCalories, accuracy: 0.001)
    }

    func testMockFetchSnapshotIsConsistentWithIndividualFetches() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        let steps = try await service.fetchSteps()
        let hr = try await service.fetchHeartRate()
        let sleep = try await service.fetchSleep()
        let calories = try await service.fetchCalories()

        XCTAssertEqual(snapshot.steps, steps)
        XCTAssertEqual(snapshot.heartRate, hr, accuracy: 0.001)
        XCTAssertEqual(snapshot.sleepDuration, sleep, accuracy: 1.0)
        XCTAssertEqual(snapshot.activeCalories, calories, accuracy: 0.001)
    }

    func testFetchHeartRateIsPhysiologicallyReasonable() async throws {
        let service = MockHealthService()
        let heartRate = try await service.fetchHeartRate()
        XCTAssertGreaterThanOrEqual(heartRate, 40.0)
        XCTAssertLessThanOrEqual(heartRate, 200.0)
    }

    func testFetchCaloriesIsPositive() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        XCTAssertGreaterThan(calories, 0.0)
    }

    // MARK: - Protocol conformance


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

    // MARK: - MockData consistency

    func testMockDataHealthSnapshotStepsMatchesExpected() {
        XCTAssertEqual(MockData.healthSnapshot.steps, 8_234)
    }

    func testMockDataHealthSnapshotHeartRateMatchesExpected() {
        XCTAssertEqual(MockData.healthSnapshot.heartRate, 72.0, accuracy: 0.001)
    }

    func testMockDataHealthSnapshotSleepGoalIs8Hours() {
        XCTAssertEqual(MockData.healthSnapshot.sleepGoal, 8 * 3600, accuracy: 1.0)
    }

    func testMockDataHealthSnapshotCalorieGoalMatchesExpected() {
        XCTAssertEqual(MockData.healthSnapshot.calorieGoal, 2_200, accuracy: 0.001)
    }

    func testMockDataHealthSnapshotStepGoalMatchesExpected() {
        XCTAssertEqual(MockData.healthSnapshot.stepGoal, 10_000)
    }
}

// MARK: - XCTest async helper

extension XCTestCase {
    func XCTAssertNoThrowAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
        } catch {
            XCTFail("Expected no error but got: \(error). \(message)", file: file, line: line)
        }
    }
}