//
//  NaturalLanguageParserTests.swift
//  NucleOSTests
//
//  Swift Testing suite for natural language event parsing
//

import Testing
import Foundation
@testable import NucleOS

@Suite("Natural Language Parser")
struct NaturalLanguageParserTests {

    @Test("parses simple event with time")
    func parsesSimpleEventWithTime() {
        let result = NaturalLanguageParser.parse("Lunch at 12pm")

        #expect(result != nil)
        #expect(result?.title == "Lunch")
        #expect(result?.location == nil)
    }

    @Test("parses event with location")
    func parsesEventWithLocation() {
        let result = NaturalLanguageParser.parse("Meeting at Starbucks at 2pm")

        #expect(result != nil)
        #expect(result?.title == "Meeting")
        #expect(result?.location == "Starbucks")
    }

    @Test("parses event for tomorrow")
    func parsesEventForTomorrow() {
        let today = Date()
        let result = NaturalLanguageParser.parse("Dentist appointment tomorrow at 9am")

        #expect(result != nil)
        #expect(result?.title == "Dentist appointment")

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        #expect(calendar.isDate(result!.startDate, inSameDayAs: tomorrow))
    }

    @Test("parses time with am/pm")
    func parsesTimeWithAmPm() {
        let result = NaturalLanguageParser.parse("Call at 3:30pm")

        #expect(result != nil)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: result!.startDate)
        let minute = calendar.component(.minute, from: result!.startDate)

        #expect(hour == 15)
        #expect(minute == 30)
    }

    @Test("parses time without minutes")
    func parsesTimeWithoutMinutes() {
        let result = NaturalLanguageParser.parse("Meeting at 9am")

        #expect(result != nil)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: result!.startDate)
        let minute = calendar.component(.minute, from: result!.startDate)

        #expect(hour == 9)
        #expect(minute == 0)
    }

    @Test("returns nil for empty input")
    func returnsNilForEmptyInput() {
        let result = NaturalLanguageParser.parse("")

        #expect(result == nil)
    }

    @Test("returns nil for whitespace only")
    func returnsNilForWhitespaceOnly() {
        let result = NaturalLanguageParser.parse("   ")

        #expect(result == nil)
    }

    @Test("default duration is one hour")
    func defaultDurationIsOneHour() {
        let result = NaturalLanguageParser.parse("Event at 10am")

        #expect(result != nil)

        let duration = result!.endDate.timeIntervalSince(result!.startDate)
        #expect(duration == 3600)
    }

    @Test("title is capitalized")
    func titleIsCapitalized() {
        let result = NaturalLanguageParser.parse("lunch at 12pm")

        #expect(result != nil)
        #expect(result?.title == "Lunch")
    }
}