//
//  HealthKitAuthorizationServiceTests.swift
//  NucleOSTests
//
//  Unit tests for HealthKitAuthorizationStatus, HealthKitAuthorizationError,
//  and MockHealthKitAuthorizationService.
//

import XCTest
@testable import NucleOS

final class HealthKitAuthorizationServiceTests: XCTestCase {

    // MARK: - HealthKitAuthorizationStatus Equatable

    func testStatusEquatableAuthorized() {
        XCTAssertEqual(HealthKitAuthorizationStatus.authorized, HealthKitAuthorizationStatus.authorized)
    }

    func testStatusEquatableNotDetermined() {
        XCTAssertEqual(HealthKitAuthorizationStatus.notDetermined, HealthKitAuthorizationStatus.notDetermined)
    }

    func testStatusEquatableDenied() {
        XCTAssertEqual(HealthKitAuthorizationStatus.denied, HealthKitAuthorizationStatus.denied)
    }

    func testStatusEquatableUnavailable() {
        XCTAssertEqual(HealthKitAuthorizationStatus.unavailable, HealthKitAuthorizationStatus.unavailable)
    }

    func testStatusNotEqualAuthorizedVsDenied() {
        XCTAssertNotEqual(HealthKitAuthorizationStatus.authorized, HealthKitAuthorizationStatus.denied)
    }

    func testStatusNotEqualNotDeterminedVsUnavailable() {
        XCTAssertNotEqual(HealthKitAuthorizationStatus.notDetermined, HealthKitAuthorizationStatus.unavailable)
    }

    // MARK: - HealthKitAuthorizationError errorDescription

    func testErrorDescriptionHealthDataUnavailable() {
        let error = HealthKitAuthorizationError.healthDataUnavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.contains("HealthKit"))
    }

    func testErrorDescriptionAuthorizationDenied() {
        let error = HealthKitAuthorizationError.authorizationDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        // Should mention settings since user needs to grant access
        XCTAssertTrue(error.errorDescription!.lowercased().contains("settings") ||
                      error.errorDescription!.lowercased().contains("denied"))
    }

    func testErrorDescriptionNotDetermined() {
        let error = HealthKitAuthorizationError.notDetermined
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("requestauthorization") ||
                      error.errorDescription!.lowercased().contains("not") ||
                      error.errorDescription!.lowercased().contains("requested"))
    }

    func testErrorIsLocalizedError() {
        let error: LocalizedError = HealthKitAuthorizationError.healthDataUnavailable
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - MockHealthKitAuthorizationService — Default initialization

    func testMockDefaultIsHealthDataAvailable() {
        let mock = MockHealthKitAuthorizationService()
        XCTAssertTrue(mock.isHealthDataAvailable)
    }

    func testMockDefaultCheckStatusResult() async {
        let mock = MockHealthKitAuthorizationService()
        let status = await mock.checkAuthorizationStatus()
        XCTAssertEqual(status, .authorized)
    }

    func testMockDefaultRequestAuthorizationResult() async throws {
        let mock = MockHealthKitAuthorizationService()
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .authorized)
    }

    // MARK: - MockHealthKitAuthorizationService — Custom initialization

    func testMockHealthDataUnavailableReturnsFalse() {
        let mock = MockHealthKitAuthorizationService(isHealthDataAvailable: false)
        XCTAssertFalse(mock.isHealthDataAvailable)
    }

    func testMockCheckStatusReturnsNotDetermined() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        let status = await mock.checkAuthorizationStatus()
        XCTAssertEqual(status, .notDetermined)
    }

    func testMockCheckStatusReturnsDenied() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .denied)
        let status = await mock.checkAuthorizationStatus()
        XCTAssertEqual(status, .denied)
    }

    func testMockCheckStatusReturnsUnavailable() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .unavailable)
        let status = await mock.checkAuthorizationStatus()
        XCTAssertEqual(status, .unavailable)
    }

    func testMockRequestAuthorizationReturnsNotDetermined() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .notDetermined)
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .notDetermined)
    }

    func testMockRequestAuthorizationReturnsDenied() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .denied)
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .denied)
    }

    func testMockRequestAuthorizationReturnsUnavailable() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .unavailable)
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .unavailable)
    }

    // MARK: - MockHealthKitAuthorizationService — Mutable properties

    func testMockCheckStatusResultIsMutable() async {
        let mock = MockHealthKitAuthorizationService(checkStatusResult: .notDetermined)
        mock.checkStatusResult = .authorized
        let status = await mock.checkAuthorizationStatus()
        XCTAssertEqual(status, .authorized)
    }

    func testMockRequestAuthorizationResultIsMutable() async throws {
        let mock = MockHealthKitAuthorizationService(requestAuthorizationResult: .notDetermined)
        mock.requestAuthorizationResult = .denied
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .denied)
    }

    func testMockIsHealthDataAvailableIsMutable() {
        let mock = MockHealthKitAuthorizationService(isHealthDataAvailable: true)
        mock.isHealthDataAvailable = false
        XCTAssertFalse(mock.isHealthDataAvailable)
    }

    // MARK: - All status cases covered

    func testAllStatusCasesDistinct() {
        let allCases: [HealthKitAuthorizationStatus] = [.notDetermined, .authorized, .denied, .unavailable]
        let uniqueSet = Set(allCases.map { "\($0)" })
        XCTAssertEqual(uniqueSet.count, 4, "All 4 status cases should be distinct")
    }

    // MARK: - Mock conforms to protocol

    func testMockConformsToProtocol() {
        let mock: HealthKitAuthorizationServiceProtocol = MockHealthKitAuthorizationService()
        XCTAssertTrue(mock.isHealthDataAvailable)
    }

    func testMockWithUnavailableHealthDataAndUnavailableStatus() async throws {
        let mock = MockHealthKitAuthorizationService(
            isHealthDataAvailable: false,
            checkStatusResult: .unavailable,
            requestAuthorizationResult: .unavailable
        )
        XCTAssertFalse(mock.isHealthDataAvailable)
        let checkStatus = await mock.checkAuthorizationStatus()
        XCTAssertEqual(checkStatus, .unavailable)
        let requestStatus = try await mock.requestAuthorization()
        XCTAssertEqual(requestStatus, .unavailable)
    }
}