//
//  HealthViewModel.swift
//  NucleOS
//
//  Observable view model that owns HealthKit permission evaluation, data fetching,
//  and snapshot publishing — keeping all business logic out of the view layer.
//

import Combine
import Foundation

@MainActor
final class HealthViewModel: ObservableObject {

    @Published private(set) var permissionState: HealthPermissionState = .notDetermined
    @Published private(set) var snapshot: HealthSnapshot?
    @Published private(set) var isLoading: Bool = false

    private let service: HealthServiceProtocol
    private let authService: HealthKitAuthorizationServiceProtocol

    init(
        service: HealthServiceProtocol = HealthService(),
        authService: HealthKitAuthorizationServiceProtocol? = nil
    ) {
        self.service = service
        if let authService {
            self.authService = authService
        } else {
            #if canImport(HealthKit)
            self.authService = HealthKitAuthorizationService()
            #else
            self.authService = MockHealthKitAuthorizationService(
                isHealthDataAvailable: false,
                checkStatusResult: .unavailable,
                requestAuthorizationResult: .unavailable
            )
            #endif
        }
    }

    // MARK: - Permission Evaluation

    /// Checks the current HealthKit authorization state via `statusForAuthorizationRequest`
    /// Evaluates current HealthKit authorization and updates the view model's published state accordingly.
    /// 
    /// Checks whether health data is available; if not, sets `permissionState` to `.unavailable`. If available,
    /// determines the authorization status and updates `permissionState` to one of `.authorized`, `.notDetermined`,
    /// `.denied`, or `.unavailable`. When authorization is `.denied` the stored `snapshot` is cleared. When
    /// authorization is `.authorized` the view model begins fetching a fresh `HealthSnapshot`.
    func evaluatePermissionState() async {
        guard authService.isHealthDataAvailable else {
            permissionState = .unavailable
            return
        }

        let status = await authService.checkAuthorizationStatus()
        switch status {
        case .authorized:
            permissionState = .authorized
            await fetchData()
        case .notDetermined:
            permissionState = .notDetermined
        case .denied:
            permissionState = .denied
            snapshot = nil
        case .unavailable:
            permissionState = .unavailable
        }
    }

    // MARK: - Authorization Request

    /// Requests HealthKit authorization via the injected auth service.
    /// On first launch this shows the system permission prompt; subsequent calls are
    /// Requests HealthKit authorization and updates the view model's permission state and snapshot accordingly.
    /// 
    /// On authorization success:
    /// - `.authorized`: sets `permissionState` to `.authorized` and triggers a data fetch.
    /// - `.denied`: sets `permissionState` to `.denied` and clears `snapshot`.
    /// - `.notDetermined`: sets `permissionState` to `.notDetermined`.
    /// - `.unavailable`: sets `permissionState` to `.unavailable`.
    /// If `HealthKitAuthorizationError.healthDataUnavailable` is thrown, sets `permissionState` to `.unavailable` and clears `snapshot`. For any other thrown error, sets `permissionState` to `.denied` and clears `snapshot`.
    func requestAuthorization() async {
        do {
            let status = try await authService.requestAuthorization()
            switch status {
            case .authorized:
                permissionState = .authorized
                await fetchData()
            case .denied:
                permissionState = .denied
                snapshot = nil
            case .notDetermined:
                permissionState = .notDetermined
            case .unavailable:
                permissionState = .unavailable
            }
        } catch HealthKitAuthorizationError.healthDataUnavailable {
            permissionState = .unavailable
            snapshot = nil
        } catch {
            permissionState = .denied
            snapshot = nil
        }
    }

    // MARK: - Data Fetching

    /// Fetches a fresh `HealthSnapshot` from the service and publishes it.
    /// Transitions `permissionState` to `.empty` or `.denied` on the matching errors and
    /// Fetches the latest health snapshot and publishes it to `snapshot`, while managing loading and permission state.
    /// 
    /// On success, updates `snapshot` with the fetched `HealthSnapshot`. If `HealthServiceError.noData` occurs, clears `snapshot` and sets `permissionState` to `.empty`. If `HealthServiceError.unauthorized` occurs, clears `snapshot` and sets `permissionState` to `.denied`. For any other error, leaves `permissionState` and `snapshot` unchanged. While the operation runs, `isLoading` is set to `true` and is cleared when the method completes.
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchSnapshot()
            snapshot = fetched
        } catch HealthServiceError.noData {
            snapshot = nil
            permissionState = .empty
        } catch HealthServiceError.unauthorized {
            snapshot = nil
            permissionState = .denied
        } catch {
            // Transient or unavailable error — leave permissionState and snapshot unchanged.
        }
    }
}
