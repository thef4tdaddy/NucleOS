//
//  AIBriefingViewModelTests.swift
//  NucleOSTests/ViewModels
//
//  Swift Testing suite for AIBriefingViewModel — mock-only, zero real LLM calls.
//  All tests run on @MainActor to match AIBriefingViewModel's isolation.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("AI Briefing ViewModel")
@MainActor
struct AIBriefingViewModelTests {

    // MARK: - Initial state

    @Test("Initial state is .idle")
    func initialStateIsIdle() {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        if case .idle = vm.state {
            // Expected
        } else {
            Issue.record("Expected .idle, got \(vm.state)")
        }
    }

    @Test("lastUpdated is nil before any generation")
    func lastUpdatedIsNilInitially() {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        #expect(vm.lastUpdated == nil)
    }

    // MARK: - initialise

    @Test("initialise: sets .unavailable when provider is unavailable")
    func initialiseUnavailable() async {
        let vm = AIBriefingViewModel(service: MockAIBriefingService(hasAvailableProvider: false))
        await vm.initialise()
        if case .unavailable = vm.state {
            // Expected
        } else {
            Issue.record("Expected .unavailable, got \(vm.state)")
        }
    }

    @Test("initialise: stays .idle when available but auto-generate is off")
    func initialiseIdleWhenNotOptedIn() async {
        let defaults = UserDefaults.standard
        let hadPreviousValue = defaults.object(forKey: AIBriefingService.autoGenerateKey) != nil
        let previousValue = defaults.bool(forKey: AIBriefingService.autoGenerateKey)
        let previousCache = defaults.string(forKey: "nucleos.ai.briefing.cache")
        let previousTimestamp = defaults.object(forKey: "nucleos.ai.briefing.timestamp")

        defer {
            if hadPreviousValue {
                defaults.set(previousValue, forKey: AIBriefingService.autoGenerateKey)
            } else {
                defaults.removeObject(forKey: AIBriefingService.autoGenerateKey)
            }
            if let previousCache {
                defaults.set(previousCache, forKey: "nucleos.ai.briefing.cache")
            } else {
                defaults.removeObject(forKey: "nucleos.ai.briefing.cache")
            }
            if let previousTimestamp {
                defaults.set(previousTimestamp, forKey: "nucleos.ai.briefing.timestamp")
            } else {
                defaults.removeObject(forKey: "nucleos.ai.briefing.timestamp")
            }
        }

        defaults.set(false, forKey: AIBriefingService.autoGenerateKey)
        defaults.removeObject(forKey: "nucleos.ai.briefing.cache")
        defaults.removeObject(forKey: "nucleos.ai.briefing.timestamp")
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        await vm.initialise()
        if case .idle = vm.state {
            // Expected
        } else {
            Issue.record("Expected .idle, got \(vm.state)")
        }
    }

    // MARK: - generate

    @Test("generate: transitions through loading and ends in .loaded")
    func generateLoadsSuccessfully() async {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        await vm.generate()
        if case .loaded(let text) = vm.state {
            #expect(!text.isEmpty)
        } else {
            Issue.record("Expected .loaded, got \(vm.state)")
        }
    }

    @Test("generate: sets lastUpdated after success")
    func generateSetsLastUpdated() async {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        await vm.generate()
        #expect(vm.lastUpdated != nil)
    }

    @Test("generate: sets .unavailable when provider is unavailable")
    func generateUnavailableWhenNoProvider() async {
        let vm = AIBriefingViewModel(service: MockAIBriefingService(hasAvailableProvider: false))
        await vm.generate()
        if case .unavailable = vm.state {
            // Expected
        } else {
            Issue.record("Expected .unavailable, got \(vm.state)")
        }
    }

    @Test("generate: loaded text matches MockData.aiBriefing")
    func generateLoadedTextMatchesMockData() async {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        await vm.generate()
        if case .loaded(let text) = vm.state {
            #expect(text == MockData.aiBriefing)
        } else {
            Issue.record("Expected .loaded, got \(vm.state)")
        }
    }

    // MARK: - Health snapshot wiring

    @Test("healthSnapshot is nil by default")
    func healthSnapshotNilByDefault() {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        #expect(vm.healthSnapshot == nil)
    }

    @Test("healthSnapshot can be set")
    func healthSnapshotCanBeSet() {
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        vm.healthSnapshot = MockData.healthSnapshot
        #expect(vm.healthSnapshot != nil)
    }

    @Test("isHealthSummaryEnabled defaults to false")
    func isHealthSummaryEnabledDefaultsFalse() {
        let originalValue = UserDefaults.standard.object(forKey: AIBriefingService.healthSummaryEnabledKey)
        defer { UserDefaults.standard.set(originalValue, forKey: AIBriefingService.healthSummaryEnabledKey) }

        UserDefaults.standard.removeObject(forKey: AIBriefingService.healthSummaryEnabledKey)
        let vm = AIBriefingViewModel(service: MockAIBriefingService())
        #expect(!vm.isHealthSummaryEnabled)
    }

    @Test("generate succeeds with health snapshot set and health enabled")
    func generateSucceedsWithHealthSnapshot() async {
        UserDefaults.standard.set(true, forKey: AIBriefingService.healthSummaryEnabledKey)
        defer { UserDefaults.standard.removeObject(forKey: AIBriefingService.healthSummaryEnabledKey) }
        let vm = AIBriefingViewModel(service: MockAIBriefingService(), healthSnapshot: MockData.healthSnapshot)
        await vm.generate()
        if case .loaded(let text) = vm.state {
            #expect(!text.isEmpty)
        } else {
            Issue.record("Expected .loaded, got \(vm.state)")
        }
    }
}
