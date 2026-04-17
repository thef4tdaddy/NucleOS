//
//  TestHelpers.swift
//  NucleOSTests
//
//  Shared test doubles (stubs and spies) used across multiple test files.
//

import Foundation
@testable import NucleOS

// MARK: - ThrowingMockHealthService

/// A configurable mock HealthServiceProtocol that returns a pre-configured
/// Result from fetchSnapshot(), enabling error path testing.
final class ThrowingMockHealthService: HealthServiceProtocol {
    var snapshotResult: Result<HealthSnapshot, Error>

    init(result: Result<HealthSnapshot, Error>) {
        self.snapshotResult = result
    }

    func requestAuthorization() async throws {}

    func fetchSteps() async throws -> Int {
        return MockData.healthSnapshot.steps
    }

    func fetchHeartRate() async throws -> Double {
        return MockData.healthSnapshot.heartRate
    }

    func fetchSleep() async throws -> TimeInterval {
        return MockData.healthSnapshot.sleepDuration
    }

    func fetchCalories() async throws -> Double {
        return MockData.healthSnapshot.activeCalories
    }

    func fetchSnapshot() async throws -> HealthSnapshot {
        switch snapshotResult {
        case .success(let snapshot):
            return snapshot
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - ThrowingMockAuthService

/// A configurable mock HealthKitAuthorizationServiceProtocol that can be
/// set to throw specific errors from requestAuthorization().
final class ThrowingMockAuthService: HealthKitAuthorizationServiceProtocol, @unchecked Sendable {
    var isHealthDataAvailable: Bool
    var checkStatusResult: HealthKitAuthorizationStatus
    var requestAuthorizationError: Error?
    var requestAuthorizationResult: HealthKitAuthorizationStatus

    init(
        isHealthDataAvailable: Bool = true,
        checkStatusResult: HealthKitAuthorizationStatus = .authorized,
        requestAuthorizationResult: HealthKitAuthorizationStatus = .authorized,
        requestAuthorizationError: Error? = nil
    ) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.checkStatusResult = checkStatusResult
        self.requestAuthorizationResult = requestAuthorizationResult
        self.requestAuthorizationError = requestAuthorizationError
    }

    func checkAuthorizationStatus() async -> HealthKitAuthorizationStatus {
        return checkStatusResult
    }

    func requestAuthorization() async throws -> HealthKitAuthorizationStatus {
        if let error = requestAuthorizationError {
            throw error
        }
        return requestAuthorizationResult
    }
}