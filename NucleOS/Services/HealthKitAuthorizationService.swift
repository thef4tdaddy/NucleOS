//
//  HealthKitAuthorizationService.swift
//  NucleOS
//
//  HealthKit availability check and authorization request layer.
//  UI never touches HKHealthStore directly — all auth state flows through this service.
//

import Foundation

// MARK: - Authorization Status

/// Unified authorization state for the HealthKit layer.
enum HealthKitAuthorizationStatus: Equatable, Sendable {
    /// The user has not yet been asked for permission.
    case notDetermined
    /// The user granted access to the requested data types.
    case authorized
    /// The user explicitly denied access, or a device/MDM policy prevented the prompt.
    case denied
    /// HealthKit is not available on this device (e.g., iPad without Health app).
    case unavailable
}

// MARK: - Errors

enum HealthKitAuthorizationError: LocalizedError {
    case healthDataUnavailable
    case authorizationDenied
    case notDetermined

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "HealthKit is not available on this device."
        case .authorizationDenied:
            return "Access to health data was denied. Enable it in Settings → Privacy & Security → Health."
        case .notDetermined:
            return "HealthKit authorization has not been requested yet. Call requestAuthorization() first."
        }
    }
}

// MARK: - Protocol

protocol HealthKitAuthorizationServiceProtocol: Sendable {
    /// Returns `true` when HealthKit is available on this device.
    var isHealthDataAvailable: Bool { get }

    /// The current authorization status, derived from the last `requestAuthorization()` call.
    var authorizationStatus: HealthKitAuthorizationStatus { get }

    /// Requests read authorization for the dashboard data types.
    /// - Returns: The resulting `HealthKitAuthorizationStatus` after the prompt.
    /// - Throws: `HealthKitAuthorizationError` if access is unavailable or denied.
    func requestAuthorization() async throws -> HealthKitAuthorizationStatus
}

// MARK: - Real Implementation

#if canImport(HealthKit)
import HealthKit

/// Concrete implementation that wraps `HKHealthStore` to manage authorization for the
/// four dashboard metrics: steps, heart rate, sleep, and active calories.
///
/// HealthKit deliberately does not expose per-type read authorization status to protect
/// user privacy. Post-request status is verified via `statusForAuthorizationRequest(toShare:read:)`:
/// - `.unnecessary` → the system has processed the prompt; treat as authorized (HealthKit hides read denials).
/// - `.shouldRequest` → still pending; status remains `.notDetermined`.
/// - `.unknown` → indeterminate result; throws `.authorizationDenied` to prevent silent failures.
final class HealthKitAuthorizationService: @unchecked Sendable, HealthKitAuthorizationServiceProtocol {

    private let store: HKHealthStore
    private let lock = NSLock()
    private var _authorizationStatus: HealthKitAuthorizationStatus = .notDetermined

    /// Data types the app needs read access to.
    private static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(calories)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    // MARK: HealthKitAuthorizationServiceProtocol

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var authorizationStatus: HealthKitAuthorizationStatus {
        guard isHealthDataAvailable else { return .unavailable }
        lock.lock()
        defer { lock.unlock() }
        return _authorizationStatus
    }

    func requestAuthorization() async throws -> HealthKitAuthorizationStatus {
        guard isHealthDataAvailable else {
            throw HealthKitAuthorizationError.healthDataUnavailable
        }

        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
        } catch {
            // HealthKit throws if the system or an MDM policy prevented the authorization prompt.
            setStatus(.denied)
            throw HealthKitAuthorizationError.authorizationDenied
        }

        // Verify the post-request status. HealthKit hides read-access denials for privacy,
        // so `.unnecessary` means the system processed the prompt — treat as authorized.
        let requestStatus = try await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes)
        switch requestStatus {
        case .unnecessary:
            // All requested types have been shown to the user; queries may proceed.
            setStatus(.authorized)
            return .authorized
        case .shouldRequest:
            // Prompt was presented but some types still appear pending; stay notDetermined.
            setStatus(.notDetermined)
            return .notDetermined
        case .unknown:
            setStatus(.denied)
            throw HealthKitAuthorizationError.authorizationDenied
        @unknown default:
            setStatus(.notDetermined)
            return .notDetermined
        }
    }

    // MARK: Private

    private func setStatus(_ status: HealthKitAuthorizationStatus) {
        lock.lock()
        defer { lock.unlock() }
        _authorizationStatus = status
    }
}
#endif

// MARK: - Mock Implementation

/// Mock implementation for SwiftUI previews and unit tests.
///
/// - Note: Mutable properties are intentionally not protected by a lock.
///   This mock is designed for single-threaded test and preview scenarios only.
final class MockHealthKitAuthorizationService: HealthKitAuthorizationServiceProtocol, @unchecked Sendable {

    var isHealthDataAvailable: Bool
    var authorizationStatus: HealthKitAuthorizationStatus
    var requestAuthorizationResult: HealthKitAuthorizationStatus

    init(
        isHealthDataAvailable: Bool = true,
        authorizationStatus: HealthKitAuthorizationStatus = .authorized,
        requestAuthorizationResult: HealthKitAuthorizationStatus = .authorized
    ) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.authorizationStatus = authorizationStatus
        self.requestAuthorizationResult = requestAuthorizationResult
    }

    func requestAuthorization() async throws -> HealthKitAuthorizationStatus {
        authorizationStatus = requestAuthorizationResult
        return requestAuthorizationResult
    }
}
