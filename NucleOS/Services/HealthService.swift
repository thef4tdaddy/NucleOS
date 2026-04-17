//
//  HealthService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for HealthKit data
//

import Foundation

// MARK: - Protocol

/// Service interface for health data. All consumers receive the app-facing
/// `HealthSnapshot` model — raw HealthKit types never cross this boundary.
protocol HealthServiceProtocol {
    /// Fetches today's health metrics and returns them as a single app-facing snapshot.
    func fetchSnapshot() async throws -> HealthSnapshot
}

// MARK: - Errors

enum HealthServiceError: LocalizedError {
    case notImplemented
    /// Thrown from `fetchSnapshot()` when `HKHealthStore.isHealthDataAvailable()` returns false.
    case unavailable

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "HealthService is not implemented yet. HealthKit integration is still pending."
        case .unavailable:
            return "HealthKit is not available on this device."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with HealthKit.
/// Each private method queries a single HealthKit metric; `fetchSnapshot()`
/// assembles the results into the app-facing `HealthSnapshot` model.
class HealthService: HealthServiceProtocol {

    // MARK: Public — Protocol

    func fetchSnapshot() async throws -> HealthSnapshot {
        // TODO: Uncomment once HealthKit is imported:
        // guard HKHealthStore.isHealthDataAvailable() else { throw HealthServiceError.unavailable }

        // Kick off all four queries concurrently.
        async let stepsTask = querySteps()
        async let heartRateTask = queryHeartRate()
        async let sleepDurationTask = querySleep()
        async let activeCaloriesTask = queryCalories()

        var steps = 0
        var heartRate = 0.0
        var sleepDuration: TimeInterval = 0
        var activeCalories = 0.0

        var firstRecoverableError: Error?
        var failedMetricCount = 0

        do {
            steps = try await stepsTask
        } catch {
            if shouldRethrowMetricError(error) { throw error }
            failedMetricCount += 1
            firstRecoverableError = firstRecoverableError ?? error
        }

        do {
            heartRate = try await heartRateTask
        } catch {
            if shouldRethrowMetricError(error) { throw error }
            failedMetricCount += 1
            firstRecoverableError = firstRecoverableError ?? error
        }

        do {
            sleepDuration = try await sleepDurationTask
        } catch {
            if shouldRethrowMetricError(error) { throw error }
            failedMetricCount += 1
            firstRecoverableError = firstRecoverableError ?? error
        }

        do {
            activeCalories = try await activeCaloriesTask
        } catch {
            if shouldRethrowMetricError(error) { throw error }
            failedMetricCount += 1
            firstRecoverableError = firstRecoverableError ?? error
        }

        // If every single metric failed with a recoverable error (e.g. all
        // permissions denied) surface the first error rather than returning an
        // all-zero snapshot that is indistinguishable from real data.
        if failedMetricCount == 4, let firstRecoverableError {
            throw firstRecoverableError
        }

        // Map raw HealthKit values → HealthSnapshot (the app-facing model).
        // Individual metrics that fail to load fall back to 0 so that a single
        // unavailable data type (e.g. no heart-rate permission) doesn't block
        // the rest of the snapshot from being returned.
        return HealthSnapshot(
            steps: steps,
            heartRate: heartRate,
            sleepDuration: sleepDuration,
            activeCalories: activeCalories
        )
    }

    // MARK: Private — Per-metric HealthKit queries

    /// Returns `true` for errors that represent a programming mistake or
    /// unrecoverable state and should propagate out of `fetchSnapshot()`.
    /// Returns `false` for expected per-metric failures (e.g. permission
    /// denied for a single data type) where graceful degradation is appropriate.
    private func shouldRethrowMetricError(_ error: Error) -> Bool {
        guard let healthServiceError = error as? HealthServiceError else {
            return false
        }
        switch healthServiceError {
        case .notImplemented:
            return true
        case .unavailable:
            return false
        }
    }

    /// Queries today's step count via `HKQuantityType.stepCount`.
    private func querySteps() async throws -> Int {
        // TODO: Request HealthKit authorization and query HKStatisticsQuery for
        // HKQuantityType(.stepCount) over the current calendar day.
        throw HealthServiceError.notImplemented
    }

    /// Queries the most recent heart-rate sample via `HKQuantityType.heartRate`.
    private func queryHeartRate() async throws -> Double {
        // TODO: Execute HKSampleQuery for HKQuantityType(.heartRate), sorted
        // descending by endDate, limit 1, and convert to BPM.
        throw HealthServiceError.notImplemented
    }

    /// Queries last night's sleep duration via `HKCategoryType.sleepAnalysis`.
    private func querySleep() async throws -> TimeInterval {
        // TODO: Execute HKSampleQuery for HKCategoryType(.sleepAnalysis) covering
        // the previous night window and sum asleep-stage durations.
        throw HealthServiceError.notImplemented
    }

    /// Queries today's active energy burned via `HKQuantityType.activeEnergyBurned`.
    private func queryCalories() async throws -> Double {
        // TODO: Execute HKStatisticsQuery for HKQuantityType(.activeEnergyBurned)
        // over the current calendar day and convert to kilocalories.
        throw HealthServiceError.notImplemented
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
class MockHealthService: HealthServiceProtocol {

    func fetchSnapshot() async throws -> HealthSnapshot {
        return MockData.healthSnapshot
    }
}
