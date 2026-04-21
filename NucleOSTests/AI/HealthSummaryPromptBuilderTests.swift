//
//  HealthSummaryPromptBuilderTests.swift
//  NucleOSTests/AI
//
//  Swift Testing suite for DefaultHealthSummaryPromptBuilder and MockHealthSummaryPromptBuilder.
//  Zero real HealthKit calls — all tests use HealthSnapshot directly.
//

import Foundation
import Testing
@testable import NucleOS

@Suite("Health Summary Prompt Builder")
struct HealthSummaryPromptBuilderTests {

    // MARK: - DefaultHealthSummaryPromptBuilder — build(from:)

    @Test("build returns a non-empty string")
    func buildReturnsNonEmpty() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.isEmpty)
    }

    @Test("build includes steps count")
    func buildIncludesSteps() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 8_234, stepGoal: 10_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(prompt.contains("8234"))
    }

    @Test("build includes step goal")
    func buildIncludesStepGoal() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 5_000, stepGoal: 12_000, heartRate: 72, sleepDuration: 0, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(prompt.contains("12000"))
    }

    @Test("build includes average heart rate when non-zero")
    func buildIncludesHeartRate() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 65, sleepDuration: 0, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(prompt.contains("65"))
        #expect(prompt.contains("bpm"))
    }

    @Test("build omits heart rate when zero")
    func buildOmitsHeartRateWhenZero() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 0, sleepDuration: 0, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(!prompt.contains("bpm"))
    }

    @Test("build includes sleep duration formatted")
    func buildIncludesSleepFormatted() {
        let builder = DefaultHealthSummaryPromptBuilder()
        // 7 hours 23 minutes of sleep
        let sleepDuration: TimeInterval = (7 * 60 + 23) * 60
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 0, sleepDuration: sleepDuration, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(prompt.contains("7h"))
    }

    @Test("build includes active calories when non-zero")
    func buildIncludesActiveCalories() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 0, sleepDuration: 0, activeCalories: 500)
        let prompt = builder.build(from: snapshot)
        #expect(prompt.contains("500"))
    }

    @Test("build omits active calories when zero")
    func buildOmitsCaloriesWhenZero() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let snapshot = HealthSnapshot(steps: 0, stepGoal: 10_000, heartRate: 0, sleepDuration: 0, activeCalories: 0)
        let prompt = builder.build(from: snapshot)
        #expect(!prompt.contains("Active calories:"))
    }

    // MARK: - Privacy rules

    @Test("build does not contain raw HK identifiers")
    func buildContainsNoHKIdentifiers() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        // Raw HealthKit type names must never appear in prompts
        #expect(!prompt.contains("HKQuantityType"))
        #expect(!prompt.contains("HKSample"))
        #expect(!prompt.contains("HKCategorySample"))
        #expect(!prompt.contains("HKQuantitySample"))
    }

    @Test("build does not contain HRV or SpO2 language")
    func buildContainsNoHRVOrSpO2() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.localizedCaseInsensitiveContains("HRV"))
        #expect(!prompt.localizedCaseInsensitiveContains("variability"))
        #expect(!prompt.localizedCaseInsensitiveContains("SpO"))
        #expect(!prompt.localizedCaseInsensitiveContains("oxygen"))
    }

    @Test("build does not contain population-comparison language")
    func buildContainsNoPopulationComparisons() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.localizedCaseInsensitiveContains("for your age"))
        #expect(!prompt.localizedCaseInsensitiveContains("below average"))
        #expect(!prompt.localizedCaseInsensitiveContains("higher than typical"))
    }

    @Test("build does not contain medical trend language")
    func buildContainsNoMedicalTrendLanguage() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.localizedCaseInsensitiveContains("declining"))
        #expect(!prompt.localizedCaseInsensitiveContains("worsening"))
        #expect(!prompt.localizedCaseInsensitiveContains("abnormal"))
    }

    @Test("build contains framing instruction (observations only)")
    func buildContainsFramingInstruction() {
        let builder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        // Must instruct provider to make observations, not give advice
        #expect(prompt.localizedCaseInsensitiveContains("observations only") ||
                prompt.localizedCaseInsensitiveContains("never give advice"))
    }

    // MARK: - Protocol conformance

    @Test("DefaultHealthSummaryPromptBuilder conforms to HealthSummaryPromptBuilder")
    func conformsToProtocol() {
        let builder: any HealthSummaryPromptBuilder = DefaultHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.isEmpty)
    }

    // MARK: - MockHealthSummaryPromptBuilder

    @Test("MockHealthSummaryPromptBuilder returns hardcoded prompt")
    func mockReturnsHardcodedPrompt() {
        let builder = MockHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(prompt == MockHealthSummaryPromptBuilder.hardcodedPrompt)
    }

    @Test("MockHealthSummaryPromptBuilder hardcodedPrompt is non-empty")
    func mockHardcodedPromptNonEmpty() {
        #expect(!MockHealthSummaryPromptBuilder.hardcodedPrompt.isEmpty)
    }

    @Test("MockHealthSummaryPromptBuilder conforms to HealthSummaryPromptBuilder")
    func mockConformsToProtocol() {
        let builder: any HealthSummaryPromptBuilder = MockHealthSummaryPromptBuilder()
        let prompt = builder.build(from: MockData.healthSnapshot)
        #expect(!prompt.isEmpty)
    }

    // MARK: - AIBriefingService health wiring

    @Test("AIBriefingService.generate with health snapshot includes prompt builder output")
    func serviceIncludesHealthContextWhenSnapshotProvided() async throws {
        // Use a spy builder that records whether build(from:) was called
        let spyBuilder = SpyHealthSummaryPromptBuilder()
        let provider = MockLLMProvider()
        let service = AIBriefingService(provider: provider, promptBuilder: spyBuilder)
        _ = try await service.generate(healthSnapshot: MockData.healthSnapshot)
        #expect(spyBuilder.buildCallCount == 1)
    }

    @Test("AIBriefingService.generate without snapshot skips prompt builder")
    func serviceSkipsBuilderWhenNoSnapshot() async throws {
        let spyBuilder = SpyHealthSummaryPromptBuilder()
        let provider = MockLLMProvider()
        let service = AIBriefingService(provider: provider, promptBuilder: spyBuilder)
        _ = try await service.generate(healthSnapshot: nil)
        #expect(spyBuilder.buildCallCount == 0)
    }

    @Test("AIBriefingService.healthSummaryEnabledKey is non-empty")
    func healthSummaryEnabledKeyIsNonEmpty() {
        #expect(!AIBriefingService.healthSummaryEnabledKey.isEmpty)
    }
}

// MARK: - Spy Builder (test helper)

/// A `HealthSummaryPromptBuilder` that records how many times `build(from:)` is called.
///
/// Used to verify whether the `AIBriefingService` correctly calls the builder
/// when a snapshot is provided, and correctly skips it when no snapshot is given.
final class SpyHealthSummaryPromptBuilder: HealthSummaryPromptBuilder {
    private(set) var buildCallCount = 0

    func build(from snapshot: HealthSnapshot) -> String {
        buildCallCount += 1
        return MockHealthSummaryPromptBuilder.hardcodedPrompt
    }
}
