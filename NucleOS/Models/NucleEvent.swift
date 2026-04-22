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

    /// Creates a new `NucleEvent`.
    /// - Parameters:
    ///   - id: Stable identifier; defaults to a new `UUID`.
    ///   - title: User-visible event title.
    ///   - startDate: Event start date/time.
    ///   - endDate: Event end date/time.
    ///   - calendarColor: Color token of the source calendar. Defaults to `.accentPrimary`.
    ///   - isAllDay: Whether the event spans the full day. Defaults to `false`.
    ///   - location: Optional location string.
    nonisolated init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        calendarColor: EventColor = .accentPrimary,
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
