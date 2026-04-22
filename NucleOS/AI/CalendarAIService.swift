//
//  CalendarAIService.swift
//  NucleOS
//
//  AI-powered calendar analysis and insights
//

import Foundation

/// Service that provides AI-powered calendar insights and suggestions.
@MainActor
class CalendarAIService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastInsight: String?
    @Published var error: String?

    private let provider: LLMProvider?
    private let calendarService: CalendarServiceProtocol

    init(
        provider: LLMProvider? = nil,
        calendarService: CalendarServiceProtocol? = nil
    ) {
        self.provider = provider
        self.calendarService = calendarService ?? CalendarService()
    }

    /// Generates a daily briefing of upcoming events with AI insights.
    func generateDailyBriefing(events: [NucleEvent]) async {
        guard let provider = provider, provider.isAvailable else {
            error = "No AI provider configured"
            return
        }

        guard !events.isEmpty else {
            lastInsight = "No events scheduled for the selected period."
            return
        }

        isAnalyzing = true
        error = nil

        let prompt = buildDailyBriefingPrompt(events: events)

        do {
            let insight = try await provider.complete(prompt: prompt)
            await MainActor.run {
                self.lastInsight = insight
                self.isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                self.error = "AI analysis failed: \(error.localizedDescription)"
                self.isAnalyzing = false
            }
        }
    }

    /// Suggests optimal meeting times based on existing events.
    func suggestMeetingTimes(
        events: [NucleEvent],
        duration: Int,
        preferredTimeOfDay: String? = nil
    ) async -> [Date] {
        guard let provider = provider, provider.isAvailable else {
            return []
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let prompt = buildMeetingSuggestionPrompt(
            events: events,
            duration: duration,
            preferredTimeOfDay: preferredTimeOfDay
        )

        do {
            let response = try await provider.complete(prompt: prompt)
            return parseSuggestedTimes(from: response)
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    /// Analyzes calendar patterns and provides productivity insights.
    func analyzePatterns(events: [NucleEvent]) async {
        guard let provider = provider, provider.isAvailable else {
            error = "No AI provider configured"
            return
        }

        guard events.count >= 3 else {
            lastInsight = "Schedule at least 3 events to see pattern analysis."
            return
        }

        isAnalyzing = true
        error = nil

        let prompt = buildPatternAnalysisPrompt(events: events)

        do {
            let insight = try await provider.complete(prompt: prompt)
            await MainActor.run {
                self.lastInsight = insight
                self.isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                self.error = "Pattern analysis failed: \(error.localizedDescription)"
                self.isAnalyzing = false
            }
        }
    }

    // MARK: - Private

    private func buildDailyBriefingPrompt(events: [NucleEvent]) -> String {
        let eventList = events.map { event in
            let time = event.isAllDay ? "All Day" : formatTime(event.startDate)
            return "- \(time): \(event.title)\(event.location.map { " (\($0))" } ?? "")"
        }.joined(separator: "\n")

        return """
        You are a helpful calendar assistant. Briefly summarize the following schedule \
        and provide 1-2 actionable insights or suggestions. Keep it concise (2-3 sentences max).

        Today's Events:
        \(eventList)

        Provide a brief, helpful summary:
        """
    }

    private func buildMeetingSuggestionPrompt(
        events: [NucleEvent],
        duration: Int,
        preferredTimeOfDay: String?
    ) -> String {
        let eventList = events.map { event in
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate))-\(formatter.string(from: event.endDate)): \(event.title)"
        }.joined(separator: "\n")

        let timePreference = preferredTimeOfDay.map { "Prefer \($0)." } ?? ""

        return """
        Based on these existing calendar events, suggest 3 best times for a \(duration)-minute meeting.
        \(timePreference)
        Return ONLY times in HH:MM format, one per line.

        Existing events:
        \(eventList)

        Suggested times:
        """
    }

    private func buildPatternAnalysisPrompt(events: [NucleEvent]) -> String {
        let weekdays = Dictionary(grouping: events) { Calendar.current.component(.weekday, from: $0.startDate) }
        let busyDays = weekdays.sorted { $0.value.count > $1.value.count }.prefix(3)
            .map { (day, count) -> String in
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                if let date = Calendar.current.date(from: DateComponents(weekday: day)) {
                    return "\(formatter.string(from: date)): \(count) events"
                }
                return "Day \(day): \(count) events"
            }.joined(separator: "\n")

        return """
        Analyze this calendar data and provide 2-3 concise productivity insights:
        - Busiest days: \(busyDays)
        - Total events: \(events.count)
        - Average events per day: \(events.count / 7)

        Provide brief insights about patterns and suggestions for improvement:
        """
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseSuggestedTimes(from response: String) -> [Date] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return response.components(separatedBy: .newlines)
            .compactMap { line -> Date? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                return formatter.date(from: trimmed)
            }
    }
}

// MARK: - SettingsViewModel Extension

private extension SettingsViewModel {
    var selectedCalendarProvider: CalendarServiceProtocol {
        if AppSettings().useMockCalendarData {
            return MockCalendarService()
        }
        return CalendarService()
    }
}