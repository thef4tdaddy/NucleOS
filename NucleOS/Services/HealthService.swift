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
    func fetchSteps() async throws -> Int
    func fetchHeartRate() async throws -> Double
    func fetchSleep() async throws -> TimeInterval
    func fetchCalories() async throws -> Double
}

// MARK: - Errors

enum HealthServiceError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "HealthService is not implemented yet. HealthKit integration is still pending."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with HealthKit.
class HealthService: HealthServiceProtocol {

    func fetchSteps() async throws -> Int {
        // TODO: Request HealthKit authorization and query HKQuantityType.stepCount
        throw HealthServiceError.notImplemented
    }

    func fetchHeartRate() async throws -> Double {
        // TODO: Query most recent HKQuantityType.heartRate sample
        throw HealthServiceError.notImplemented
    }

    func fetchSleep() async throws -> TimeInterval {
        // TODO: Query HKCategoryType.sleepAnalysis for last night's sleep duration
        throw HealthServiceError.notImplemented
    }

    func fetchCalories() async throws -> Double {
        // TODO: Query HKQuantityType.activeEnergyBurned for today
        throw HealthServiceError.notImplemented
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
