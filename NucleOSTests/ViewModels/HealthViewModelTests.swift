//
//  HealthViewModelTests.swift
//  NucleOSTests/ViewModels
//
//  Swift Testing suite for HealthViewModel — mock-only, zero real HealthKit calls.
//  All tests run on @MainActor to match HealthViewModel's isolation.
//

import Testing
@testable import NucleOS

@Suite("Health ViewModel")
@MainActor
struct HealthViewModelTests {

    // MARK: - Initial state

    @Test("Initial permissionState is .notDetermined")
    func initialPermissionStateIsNotDetermined() {
        let vm = HealthViewModel(
            service: MockHealthService(),
            authService: MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        )
        #expect(vm.permissionState == .notDetermined)
    }

    @Test("snapshot is nil before any auth/fetch")
    func snapshotIsNilBeforeAuth() {
        let vm = HealthViewModel(
            service: MockHealthService(),
            authService: MockHealthKitAuthorizationService()
        )
        #expect(vm.snapshot == nil)
    }

    @Test("isLoading starts false")
    func isLoadingStartsFalse() {
        let vm = HealthViewModel(
            service: MockHealthService(),
            authService: MockHealthKitAuthorizationService()
        )
        #expect(vm.isLoading == false)
    }

    // MARK: - evaluatePermissionState

    @Test("evaluatePermissionState: authorized sets state and fetches snapshot")
    func evaluateAuthorizedSetsStateAndFetchesSnapshot() async {
        let auth = MockHealthKitAuthorizationService(checkStatusResult: .authorized)
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.evaluatePermissionState()
        #expect(vm.permissionState == .authorized)
        #expect(vm.snapshot != nil)
    }

    @Test("evaluatePermissionState: notDetermined sets state without fetch")
    func evaluateNotDeterminedSetsStateNoFetch() async {
        let auth = MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.evaluatePermissionState()
        #expect(vm.permissionState == .notDetermined)
        #expect(vm.snapshot == nil)
    }

    @Test("evaluatePermissionState: unavailable sets unavailable state")
    func evaluateUnavailableSetsState() async {
        let auth = MockHealthKitAuthorizationService(
            isHealthDataAvailable: false,
            checkStatusResult: .unavailable
        )
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.evaluatePermissionState()
        #expect(vm.permissionState == .unavailable)
    }

    @Test("evaluatePermissionState: denied clears snapshot")
    func evaluateDeniedClearsSnapshot() async {
        let auth = MockHealthKitAuthorizationService(checkStatusResult: .denied)
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.evaluatePermissionState()
        #expect(vm.permissionState == .denied)
        #expect(vm.snapshot == nil)
    }

    // MARK: - fetchData

    @Test("isLoading is true during fetch (false after completion)")
    func isLoadingFalseAfterFetch() async {
        let vm = HealthViewModel(
            service: MockHealthService(),
            authService: MockHealthKitAuthorizationService(checkStatusResult: .authorized)
        )
        await vm.fetchData()
        #expect(vm.isLoading == false)
    }

    @Test("snapshot populated after successful fetchData")
    func snapshotPopulatedAfterFetch() async {
        let vm = HealthViewModel(
            service: MockHealthService(),
            authService: MockHealthKitAuthorizationService(checkStatusResult: .authorized)
        )
        await vm.fetchData()
        #expect(vm.snapshot != nil)
        #expect(vm.snapshot?.steps == MockData.healthSnapshot.steps)
    }

    @Test("fetchData with noData error sets permissionState to .empty")
    func fetchDataNoDataSetsEmpty() async {
        let failing = ThrowingMockHealthService(result: .failure(HealthServiceError.noData))
        let vm = HealthViewModel(
            service: failing,
            authService: MockHealthKitAuthorizationService(checkStatusResult: .authorized)
        )
        await vm.fetchData()
        #expect(vm.permissionState == .empty)
        #expect(vm.snapshot == nil)
    }

    @Test("fetchData with unauthorized error sets permissionState to .denied")
    func fetchDataUnauthorizedSetsDenied() async {
        let failing = ThrowingMockHealthService(result: .failure(HealthServiceError.unauthorized))
        let vm = HealthViewModel(
            service: failing,
            authService: MockHealthKitAuthorizationService(checkStatusResult: .authorized)
        )
        await vm.fetchData()
        #expect(vm.permissionState == .denied)
        #expect(vm.snapshot == nil)
    }

    // MARK: - requestAuthorization

    @Test("requestAuthorization: authorized sets state and populates snapshot")
    func requestAuthorizationAuthorized() async {
        let auth = MockHealthKitAuthorizationService(requestAuthorizationResult: .authorized)
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.requestAuthorization()
        #expect(vm.permissionState == .authorized)
        #expect(vm.snapshot != nil)
    }

    @Test("requestAuthorization: denied sets state and clears snapshot")
    func requestAuthorizationDenied() async {
        let auth = MockHealthKitAuthorizationService(requestAuthorizationResult: .denied)
        let vm = HealthViewModel(service: MockHealthService(), authService: auth)
        await vm.requestAuthorization()
        #expect(vm.permissionState == .denied)
        #expect(vm.snapshot == nil)
    }
}
