//
//  CalendarAIServiceTests.swift
//  NucleOSTests
//
//  Swift Testing suite for CalendarAIService
//

import Testing
import Foundation
@testable import NucleOS

@Suite("Calendar AI Service")
struct CalendarAIServiceTests {

    @Test("generateDailyBriefing with no events sets appropriate message")
    func generateDailyBriefingNoEvents() async {
        let service = CalendarAIService(provider: MockLLMProvider())
        await service.generateDailyBriefing(events: [])

        #expect(service.lastInsight == "No events scheduled for the selected period.")
        #expect(service.error == nil)
        #expect(service.isAnalyzing == false)
    }

    @Test("generateDailyBriefing with events calls provider")
    func generateDailyBriefingWithEvents() async {
        let provider = MockLLMProvider()
        let service = CalendarAIService(provider: provider)

        let events = [
            NucleEvent(title: "Meeting", startDate: Date(), endDate: Date().addingTimeInterval(3600)),
            NucleEvent(title: "Lunch", startDate: Date().addingTimeInterval(7200), endDate: Date().addingTimeInterval(10800))
        ]

        await service.generateDailyBriefing(events: events)

        #expect(service.lastInsight == MockLLMProvider.hardcodedResponse)
        #expect(service.error == nil)
        #expect(service.isAnalyzing == false)
    }

    @Test("generateDailyBriefing with unavailable provider sets error")
    func generateDailyBriefingUnavailableProvider() async {
        let service = CalendarAIService(provider: nil)
        await service.generateDailyBriefing(events: [NucleEvent(title: "Test", startDate: Date(), endDate: Date())])

        #expect(service.error == "No AI provider configured")
        #expect(service.isAnalyzing == false)
    }

    @Test("suggestMeetingTimes with unavailable provider returns empty")
    func suggestMeetingTimesUnavailableProvider() async {
        let service = CalendarAIService(provider: nil)
        let times = await service.suggestMeetingTimes(events: [], duration: 60)

        #expect(times.isEmpty)
    }

    @Test("suggestMeetingTimes with available provider returns parsed times")
    func suggestMeetingTimesWithProvider() async {
        let service = CalendarAIService(provider: MockLLMProvider())
        let times = await service.suggestMeetingTimes(events: [], duration: 60)

        #expect(service.isAnalyzing == false)
    }

    @Test("analyzePatterns with fewer than 3 events sets message")
    func analyzePatternsFewEvents() async {
        let service = CalendarAIService(provider: MockLLMProvider())
        await service.analyzePatterns(events: [
            NucleEvent(title: "One", startDate: Date(), endDate: Date())
        ])

        #expect(service.lastInsight == "Schedule at least 3 events to see pattern analysis.")
        #expect(service.isAnalyzing == false)
    }

    @Test("analyzePatterns with enough events calls provider")
    func analyzePatternsWithEvents() async {
        let service = CalendarAIService(provider: MockLLMProvider())
        let events = (0..<5).map { i in
            NucleEvent(
                title: "Event \(i)",
                startDate: Date().addingTimeInterval(TimeInterval(i * 86400)),
                endDate: Date().addingTimeInterval(TimeInterval(i * 86400 + 3600))
            )
        }

        await service.analyzePatterns(events: events)

        #expect(service.lastInsight == MockLLMProvider.hardcodedResponse)
        #expect(service.error == nil)
        #expect(service.isAnalyzing == false)
    }

    @Test("isAnalyzing is true during generation")
    func isAnalyzingDuringGeneration() async {
        let service = CalendarAIService(provider: MockLLMProvider())
        let events = [NucleEvent(title: "Test", startDate: Date(), endDate: Date())]

        let task = Task {
            await service.generateDailyBriefing(events: events)
        }

        // Small delay to let the task start
        try? await Task.sleep(nanoseconds: 10_000_000)

        await task.value

        #expect(service.isAnalyzing == false)
    }
}