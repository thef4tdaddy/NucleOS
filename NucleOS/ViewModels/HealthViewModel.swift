//
//  HealthViewModel.swift
//  NucleOS
//
//  Observable view model that owns HealthKit permission evaluation,
//  keeping business logic out of the view layer.
//

import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
final class HealthViewModel: ObservableObject {

    @Published private(set) var permissionState: HealthPermissionState = .notDetermined

#if canImport(HealthKit)
    /// Shared store instance — HealthKit best practice is one store per app.
    private static let store = HKHealthStore()
#endif

    // MARK: - Permission Evaluation

    /// Evaluates the current HealthKit availability and authorization status,
    /// then updates `permissionState` accordingly.
    func evaluatePermissionState() {
#if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            permissionState = .unavailable
            return
        }

        let stepType = HKQuantityType(.stepCount)
        let status = Self.store.authorizationStatus(for: stepType)

        switch status {
        case .notDetermined:
            permissionState = .notDetermined
        case .sharingDenied:
            permissionState = .denied
        case .sharingAuthorized:
            permissionState = .authorized
        @unknown default:
            permissionState = .notDetermined
        }
#else
        permissionState = .unavailable
#endif
    }

    // MARK: - Authorization Request

    /// Requests HealthKit authorization for the metrics NucleOS displays.
    /// After the request completes, re-evaluates the permission state.
    func requestAuthorization() async {
#if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKCategoryType(.sleepAnalysis),
        ]

        do {
            try await Self.store.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            print("HealthKit authorization error: \(error)")
        }

        evaluatePermissionState()
#endif
    }
}
