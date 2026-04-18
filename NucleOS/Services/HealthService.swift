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
    /// Maps an Error originating from HealthKit to the corresponding `HealthServiceError`.
    /// - Parameter error: The error produced by a HealthKit operation.
    /// - Returns: A `HealthServiceError` representing the provided error — `.unauthorized` for authorization-related `HKError` codes, otherwise `.queryFailed` wrapping the original error.
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

    /// Requests read-only authorization for the service's configured HealthKit data types.
    /// 
    /// Attempts to obtain read access to the static set of health types defined by the service.
    /// - Throws: `HealthServiceError.unavailable` if Health data is not available on the device.
    /// - Throws: `HealthServiceError.unauthorized` if the user has denied read access (mapped from `HKError.errorAuthorizationDenied`/`errorAuthorizationNotDetermined`).
    /// - Throws: `HealthServiceError.queryFailed(_)` for other underlying HealthKit errors.

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

    /// Fetches the cumulative step count recorded since the start of today from HealthKit.
    /// - Returns: The total number of steps since the start of today, rounded to the nearest integer.
    /// - Throws: `HealthServiceError.unavailable` if HealthKit or the step count type is not available.
    /// - Throws: `HealthServiceError.noData` if no cumulative step data is available for today.
    /// - Throws: `HealthServiceError.unauthorized` if access to step data is denied.
    /// - Throws: `HealthServiceError.queryFailed(_:)` if an underlying HealthKit query fails.
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

    /// Fetches the most recent heart rate measurement from HealthKit taken within the last 24 hours.
    /// - Returns: The most recent heart rate in beats per minute.
    /// - Throws: `HealthServiceError.unavailable` if HealthKit or the heart rate quantity type is unavailable; `HealthServiceError.noData` if no samples are found; `HealthServiceError.queryFailed(_)` if the underlying HealthKit query fails.
    func fetchHeartRate() async throws -> Double {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthServiceError.unavailable
        }

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
                    continuation.resume(throwing: self.mapHKError(error))
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
    /// Calculates the total time spent asleep during last night.
    /// 
    /// Aggregates sleep analysis samples from the last-night time window and returns the summed duration of asleep states.
    /// - Returns: Total time asleep in seconds as a `TimeInterval`.
    /// - Throws:
    ///   - `HealthServiceError.unavailable` if HealthKit is not available or the sleep analysis type cannot be retrieved.
    ///   - `HealthServiceError.noData` if no sleep samples are found for the requested range.
    ///   - `HealthServiceError.unauthorized` or `HealthServiceError.queryFailed(Error)` when the underlying HealthKit query fails or access is denied.
    func fetchSleep() async throws -> TimeInterval {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthServiceError.unavailable
        }

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

                let total = categorySamples.reduce(0.0) { acc, sample in
                    asleepValues.contains(sample.value)
                        ? acc + sample.endDate.timeIntervalSince(sample.startDate)
                        : acc
                }

                continuation.resume(returning: total)
            }
            store.execute(query)
        }
    }

    // MARK: - Calories

    /// Fetches the cumulative active energy burned for today in kilocalories.
    /// - Returns: The total active energy burned today, expressed in kilocalories.
    /// - Throws:
    ///   - `HealthServiceError.unavailable` if HealthKit is not available or the required quantity type is missing.
    ///   - `HealthServiceError.noData` if no cumulative energy data is available for today.
    ///   - `HealthServiceError.queryFailed(let error)` if an underlying HealthKit query fails; the associated `error` provides details.
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

    /// Fetches all supported health metrics concurrently and returns a consolidated snapshot.
    ///
    /// - Performs steps, heart rate, sleep duration, and active calories fetches in parallel; if any individual fetch fails, that metric is set to `0` in the returned snapshot.
    /// - Returns: A `HealthSnapshot` containing `steps`, `heartRate`, `sleepDuration`, and `activeCalories`, where each metric is the fetched value or `0` if its fetch failed.
    func fetchSnapshot() async throws -> HealthSnapshot {
        try await SentryConfig.traced(operation: "db.query", name: "HealthService.fetchSnapshot") {
        async let steps = fetchSteps()
        async let hr = fetchHeartRate()
        async let sleep = fetchSleep()
        async let calories = fetchCalories()

        return HealthSnapshot(
            steps: (try? await steps) ?? 0,
            heartRate: (try? await hr) ?? 0,
            sleepDuration: (try? await sleep) ?? 0,
            activeCalories: (try? await calories) ?? 0
        )
        }
    }
}

#else

/// Fallback `HealthService` for platforms where HealthKit is unavailable at compile time.
class HealthService: HealthServiceProtocol {
    /// Requests authorization to read health data from HealthKit.
/// - Throws: `HealthServiceError.unavailable` if HealthKit is not available on the current platform.
func requestAuthorization() async throws { throw HealthServiceError.unavailable }
    /// Fetches the total number of steps recorded since the start of today.
/// - Returns: The total step count for the current day.
/// - Throws: `HealthServiceError.unavailable` when the Health service (HealthKit) is not available or cannot provide step data.
func fetchSteps() async throws -> Int { throw HealthServiceError.unavailable }
    /// Fetches the most recent heart rate measured within the last 24 hours, expressed in beats per minute.
/// - Returns: The heart rate in beats per minute (BPM).
/// - Throws: `HealthServiceError.unavailable` if health data is not available on the current platform.
func fetchHeartRate() async throws -> Double { throw HealthServiceError.unavailable }
    /// Calculates the total duration classified as asleep for the device's last night sleep window.
/// Aggregates sleep samples that represent asleep states and returns their combined duration.
/// - Returns: Total sleep duration (in seconds) for the last night.
/// - Throws: `HealthServiceError.unavailable` if HealthKit is not available on the current platform.
func fetchSleep() async throws -> TimeInterval { throw HealthServiceError.unavailable }
    /// Fetches the device's active energy burned for today in kilocalories.
/// - Returns: The total active energy burned today, in kilocalories.
/// - Throws: `HealthServiceError.unavailable` if HealthKit is not available on the current platform.
func fetchCalories() async throws -> Double { throw HealthServiceError.unavailable }
    /// Provides a snapshot of key health metrics (steps, most recent heart rate, sleep duration, and calories burned).
/// - Returns: A `HealthSnapshot` containing step count, heart rate in beats per minute, sleep time in seconds, and calories in kilocalories.
/// - Throws: `HealthServiceError.unavailable` when HealthKit is not available on the current platform.
func fetchSnapshot() async throws -> HealthSnapshot { throw HealthServiceError.unavailable }
}

#endif

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
class MockHealthService: HealthServiceProtocol {

    /// Treats health authorization as granted for the mock service.
    /// 
    /// No operation; used in tests and previews to simulate a granted HealthKit authorization.
    func requestAuthorization() async throws {
        // No-op for mock — authorization is always considered granted.
    }

    /// Provides the mocked step count for the current day.
    /// - Returns: The step count from the mock health snapshot as an `Int`.
    func fetchSteps() async throws -> Int {
        return MockData.healthSnapshot.steps
    }

    func fetchHeartRate() async throws -> Double {
        return MockData.healthSnapshot.heartRate
    }

    func fetchSleep() async throws -> TimeInterval {
        return MockData.healthSnapshot.sleepDuration
    }

    /// Provides the mock active energy burned value.
    /// - Returns: The mock active energy burned in kilocalories.
    func fetchCalories() async throws -> Double {
        return MockData.healthSnapshot.activeCalories
    }

    /// Provide a predefined health data snapshot for previews and tests.
    /// - Returns: A `HealthSnapshot` populated with mock values from `MockData.healthSnapshot`.
    func fetchSnapshot() async throws -> HealthSnapshot {
        return MockData.healthSnapshot
    }
}
