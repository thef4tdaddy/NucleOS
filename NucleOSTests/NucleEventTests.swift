//
//  NucleEventTests.swift
//  NucleOSTests
//
//  Tests for NucleEvent and EventColor changes in this PR:
//  - Hashable conformance removed from EventColor and NucleEvent
//  - EventColor.hexValue computed property
//  - EventColor Equatable conformance still present
//

import XCTest
@testable import NucleOS

final class NucleEventTests: XCTestCase {

    // MARK: - EventColor hexValue Tests

    func testAccentPrimaryHexValue() {
        XCTAssertEqual(EventColor.accentPrimary.hexValue, "5b3fd4")
    }

    func testAccentLightHexValue() {
        XCTAssertEqual(EventColor.accentLight.hexValue, "7c5cf0")
    }

    func testAccentLavenderHexValue() {
        XCTAssertEqual(EventColor.accentLavender.hexValue, "c4b5fd")
    }

    func testCustomHexValue() {
        XCTAssertEqual(EventColor.custom("ff6b6b").hexValue, "ff6b6b")
    }

    func testCustomHexValueEmptyString() {
        XCTAssertEqual(EventColor.custom("").hexValue, "")
    }

    func testCustomHexValueIsPassthrough() {
        let hex = "aabbcc"
        XCTAssertEqual(EventColor.custom(hex).hexValue, hex)
    }

    // MARK: - EventColor Equatable Tests

    func testAccentPrimaryEquality() {
        XCTAssertEqual(EventColor.accentPrimary, EventColor.accentPrimary)
    }

    func testAccentLightEquality() {
        XCTAssertEqual(EventColor.accentLight, EventColor.accentLight)
    }

    func testAccentLavenderEquality() {
        XCTAssertEqual(EventColor.accentLavender, EventColor.accentLavender)
    }

    func testCustomColorEqualityWithSameHex() {
        XCTAssertEqual(EventColor.custom("ff6b6b"), EventColor.custom("ff6b6b"))
    }

    func testCustomColorInequalityWithDifferentHex() {
        XCTAssertNotEqual(EventColor.custom("ff0000"), EventColor.custom("00ff00"))
    }

    func testDifferentCasesAreNotEqual() {
        XCTAssertNotEqual(EventColor.accentPrimary, EventColor.accentLight)
        XCTAssertNotEqual(EventColor.accentPrimary, EventColor.accentLavender)
        XCTAssertNotEqual(EventColor.accentLight, EventColor.accentLavender)
    }

    func testCustomColorNotEqualToThemeCases() {
        // custom hex that happens to match theme hex is still .custom, not .accentPrimary
        XCTAssertNotEqual(EventColor.custom("5b3fd4"), EventColor.accentPrimary)
    }

    // MARK: - NucleEvent Initializer Tests

    func testDefaultInitializerValues() {
        let start = Date()
        let end = Date(timeIntervalSinceNow: 3600)
        let event = NucleEvent(title: "Test Event", startDate: start, endDate: end)
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.startDate, start)
        XCTAssertEqual(event.endDate, end)
        XCTAssertEqual(event.calendarColor, .accentPrimary)
        XCTAssertFalse(event.isAllDay)
        XCTAssertNil(event.location)
    }

    func testInitializerWithAllParameters() {
        let id = UUID()
        let start = Date()
        let end = Date(timeIntervalSinceNow: 1800)
        let event = NucleEvent(
            id: id,
            title: "Full Event",
            startDate: start,
            endDate: end,
            calendarColor: .accentLavender,
            isAllDay: true,
            location: "Conference Room A"
        )
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.title, "Full Event")
        XCTAssertEqual(event.startDate, start)
        XCTAssertEqual(event.endDate, end)
        XCTAssertEqual(event.calendarColor, .accentLavender)
        XCTAssertTrue(event.isAllDay)
        XCTAssertEqual(event.location, "Conference Room A")
    }

    func testIsAllDayDefaultsFalse() {
        let event = NucleEvent(title: "E", startDate: Date(), endDate: Date())
        XCTAssertFalse(event.isAllDay)
    }

    func testLocationDefaultsNil() {
        let event = NucleEvent(title: "E", startDate: Date(), endDate: Date())
        XCTAssertNil(event.location)
    }

    func testCustomColorEventCreation() {
        let event = NucleEvent(
            title: "Custom Color Event",
            startDate: Date(),
            endDate: Date(timeIntervalSinceNow: 3600),
            calendarColor: .custom("ff6b6b")
        )
        XCTAssertEqual(event.calendarColor, .custom("ff6b6b"))
        XCTAssertEqual(event.calendarColor.hexValue, "ff6b6b")
    }

    // MARK: - NucleEvent Equatable Tests

    func testEventsWithSameIDAndFieldsAreEqual() {
        let id = UUID()
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 3600)
        let event1 = NucleEvent(id: id, title: "Event", startDate: start, endDate: end)
        let event2 = NucleEvent(id: id, title: "Event", startDate: start, endDate: end)
        XCTAssertEqual(event1, event2)
    }

    func testEventsWithDifferentIDsAreNotEqual() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 3600)
        let event1 = NucleEvent(title: "Event", startDate: start, endDate: end)
        let event2 = NucleEvent(title: "Event", startDate: start, endDate: end)
        XCTAssertNotEqual(event1, event2)
    }

    // MARK: - Mutable Fields Tests

    func testEventFieldsAreMutable() {
        var event = NucleEvent(title: "Original", startDate: Date(), endDate: Date())
        let newStart = Date(timeIntervalSinceNow: 3600)
        let newEnd = Date(timeIntervalSinceNow: 7200)
        event.title = "Modified"
        event.startDate = newStart
        event.endDate = newEnd
        event.calendarColor = .accentLight
        event.isAllDay = true
        event.location = "New Location"
        XCTAssertEqual(event.title, "Modified")
        XCTAssertEqual(event.startDate, newStart)
        XCTAssertEqual(event.endDate, newEnd)
        XCTAssertEqual(event.calendarColor, .accentLight)
        XCTAssertTrue(event.isAllDay)
        XCTAssertEqual(event.location, "New Location")
    }

    // MARK: - Identifiable Tests

    func testEventHasUniqueIDByDefault() {
        let e1 = NucleEvent(title: "E1", startDate: Date(), endDate: Date())
        let e2 = NucleEvent(title: "E2", startDate: Date(), endDate: Date())
        XCTAssertNotEqual(e1.id, e2.id)
    }
}