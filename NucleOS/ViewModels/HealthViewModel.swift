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
    /// (no system prompt is shown) and fetches data if already authorized.
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
    /// no-ops from the user's perspective. On success, fetches health data immediately.
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
        } catch {
            permissionState = .denied
            snapshot = nil
        }
    }

    // MARK: - Data Fetching

    /// Fetches a fresh `HealthSnapshot` from the service and publishes it.
    /// Transitions `permissionState` to `.empty` or `.denied` on the matching errors and
    /// clears any previously cached snapshot so stale data is not shown.
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
