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
    func fetchSteps() async throws -> Int
    func fetchHeartRate() async throws -> Double
    func fetchSleep() async throws -> TimeInterval
    func fetchCalories() async throws -> Double
}

// MARK: - Errors

enum HealthServiceError: LocalizedError {
    case unauthorized
    case dataNotAvailable
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "HealthKit access is not authorized. Please grant permission in Settings."
        case .dataNotAvailable:
            return "No health data is available for the requested metric."
        case .queryFailed(let reason):
            return "HealthKit query failed: \(reason)"
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that integrates with HealthKit.
/// Depends on `HealthKitAuthorizationService` to verify access before querying.
class HealthService: HealthServiceProtocol {

    private let store: HKHealthStore
    private let authService: HealthKitAuthorizationServiceProtocol

    init(
        store: HKHealthStore = HKHealthStore(),
        authService: HealthKitAuthorizationServiceProtocol = HealthKitAuthorizationService()
    ) {
        self.store = store
        self.authService = authService
    }

    // MARK: - Private Helpers

    private func requireAuthorization() throws {
        switch authService.authorizationStatus {
        case .authorized:
            break
        case .notDetermined:
            throw HealthKitAuthorizationError.notDetermined
        case .denied:
            throw HealthKitAuthorizationError.authorizationDenied
        case .unavailable:
            throw HealthKitAuthorizationError.healthDataUnavailable
        }
    }

    /// Returns a date representing the start of today in the current calendar.
    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }

    // MARK: - HealthServiceProtocol

    func fetchSteps() async throws -> Int {
        try requireAuthorization()

        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthServiceError.dataNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error.localizedDescription))
                    return
                }
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    func fetchHeartRate() async throws -> Double {
        try requireAuthorization()

        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthServiceError.dataNotAvailable
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error.localizedDescription))
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(throwing: HealthServiceError.dataNotAvailable)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    func fetchSleep() async throws -> TimeInterval {
        try requireAuthorization()

        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthServiceError.dataNotAvailable
        }

        // Look back 24 hours for the most recent sleep session.
        let yesterday = Date(timeIntervalSinceNow: -86_400)
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error.localizedDescription))
                    return
                }
                guard let samples else {
                    continuation.resume(throwing: HealthServiceError.dataNotAvailable)
                    return
                }
                // Sum all asleep stages; skip any samples with unrecognised category values.
                let asleepValues: Set<HKCategoryValueSleepAnalysis> = [.asleepCore, .asleepDeep, .asleepREM]
                let totalSleep = samples
                    .compactMap { $0 as? HKCategorySample }
                    .filter { sample in
                        guard let stage = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                        return asleepValues.contains(stage)
                    }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSleep)
            }
            store.execute(query)
        }
    }

    func fetchCalories() async throws -> Double {
        try requireAuthorization()

        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthServiceError.dataNotAvailable
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: HealthServiceError.queryFailed(error.localizedDescription))
                    return
                }
                let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            store.execute(query)
        }
    }
}

// MARK: - Mock Implementation

/// Mock implementation backed by `MockData` for SwiftUI previews and testing.
class MockHealthService: HealthServiceProtocol {

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
}
