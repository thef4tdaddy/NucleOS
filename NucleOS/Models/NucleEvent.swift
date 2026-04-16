//
//  NucleEvent.swift
//  NucleOS
//
//  Data model representing a calendar event sourced from EventKit
//

import Foundation

struct NucleEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var calendarColor: String
    var isAllDay: Bool
    var location: String?

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        calendarColor: String = "5b3fd4",
        isAllDay: Bool = false,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarColor = calendarColor
        self.isAllDay = isAllDay
        self.location = location
    }
}
