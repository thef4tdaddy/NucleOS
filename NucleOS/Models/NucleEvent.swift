//
//  NucleEvent.swift
//  NucleOS
//
//  Data model representing a calendar event sourced from EventKit
//

import Foundation

// MARK: - EventColor

/// Strongly typed color token for calendar events.
/// Use theme cases for events created inside the app; use `.custom` for colours
/// supplied by EventKit (e.g. from the user's own calendars).
enum EventColor: Hashable, Sendable, Equatable {
    /// Accent purple — matches `Color.accentPrimary` (#5b3fd4)
    case accentPrimary
    /// Light accent purple — matches `Color.accentLight` (#7c5cf0)
    case accentLight
    /// Lavender accent — matches `Color.accentLavender` (#c4b5fd)
    case accentLavender
    /// Arbitrary hex string for EventKit interop (e.g. user calendar colours)
    case custom(String)

    /// Hex string representation (without leading `#`).
    var hexValue: String {
        switch self {
        case .accentPrimary: return "5b3fd4"
        case .accentLight: return "7c5cf0"
        case .accentLavender: return "c4b5fd"
        case .custom(let hex): return hex
        }
    }
}

// MARK: - NucleEvent

/// A calendar event sourced from the user's Apple Calendar via EventKit.
struct NucleEvent: Identifiable, Equatable, Sendable {
    /// Stable identifier used to correlate events across reloads.
    let id: UUID
    /// EventKit unique identifier — used for update/delete operations.
    var eventIdentifier: String?
    /// The EKCalendar identifier this event belongs to.
    var calendarIdentifier: String?
    /// User-visible title of the event.
    var title: String
    /// The date and time the event begins.
    var startDate: Date
    /// The date and time the event ends.
    var endDate: Date
    /// The colour token of the source calendar.
    var calendarColor: EventColor
    /// Whether the event spans the entire day.
    var isAllDay: Bool
    /// Optional location string attached to the event.
    var location: String?
    /// Optional notes / description text.
    var notes: String?
    /// Optional URL associated with the event.
    var url: URL?
    /// Availability status (busy, free, tentative, unavailable).
    var availability: EventAvailability
    /// Event reminder offset in minutes before start (nil = no reminder).
    var reminderOffset: Int?
    /// Whether the user has declined this event invitation.
    var isDeclined: Bool

    static func == (lhs: NucleEvent, rhs: NucleEvent) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated init(
        id: UUID = UUID(),
        eventIdentifier: String? = nil,
        calendarIdentifier: String? = nil,
        title: String,
        startDate: Date,
        endDate: Date,
        calendarColor: EventColor = .accentPrimary,
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        availability: EventAvailability = .busy,
        reminderOffset: Int? = nil,
        isDeclined: Bool = false
    ) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarColor = calendarColor
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.availability = availability
        self.reminderOffset = reminderOffset
        self.isDeclined = isDeclined
    }
}

/// Availability status for calendar events.
enum EventAvailability: String, Sendable {
    case busy
    case free
    case tentative
    case unavailable
}
