//
//  HealthViewModel.swift
//  NucleOS
//
//  Observable view model that owns HealthKit permission evaluation, data fetching,
//  and snapshot publishing — keeping all business logic out of the view layer.
//

import Foundation
import Combine

#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
final class HealthViewModel: ObservableObject {

    @Published private(set) var permissionState: HealthPermissionState = .notDetermined
    @Published private(set) var snapshot: HealthSnapshot?
    @Published private(set) var isLoading: Bool = false

    private let service: HealthServiceProtocol

    init(service: HealthServiceProtocol = HealthService()) {
        self.service = service
    }

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
    /// After the request completes, re-evaluates the permission state and fetches data.
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

        if permissionState == .authorized {
            await fetchData()
        }
#endif
    }

    // MARK: - Data Fetching

    /// Fetches a fresh `HealthSnapshot` from the service and publishes it.
    /// Transitions `permissionState` to `.empty` when authorized but no data is returned.
    /// Must be called after authorization is confirmed.
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchSnapshot()
            snapshot = fetched
        } catch HealthServiceError.noData {
            permissionState = .empty
        } catch HealthServiceError.unauthorized {
            permissionState = .denied
        } catch {
            // For unavailable or other transient errors, leave permissionState unchanged.
            // The snapshot remains nil and the view falls back to mock data.
        }
    }
}
