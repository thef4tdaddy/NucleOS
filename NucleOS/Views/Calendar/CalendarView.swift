//
//  CalendarView.swift
//  NucleOS
//
//  Full calendar view with read-only events from EventKit
//

import SwiftUI

/// Full-page view that displays upcoming calendar events, grouped by day.
struct CalendarView: View {
    @State private var events: [NucleEvent] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedDays = 7
    @State private var loadTask: Task<Void, Never>?
    @State private var showingMockData = false

    private let calendarService = CalendarService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    if !events.isEmpty {
                        Text("\(events.count) events in the next \(selectedDays) days")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(.accentPrimary)
                }

                Menu(content: {
                    Button(action: {
                        selectedDays = 1
                        startLoadEvents()
                    }, label: {
                        Text("Today")
                    })

                    Button(action: {
                        selectedDays = 7
                        startLoadEvents()
                    }, label: {
                        Text("Next 7 Days")
                    })

                    Button(action: {
                        selectedDays = 30
                        startLoadEvents()
                    }, label: {
                        Text("Next 30 Days")
                    })
                }, label: {
                    HStack(spacing: 6) {
                        Text("\(selectedDays) \(selectedDays == 1 ? "Day" : "Days")")
                            .font(.system(size: 13, weight: .medium))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.accentPrimary)
                })
                .disabled(isLoading)
                .accessibilityLabel("Select day range")

                Button(action: { startLoadEvents() }, label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Refresh events")
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()
                .background(Color.border)

            // Content
            if let error = error {
                ErrorStateView(message: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty && !isLoading {
                EmptyStateView(message: "No events scheduled")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(content: {
                    VStack(spacing: 24) {
                        ForEach(groupedEventsByDay, id: \.key, content: { day, dayEvents in
                            DayEventsSection(date: day, events: dayEvents)
                        })
                    }
                    .padding(.vertical, 24)
                })
            }
        }
        .background(Color.backgroundPrimary)
        .task(priority: .userInitiated) {
            await loadEvents()
        }
    }

    /// Events sorted and grouped by calendar day (start-of-day key).
    private var groupedEventsByDay: [(key: Date, value: [NucleEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    /// Cancels any in-flight load and starts a fresh one to prevent races.
    private func startLoadEvents() {
        // Cancel any in-flight task to prevent races
        loadTask?.cancel()
        loadTask = Task {
            await loadEvents()
        }
    }

    /// Fetches events for the selected day range; falls back to mock data if permission is denied.
    private func loadEvents() async {
        isLoading = true
        error = nil
        showingMockData = false

        do {
            if selectedDays == 1 {
                events = try await calendarService.fetchTodayEvents()
            } else {
                events = try await calendarService.fetchUpcomingEvents(days: selectedDays)
            }
        } catch CalendarServiceError.permissionDenied {
            // Show mock data with clear indication
            showingMockData = true
            do {
                if selectedDays == 1 {
                    events = try await MockCalendarService().fetchTodayEvents()
                } else {
                    events = try await MockCalendarService().fetchUpcomingEvents(days: selectedDays)
                }
                self.error = "Showing sample data. Grant Calendar access in System Settings to see your events."
            } catch {
                self.error = "Calendar permission denied: \(error.localizedDescription)"
                events = []
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
        loadTask = nil
    }
}

/// A labelled group of ``EventCardView`` rows for a single calendar day.
struct DayEventsSection: View {
    /// The calendar day this section represents (start-of-day).
    let date: Date
    /// Events occurring on this day.
    let events: [NucleEvent]

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text(dateLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                Text("\(events.count) \(events.count == 1 ? "event" : "events")")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 32)

            // Events
            VStack(spacing: 8) {
                ForEach(events.sorted { $0.startDate < $1.startDate }, content: { event in
                    EventCardView(event: event)
                })
            }
            .padding(.horizontal, 32)
        }
    }

    /// "Today", "Tomorrow", or the full weekday name for other dates.
    private var dayLabel: String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    /// Medium-style date string (e.g. "Apr 17, 2026").
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// A full-width card showing a single event's title, time range, and optional location.
struct EventCardView: View {
    /// The event to display.
    let event: NucleEvent

    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            Rectangle()
                .fill(colorFromEventColor(event.calendarColor))
                .frame(width: 4, height: 60)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)

                // Time and Location
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))

                        Text(formatTimeRange(event.startDate, end: event.endDate, isAllDay: event.isAllDay))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.textMuted)

                    if let location = event.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location")
                                .font(.system(size: 11))

                            Text(location)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
    }

    /// Returns `"All Day"` or a short `"HH:mm – HH:mm"` string.
    private func formatTimeRange(_ start: Date, end: Date, isAllDay: Bool) -> String {
        if isAllDay {
            return "All Day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    /// Maps an ``EventColor`` token to a SwiftUI `Color`.
    private func colorFromEventColor(_ eventColor: EventColor) -> Color {
        switch eventColor {
        case .accentPrimary:
            return .accentPrimary
        case .accentLight:
            return .accentLight
        case .accentLavender:
            return .accentLavender
        case .custom(let hex):
            return Color(hex: hex)
        }
    }
}

#Preview {
    CalendarView()
}
