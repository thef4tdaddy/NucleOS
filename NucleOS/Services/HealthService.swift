//
//  HealthService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for HealthKit data
//

import Foundation

// MARK: - Permission State

/// Represents the possible HealthKit authorization states for the UI.
enum HealthPermissionState: Equatable {
    /// Authorization has not been requested yet.
    case notDetermined
    /// HealthKit is unavailable on this device or OS version.
    case unavailable
    /// The user has denied or restricted access.
    case denied
    /// Access is authorized but no health data exists yet.
    case empty
    /// Access is authorized and data is available.
    case authorized
}

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
#if os(macOS)
            return "HealthKit access has been denied. Please grant access in System Settings → Privacy & Security → Health."
#else
            return "HealthKit access has been denied. Please grant access in Settings → Privacy & Security → Health."
#endif
        case .noData:
            return "No health data is available for the requested time range."
        case .queryFailed(let underlying):
            return "Health query failed: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Real Implementation

#if canImport(HealthKit)
import HealthKit

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
        if let steps     = HKQuantityType.quantityType(forIdentifier: .stepCount)          { types.insert(steps) }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)           { types.insert(heartRate) }
        if let calories  = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(calories) }
        if let sleep     = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)         { types.insert(sleep) }
        return types
    }()

    // MARK: - Error mapping

    /// Converts an `HKError` to the appropriate `HealthServiceError`.
    /// Authorization-denied codes map to `.unauthorized`; everything else maps to `.queryFailed`.
    private func mapHKError(_ error: Error) -> HealthServiceError {
        if let hkError = error as? HKError {
            switch hkError.code {
            case .errorAuthorizationDenied, .errorAuthorizationNotDetermined:
                return .unauthorized
            default:
                return .queryFailed(error)
            }
        }
        return .queryFailed(error)
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
        } catch {
            throw mapHKError(error)
        }
        // Note: HealthKit does not expose read-access denial status for privacy reasons —
        // `authorizationStatus(for:)` always returns `.notDetermined` for read types.
        // Authorization denial will surface as `.unauthorized` when a query explicitly
        // returns `HKError.errorAuthorizationDenied`, or as `.noData` when results are empty.
    }

    // MARK: - Steps

    /// Returns the total step count for today (midnight → now).
    func fetchSteps() async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthServiceError.unavailable
        }

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
                    continuation.resume(throwing: self.mapHKError(error))
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(throwing: HealthServiceError.noData)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: .count()).rounded()))
            }
            store.execute(query)
        }
    }

    // MARK: - Heart Rate

    /// Returns the average heart rate over the past 24 hours, in BPM.
    func fetchHeartRate() async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthServiceError.unavailable
        }

        let (start, end) = Date.last24HoursRange()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: self.mapHKError(error))
                    return
                }
                guard let average = result?.averageQuantity() else {
                    continuation.resume(throwing: HealthServiceError.noData)
                    return
                }
                let bpm = average.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
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
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthServiceError.unavailable
        }

        let (start, end) = Date.lastNightRange()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: self.mapHKError(error))
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample],
                      !categorySamples.isEmpty else {
                    continuation.resume(throwing: HealthServiceError.noData)
                    return
                }

                // Include all asleep sub-stages; exclude inBed / awake
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]

                // Clip each sample interval by intersecting with the query range
                let total = categorySamples.reduce(0.0) { acc, sample in
                    guard asleepValues.contains(sample.value) else { return acc }

                    // Clip sample start/end to the query window
                    let clippedStart = max(sample.startDate, start)
                    let clippedEnd = min(sample.endDate, end)

                    guard clippedStart < clippedEnd else { return acc }
                    return acc + clippedEnd.timeIntervalSince(clippedStart)
                }

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
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthServiceError.unavailable
        }

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
                    continuation.resume(throwing: self.mapHKError(error))
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(throwing: HealthServiceError.noData)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: .kilocalorie()))
            }
            store.execute(query)
        }
    }

    // MARK: - Snapshot

    /// Fetches all four metrics concurrently and returns a single `HealthSnapshot`.
    /// If all four fail, propagates a meaningful error. If at least one succeeds,
    /// constructs HealthSnapshot from successful values (zeroes for failed metrics).
    func fetchSnapshot() async throws -> HealthSnapshot {
        // Capture results with error handling
        let stepsResult = await Result { try await fetchSteps() }
        let hrResult = await Result { try await fetchHeartRate() }
        let sleepResult = await Result { try await fetchSleep() }
        let caloriesResult = await Result { try await fetchCalories() }

        // Extract values or nil
        let stepsValue = try? stepsResult.get()
        let hrValue = try? hrResult.get()
        let sleepValue = try? sleepResult.get()
        let caloriesValue = try? caloriesResult.get()

        // If all four failed, propagate the dominant error
        if stepsValue == nil && hrValue == nil && sleepValue == nil && caloriesValue == nil {
            // Count error types to determine dominant failure
            let errors = [stepsResult, hrResult, sleepResult, caloriesResult].compactMap { result -> HealthServiceError? in
                if case .failure(let error) = result {
                    return error as? HealthServiceError
                }
                return nil
            }

            // Prioritize: unauthorized > noData > queryFailed > unavailable
            if errors.contains(where: { if case .unauthorized = $0 { return true }; return false }) {
                throw HealthServiceError.unauthorized
            } else if errors.contains(where: { if case .noData = $0 { return true }; return false }) {
                throw HealthServiceError.noData
            } else if let firstQueryError = errors.first(where: { if case .queryFailed = $0 { return true }; return false }) {
                throw firstQueryError
            } else {
                throw HealthServiceError.unavailable
            }
        }

        // At least one metric succeeded — construct snapshot with available data
        return HealthSnapshot(
            steps: stepsValue ?? 0,
            heartRate: hrValue ?? 0,
            sleepDuration: sleepValue ?? 0,
            activeCalories: caloriesValue ?? 0
        )
    }
}

#else

/// Fallback `HealthService` for platforms where HealthKit is unavailable at compile time.
class HealthService: HealthServiceProtocol {
    func requestAuthorization() async throws { throw HealthServiceError.unavailable }
    func fetchSteps() async throws -> Int { throw HealthServiceError.unavailable }
    func fetchHeartRate() async throws -> Double { throw HealthServiceError.unavailable }
    func fetchSleep() async throws -> TimeInterval { throw HealthServiceError.unavailable }
    func fetchCalories() async throws -> Double { throw HealthServiceError.unavailable }
    func fetchSnapshot() async throws -> HealthSnapshot { throw HealthServiceError.unavailable }
}

#endif

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