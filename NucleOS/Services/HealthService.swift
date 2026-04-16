//
//  HealthService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for HealthKit data
//

import Foundation

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

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
class MockHealthService: HealthServiceProtocol {

    func fetchSteps() async throws -> Int {
        return 8_432
    }

    func fetchHeartRate() async throws -> Double {
        return 72.0
    }

    func fetchSleep() async throws -> TimeInterval {
        // 7 hours 23 minutes in seconds
        return (7 * 60 + 23) * 60
    }

    func fetchCalories() async throws -> Double {
        return 487.0
    }
}
