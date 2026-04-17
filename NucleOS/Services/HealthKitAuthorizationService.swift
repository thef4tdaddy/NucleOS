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

    /// Non-prompting check: uses `statusForAuthorizationRequest` to determine if the
    /// authorization prompt has already been shown and acted upon by the user.
    /// Returns `.authorized` when the user has previously decided (HealthKit treats both
    /// grant and deny as `.unnecessary` to protect read-access privacy).
    /// Returns `.notDetermined` when the prompt has not been shown yet.
    func checkAuthorizationStatus() async -> HealthKitAuthorizationStatus

    /// Requests read authorization for the dashboard data types.
    /// Shows the system authorization prompt on first call; subsequent calls are no-ops.
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

    /// Checks the current HealthKit authorization state for the app's required read types.
    /// - Returns: A `HealthKitAuthorizationStatus` describing the current state:
    ///   - `.unavailable` when HealthKit is not available on the device.
    ///   - `.authorized` when HealthKit reports the authorization prompt has already been handled for the requested read types.
    ///   - `.notDetermined` when the authorization prompt has not been shown or the status is unknown.
    func checkAuthorizationStatus() async -> HealthKitAuthorizationStatus {
        guard isHealthDataAvailable else { return .unavailable }
        guard let status = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes) else {
            return .notDetermined
        }
        switch status {
        case .unnecessary:
            // The system has previously shown the prompt; treat as authorized.
            // HealthKit hides read-access denials to protect user privacy — a failed
            // query will surface `.unauthorized` at fetch time if the user denied.
            return .authorized
        case .shouldRequest:
            return .notDetermined
        case .unknown:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    /// Requests read authorization for the app's required HealthKit data and returns the unified authorization status after the request.
    /// - Returns: A `HealthKitAuthorizationStatus` representing the post-request outcome: `.authorized` when access is granted or the system treated the prompt as already processed, or `.notDetermined` when the system still expects a prompt.
    /// - Throws: `HealthKitAuthorizationError.healthDataUnavailable` if HealthKit is not available on the device; `HealthKitAuthorizationError.authorizationDenied` if the authorization prompt was prevented (system/MDM) or the post-request status indicates denial.
    func requestAuthorization() async throws -> HealthKitAuthorizationStatus {
        guard isHealthDataAvailable else {
            throw HealthKitAuthorizationError.healthDataUnavailable
        }

        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
        } catch {
            // HealthKit throws if the system or an MDM policy prevented the authorization prompt.
            throw HealthKitAuthorizationError.authorizationDenied
        }

        // Verify the post-request status. HealthKit hides read-access denials for privacy,
        // so `.unnecessary` means the system processed the prompt — treat as authorized.
        let requestStatus = try await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes)
        switch requestStatus {
        case .unnecessary:
            return .authorized
        case .shouldRequest:
            return .notDetermined
        case .unknown:
            throw HealthKitAuthorizationError.authorizationDenied
        @unknown default:
            return .notDetermined
        }
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
    var checkStatusResult: HealthKitAuthorizationStatus
    var requestAuthorizationResult: HealthKitAuthorizationStatus

    init(
        isHealthDataAvailable: Bool = true,
        checkStatusResult: HealthKitAuthorizationStatus = .authorized,
        requestAuthorizationResult: HealthKitAuthorizationStatus = .authorized
    ) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.checkStatusResult = checkStatusResult
        self.requestAuthorizationResult = requestAuthorizationResult
    }

    /// Provides the mock's configured HealthKit authorization status for status checks.
    /// - Returns: The `HealthKitAuthorizationStatus` value currently stored in `checkStatusResult`.
    func checkAuthorizationStatus() async -> HealthKitAuthorizationStatus {
        return checkStatusResult
    }

    /// Provide the preconfigured authorization result for a simulated authorization request.
    /// - Returns: The `HealthKitAuthorizationStatus` value configured on the mock that represents the outcome of requesting HealthKit authorization.
    func requestAuthorization() async throws -> HealthKitAuthorizationStatus {
        return requestAuthorizationResult
    }
}
