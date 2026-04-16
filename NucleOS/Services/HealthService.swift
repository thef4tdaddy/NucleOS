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

        // Query each metric independently so a partial failure can be surfaced
        // or given a default value without blocking the whole snapshot.
        async let steps = querySteps()
        async let heartRate = queryHeartRate()
        async let sleepDuration = querySleep()
        async let activeCalories = queryCalories()

        // Map raw HealthKit values → HealthSnapshot (the app-facing model).
        // Individual metrics that fail to load fall back to 0 so that a single
        // unavailable data type (e.g. no heart-rate permission) doesn't block
        // the rest of the snapshot. The dashboard checks for 0 values to show
        // appropriate "—" placeholders instead of incorrect zeros.
        return HealthSnapshot(
            steps: (try? await steps) ?? 0,
            heartRate: (try? await heartRate) ?? 0,
            sleepDuration: (try? await sleepDuration) ?? 0,
            activeCalories: (try? await activeCalories) ?? 0
        )
    }

    // MARK: Private — Per-metric HealthKit queries

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
