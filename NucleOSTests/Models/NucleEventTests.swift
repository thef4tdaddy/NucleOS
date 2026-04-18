//
//  NucleEventTests.swift
//  NucleOSTests/Models
//
//  Swift Testing suite for the NucleEvent model.
//

import Testing
@testable import NucleOS

@Suite("NucleEvent Model")
struct NucleEventModelTests {

    // MARK: - Identifiable

    @Test("NucleEvent conforms to Identifiable with UUID id")
    func identifiableConformance() {
        let event = NucleEvent(title: "Test", startDate: Date(), endDate: Date())
        #expect(event.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("Two events created independently have different ids")
    func twoEventsHaveDifferentIDs() {
        let e1 = NucleEvent(title: "A", startDate: Date(), endDate: Date())
        let e2 = NucleEvent(title: "B", startDate: Date(), endDate: Date())
        #expect(e1.id != e2.id)
    }

    // MARK: - startDate before endDate

    @Test("startDate is before or equal to endDate")
    func startDateBeforeEndDate() {
        let start = Date()
        let end = Date(timeIntervalSinceNow: 3600)
        let event = NucleEvent(title: "E", startDate: start, endDate: end)
        #expect(event.startDate <= event.endDate)
    }

    @Test("startDate == endDate is valid for zero-duration events")
    func zeroDurationEventValid() {
        let now = Date()
        let event = NucleEvent(title: "Zero Duration", startDate: now, endDate: now)
        #expect(event.startDate == event.endDate)
    }

    // MARK: - Duration calculable

    @Test("Duration is calculable from startDate and endDate")
    func durationCalculable() {
        let start = Date()
        let end = Date(timeIntervalSinceNow: 3600)
        let event = NucleEvent(title: "One Hour", startDate: start, endDate: end)
        let duration = event.endDate.timeIntervalSince(event.startDate)
        #expect(duration == 3600.0)
    }

    @Test("Duration of 90-minute event is 5400 seconds")
    func ninetyMinuteDuration() {
        let start = Date()
        let end = Date(timeIntervalSinceNow: 5400)
        let event = NucleEvent(title: "Standup", startDate: start, endDate: end)
        let duration = event.endDate.timeIntervalSince(event.startDate)
        #expect(duration == 5400.0)
    }

    // MARK: - Default values

    @Test("Default calendarColor is .accentPrimary")
    func defaultCalendarColor() {
        let event = NucleEvent(title: "E", startDate: Date(), endDate: Date())
        #expect(event.calendarColor == .accentPrimary)
    }

    @Test("Default isAllDay is false")
    func defaultIsAllDayFalse() {
        let event = NucleEvent(title: "E", startDate: Date(), endDate: Date())
        #expect(event.isAllDay == false)
    }

    @Test("Default location is nil")
    func defaultLocationNil() {
        let event = NucleEvent(title: "E", startDate: Date(), endDate: Date())
        #expect(event.location == nil)
    }

    // MARK: - Equatable

    @Test("Events with same id and fields are equal")
    func sameIDEventsAreEqual() {
        let id = UUID()
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 3600)
        let e1 = NucleEvent(id: id, title: "Event", startDate: start, endDate: end)
        let e2 = NucleEvent(id: id, title: "Event", startDate: start, endDate: end)
        #expect(e1 == e2)
    }

    @Test("Events with different ids are not equal")
    func differentIDEventsAreNotEqual() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let end = Date(timeIntervalSinceReferenceDate: 3600)
        let e1 = NucleEvent(title: "Event", startDate: start, endDate: end)
        let e2 = NucleEvent(title: "Event", startDate: start, endDate: end)
        #expect(e1 != e2)
    }

    // MARK: - EventColor

    @Test("EventColor.accentPrimary hexValue is 5b3fd4")
    func accentPrimaryHex() {
        #expect(EventColor.accentPrimary.hexValue == "5b3fd4")
    }

    @Test("EventColor.accentLight hexValue is 7c5cf0")
    func accentLightHex() {
        #expect(EventColor.accentLight.hexValue == "7c5cf0")
    }

    @Test("EventColor.accentLavender hexValue is c4b5fd")
    func accentLavenderHex() {
        #expect(EventColor.accentLavender.hexValue == "c4b5fd")
    }

    @Test("EventColor.custom passes through its hex string")
    func customColorPassthrough() {
        #expect(EventColor.custom("ff6b6b").hexValue == "ff6b6b")
    }
}
