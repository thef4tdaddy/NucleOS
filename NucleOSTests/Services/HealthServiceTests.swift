//
//  HealthServiceTests.swift
//  NucleOSTests/Services
//
//  Swift Testing suite for HealthService — mock-only, zero real HealthKit calls.
//

import Testing
@testable import NucleOS

@Suite("Health Service")
struct HealthServiceTests {

    // MARK: - fetchSnapshot

    @Test("fetchSnapshot returns valid HealthSnapshot")
    func fetchSnapshotReturnsSnapshot() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        // Snapshot is a valid value type — just having it is a pass
        _ = snapshot
    }

    @Test("steps >= 0")
    func stepsNonNegative() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        #expect(snapshot.steps >= 0)
    }

    @Test("heartRate between 20 and 300 bpm")
    func heartRatePhysiological() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        #expect(snapshot.heartRate >= 20)
        #expect(snapshot.heartRate <= 300)
    }

    @Test("sleepDuration between 0 and 24 hours")
    func sleepHoursReasonable() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        let sleepHours = snapshot.sleepDuration / 3600
        #expect(sleepHours >= 0)
        #expect(sleepHours <= 24)
    }

    @Test("calories >= 0")
    func caloriesNonNegative() async throws {
        let service = MockHealthService()
        let snapshot = try await service.fetchSnapshot()
        #expect(snapshot.activeCalories >= 0)
    }

    @Test("fetchSnapshot completes without throw on mock")
    func fetchSnapshotDoesNotThrow() async throws {
        let service = MockHealthService()
        // If this completes without throwing, the test passes
        let snapshot = try await service.fetchSnapshot()
        _ = snapshot
    }

    // MARK: - Individual fetches

    @Test("fetchSteps returns non-negative int")
    func fetchStepsNonNegative() async throws {
        let service = MockHealthService()
        let steps = try await service.fetchSteps()
        #expect(steps >= 0)
    }

    @Test("fetchHeartRate returns physiological BPM")
    func fetchHeartRatePhysiological() async throws {
        let service = MockHealthService()
        let hr = try await service.fetchHeartRate()
        #expect(hr >= 20)
        #expect(hr <= 300)
    }

    @Test("fetchSleep returns valid TimeInterval")
    func fetchSleepValidInterval() async throws {
        let service = MockHealthService()
        let sleep = try await service.fetchSleep()
        #expect(sleep >= 0)
        #expect(sleep <= 86400) // max 24 hours
    }

    @Test("fetchCalories returns non-negative value")
    func fetchCaloriesNonNegative() async throws {
        let service = MockHealthService()
        let calories = try await service.fetchCalories()
        #expect(calories >= 0)
    }

    // MARK: - Protocol conformance

    @Test("MockHealthService conforms to HealthServiceProtocol")
    func mockConformsToProtocol() {
        let service: HealthServiceProtocol = MockHealthService()
        #expect(service is MockHealthService)
    }

    // MARK: - requestAuthorization

    @Test("requestAuthorization does not throw on mock")
    func requestAuthorizationNoThrow() async throws {
        let service = MockHealthService()
        try await service.requestAuthorization()
    }
}
