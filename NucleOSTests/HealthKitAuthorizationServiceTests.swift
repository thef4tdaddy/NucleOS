//
//  HealthKitAuthorizationServiceTests.swift
//  NucleOSTests
//
//  Unit tests for HealthKitAuthorizationStatus, HealthKitAuthorizationError,
//  and MockHealthKitAuthorizationService.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("HealthKit Authorization Service")
struct HealthKitAuthorizationServiceTests {

    // MARK: - HealthKitAuthorizationStatus Equatable

    @Test("authorized equals authorized")
    func statusEquatableAuthorized() {
        #expect(HealthKitAuthorizationStatus.authorized == HealthKitAuthorizationStatus.authorized)
    }

    @Test("notDetermined equals notDetermined")
    func statusEquatableNotDetermined() {
        #expect(HealthKitAuthorizationStatus.notDetermined == HealthKitAuthorizationStatus.notDetermined)
    }

    @Test("denied equals denied")
    func statusEquatableDenied() {
        #expect(HealthKitAuthorizationStatus.denied == HealthKitAuthorizationStatus.denied)
    }

    @Test("unavailable equals unavailable")
    func statusEquatableUnavailable() {
        #expect(HealthKitAuthorizationStatus.unavailable == HealthKitAuthorizationStatus.unavailable)
    }

    @Test("authorized does not equal denied")
    func statusNotEqualAuthorizedVsDenied() {
        #expect(HealthKitAuthorizationStatus.authorized != HealthKitAuthorizationStatus.denied)
    }

    @Test("notDetermined does not equal unavailable")
    func statusNotEqualNotDeterminedVsUnavailable() {
        #expect(HealthKitAuthorizationStatus.notDetermined != HealthKitAuthorizationStatus.unavailable)
    }

    @Test("all 4 status cases are distinct")
    func allStatusCasesDistinct() {
        let allCases: [HealthKitAuthorizationStatus] = [.notDetermined, .authorized, .denied, .unavailable]
        let uniqueSet = Set(allCases.map { "\($0)" })
        #expect(uniqueSet.count == 4)
    }

    // MARK: - HealthKitAuthorizationError errorDescription

    @Test("healthDataUnavailable error has description mentioning HealthKit")
    func errorDescriptionHealthDataUnavailable() {
        let error = HealthKitAuthorizationError.healthDataUnavailable
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.errorDescription?.contains("HealthKit") == true)
    }

    @Test("authorizationDenied error has non-empty description")
    func errorDescriptionAuthorizationDenied() {
        let error = HealthKitAuthorizationError.authorizationDenied
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
        let desc = error.errorDescription?.lowercased() ?? ""
        #expect(desc.contains("settings") || desc.contains("denied"))
    }

    @Test("notDetermined error has non-empty description")
    func errorDescriptionNotDetermined() {
        let error = HealthKitAuthorizationError.notDetermined
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }

    @Test("error conforms to LocalizedError")
    func errorIsLocalizedError() {
        let error: LocalizedError = HealthKitAuthorizationError.healthDataUnavailable
        #expect(error.errorDescription != nil)
    }

    // MARK: - MockHealthKitAuthorizationService — Default initialization

    @Test("mock default isHealthDataAvailable is true")
    func mockDefaultIsHealthDataAvailable() {
        let mock = MockHealthKitAuthorizationService()
        #expect(mock.isHealthDataAvailable)
    }

    @Test("mock default checkAuthorizationStatus returns authorized")
    func mockDefaultCheckStatusResult() async {
        let mock = MockHealthKitAuthorizationService()
        let status = await mock.checkAuthorizationStatus()
        #expect(status == .authorized)
    }

    @Test("mock default requestAuthorization returns authorized")
    func mockDefaultRequestAuthorizationResult() async throws {
        let mock = MockHealthKitAuthorizationService()
        let status = try await mock.requestAuthorization()
        #expect(status == .authorized)
    }

    // MARK: - MockHealthKitAuthorizationService — Custom initialization

    @Test("mock with isHealthDataAvailable false returns false")
    func mockHealthDataUnavailableReturnsFalse() {
        let mock = MockHealthKitAuthorizationService(isHealthDataAvailable: false)
        #expect(!mock.isHealthDataAvailable)
    }

    @Test("mock checkStatus returns notDetermined when configured")
    func mockCheckStatusReturnsNotDetermined() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        let status = await mock.checkAuthorizationStatus()
        #expect(status == .notDetermined)
    }

    @Test("mock checkStatus returns denied when configured")
    func mockCheckStatusReturnsDenied() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .denied)
        let status = await mock.checkAuthorizationStatus()
        #expect(status == .denied)
    }

    @Test("mock checkStatus returns unavailable when configured")
    func mockCheckStatusReturnsUnavailable() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .unavailable)
        let status = await mock.checkAuthorizationStatus()
        #expect(status == .unavailable)
    }

    @Test("mock requestAuthorization returns notDetermined when configured")
    func mockRequestAuthorizationReturnsNotDetermined() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .notDetermined)
        let status = try await mock.requestAuthorization()
        #expect(status == .notDetermined)
    }

    @Test("mock requestAuthorization returns denied when configured")
    func mockRequestAuthorizationReturnsDenied() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .denied)
        let status = try await mock.requestAuthorization()
        #expect(status == .denied)
    }

    @Test("mock requestAuthorization returns unavailable when configured")
    func mockRequestAuthorizationReturnsUnavailable() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .unavailable)
        let status = try await mock.requestAuthorization()
        #expect(status == .unavailable)
    }

    // MARK: - MockHealthKitAuthorizationService — Mutable properties

    @Test("mock checkStatusResult property is mutable")
    func mockCheckStatusResultIsMutable() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        mock.checkStatusResult = .authorized
        let status = await mock.checkAuthorizationStatus()
        #expect(status == .authorized)
    }

    @Test("mock requestAuthorizationResult property is mutable")
    func mockRequestAuthorizationResultIsMutable() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .notDetermined)
        mock.requestAuthorizationResult = .denied
        let status = try await mock.requestAuthorization()
        #expect(status == .denied)
    }

    @Test("mock isHealthDataAvailable property is mutable")
    func mockIsHealthDataAvailableIsMutable() {
        let mock = MockHealthKitAuthorizationService(isHealthDataAvailable: true)
        mock.isHealthDataAvailable = false
        #expect(!mock.isHealthDataAvailable)
    }

    // MARK: - Mock conforms to protocol

    @Test("mock conforms to HealthKitAuthorizationServiceProtocol")
    func mockConformsToProtocol() {
        let mock: HealthKitAuthorizationServiceProtocol = MockHealthKitAuthorizationService()
        #expect(mock.isHealthDataAvailable)
    }

    @Test("mock handles all-unavailable configuration")
    func mockWithUnavailableHealthDataAndUnavailableStatus() async throws {
        let mock = MockHealthKitAuthorizationService(
            isHealthDataAvailable: false,
            checkStatusResult: .unavailable,
            requestAuthorizationResult: .unavailable
        )
        #expect(!mock.isHealthDataAvailable)
        let checkStatus = await mock.checkAuthorizationStatus()
        #expect(checkStatus == .unavailable)
        let requestStatus = try await mock.requestAuthorization()
        #expect(requestStatus == .unavailable)
    }
}
