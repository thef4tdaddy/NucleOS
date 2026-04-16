//
//  HealthService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for HealthKit data
//

import Foundation
import HealthKit

// MARK: - Protocol

protocol HealthServiceProtocol {
    /// Requests HealthKit authorization for all metrics used by the dashboard.
    /// Safe to call multiple times — HealthKit only prompts the user once.
    func requestAuthorization() async throws

    func fetchSteps() async throws -> Int
    func fetchHeartRate() async throws -> Double
    func fetchSleep() async throws -> TimeInterval
    func fetchCalories() async throws -> Double

    /// Convenience: fetches all four metrics concurrently and returns a snapshot.
    func fetchSnapshot() async throws -> HealthSnapshot
}

// MARK: - Errors

enum HealthServiceError: LocalizedError {
    /// HealthKit is not available on this device (e.g. macOS without HealthKit entitlement active).
    case unavailable
    /// The user has denied HealthKit access.
    case unauthorized
    /// A query returned no samples when at least one was expected.
    case noData
    /// The underlying HKQuery reported an error.
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "HealthKit is not available on this device."
        case .unauthorized:
            return "HealthKit access has been denied. Please grant access in System Settings → Privacy & Security → Health."
        case .noData:
            return "No health data is available for the requested time range."
        case .queryFailed(let underlying):
            return "Health query failed: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Real Implementation

/// Concrete HealthKit-backed implementation.
///
/// Calling order:
/// 1. `requestAuthorization()` — call once at app launch or before first fetch.
/// 2. Individual `fetch*()` methods — safe to call concurrently via `async let`.
class HealthService: HealthServiceProtocol {

    // MARK: Private state

    private let store = HKHealthStore()

    /// All quantity/category types the dashboard reads.
    private static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps    = HKQuantityType.quantityType(forIdentifier: .stepCount)          { types.insert(steps) }
        if let hr       = HKQuantityType.quantityType(forIdentifier: .heartRate)           { types.insert(hr) }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(calories) }
        if let sleep    = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)         { types.insert(sleep) }
        return types
    }()

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
        } catch {
            throw HealthServiceError.queryFailed(error)
        }
    }

    // MARK: - Steps

    /// Returns the total step count for today (midnight → now).
    func fetchSteps() async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }

        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: .startOfToday,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error))
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    // MARK: - Heart Rate

    /// Returns the most recent heart rate sample from the past 24 hours, in BPM.
    func fetchHeartRate() async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }

        let type = HKQuantityType(.heartRate)
        let (start, end) = Date.last24HoursRange()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error))
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(throwing: HealthServiceError.noData)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep

    /// Returns the total time asleep last night (yesterday 6 PM → today 10 AM), in seconds.
    ///
    /// Only `asleep*` categories are summed; `inBed` samples are excluded so the
    /// result reflects actual sleep rather than time spent in bed.
    func fetchSleep() async throws -> TimeInterval {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }

        let type = HKCategoryType(.sleepAnalysis)
        let (start, end) = Date.lastNightRange()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error))
                    return
                }

                // Include all asleep sub-stages; exclude inBed / awake
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]

                let total = (samples as? [HKCategorySample])?.reduce(0.0) { acc, sample in
                    asleepValues.contains(sample.value)
                        ? acc + sample.endDate.timeIntervalSince(sample.startDate)
                        : acc
                } ?? 0

                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }

    // MARK: - Calories

    /// Returns the total active energy burned today (midnight → now), in kilocalories.
    func fetchCalories() async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }

        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(
            withStart: .startOfToday,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error))
                    return
                }
                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }
    }

    // MARK: - Snapshot

    /// Fetches all four metrics concurrently and returns a single `HealthSnapshot`.
    func fetchSnapshot() async throws -> HealthSnapshot {
        async let steps    = fetchSteps()
        async let hr       = fetchHeartRate()
        async let sleep    = fetchSleep()
        async let calories = fetchCalories()

        return try await HealthSnapshot(
            steps: steps,
            heartRate: hr,
            sleepDuration: sleep,
            activeCalories: calories
        )
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
class MockHealthService: HealthServiceProtocol {

    func requestAuthorization() async throws {
        // No-op for mock — authorization is always considered granted.
    }

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
        return MockData.healthSnapshot
    }
}
