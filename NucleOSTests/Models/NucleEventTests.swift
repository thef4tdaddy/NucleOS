//
//  NucleEventTests.swift
//  NucleOSTests
//
//  Swift Testing suite for NucleEvent model including tier 2 fields
//

import Testing
import Foundation
@testable import NucleOS

@Suite("NucleEvent Model")
struct NucleEventTests {

    @Test("default initialization sets correct defaults")
    func defaultInitialization() {
        let event = NucleEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )

        #expect(event.title == "Test Event")
        #expect(event.calendarColor == .accentPrimary)
        #expect(event.isAllDay == false)
        #expect(event.location == nil)
        #expect(event.notes == nil)
        #expect(event.url == nil)
        #expect(event.availability == .busy)
        #expect(event.reminderOffset == nil)
        #expect(event.isDeclined == false)
    }

    @Test("full initialization with all tier 2 fields")
    func fullInitialization() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7200)
        let url = URL(string: "https://example.com")!

        let event = NucleEvent(
            title: "Full Event",
            startDate: startDate,
            endDate: endDate,
            calendarColor: .accentLavender,
            isAllDay: true,
            location: "Conference Room",
            notes: "Important meeting notes",
            url: url,
            availability: .tentative,
            reminderOffset: 15,
            isDeclined: true
        )

        #expect(event.title == "Full Event")
        #expect(event.calendarColor == .accentLavender)
        #expect(event.isAllDay == true)
        #expect(event.location == "Conference Room")
        #expect(event.notes == "Important meeting notes")
        #expect(event.url == url)
        #expect(event.availability == .tentative)
        #expect(event.reminderOffset == 15)
        #expect(event.isDeclined == true)
    }

    @Test("equality with same id")
    func equalitySameId() {
        let id = UUID()
        let event1 = NucleEvent(
            id: id,
            title: "Event",
            startDate: Date(),
            endDate: Date()
        )
        let event2 = NucleEvent(
            id: id,
            title: "Different Title",
            startDate: Date().addingTimeInterval(1000),
            endDate: Date().addingTimeInterval(2000)
        )

        #expect(event1 == event2)
    }

    @Test("inequality with different id")
    func inequalityDifferentId() {
        let event1 = NucleEvent(title: "Event", startDate: Date(), endDate: Date())
        let event2 = NucleEvent(title: "Event", startDate: Date(), endDate: Date())

        #expect(event1 != event2)
    }

    @Test("availability enum raw values")
    func availabilityRawValues() {
        #expect(EventAvailability.busy.rawValue == "busy")
        #expect(EventAvailability.free.rawValue == "free")
        #expect(EventAvailability.tentative.rawValue == "tentative")
        #expect(EventAvailability.unavailable.rawValue == "unavailable")
    }

    @Test("event color hex values")
    func eventColorHexValues() {
        #expect(EventColor.accentPrimary.hexValue == "5b3fd4")
        #expect(EventColor.accentLight.hexValue == "7c5cf0")
        #expect(EventColor.accentLavender.hexValue == "c4b5fd")
        #expect(EventColor.custom("ff0000").hexValue == "ff0000")
    }

    @Test("sendable conformance compiles")
    func sendableConformance() {
        let event = NucleEvent(title: "Sendable Test", startDate: Date(), endDate: Date())
        let _ = event as Sendable
    }
}