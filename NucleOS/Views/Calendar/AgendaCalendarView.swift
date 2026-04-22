//
//  AgendaCalendarView.swift
//  NucleOS
//
//  Agenda view showing all upcoming events in chronological list
//

import SwiftUI

/// Agenda view showing all upcoming events in a chronological list with time markers.
struct AgendaCalendarView: View {
    let events: [NucleEvent]
    @State private var searchText = ""

    private let calendar = Calendar.current

    var filteredEvents: [NucleEvent] {
        if searchText.isEmpty {
            return events.sorted { $0.startDate < $1.startDate }
        } else {
            return events.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                (event.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            .sorted { $0.startDate < $1.startDate }
        }
    }

    var groupedEvents: [(key: Date, value: [NucleEvent])] {
        let grouped = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textMuted)
                    .padding(.leading, 8)

                TextField("Search events...", text: $searchText)
                    .textFieldStyle(.plain)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundCard)
            )
            .padding(.horizontal, 32)
            .padding(.top, 24)

            // Event list
            if filteredEvents.isEmpty {
                EmptyStateView(message: "No events found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                        ForEach(groupedEvents, id: \.key) { day, dayEvents in
                            Section(header: AgendaSectionHeader(date: day, count: dayEvents.count)) {
                                VStack(spacing: 8) {
                                    ForEach(dayEvents, id: \.id) { event in
                                        AgendaEventRow(event: event)
                                    }
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Color.backgroundPrimary)
    }
}

struct AgendaSectionHeader: View {
    let date: Date
    let count: Int

    private let calendar = Calendar.current

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(dateLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Text("\(count) \(count == 1 ? "event" : "events")")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
        .background(Color.backgroundPrimary)
    }

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

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AgendaEventRow: View {
    let event: NucleEvent
    @State private var isSelected = false

    var body: some View {
        HStack(spacing: 16) {
            // Time column
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(event.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)

                if !event.isAllDay {
                    Text(formatTime(event.endDate))
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }
            .frame(width: 60, alignment: .leading)

            // Color indicator
            Rectangle()
                .fill(colorFromEventColor(event.calendarColor))
                .frame(width: 4, height: 60)
                .cornerRadius(2)

            // Event content
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)

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

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
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
        .onTapGesture {
            isSelected.toggle()
        }
    }

    private func formatTime(_ date: Date) -> String {
        if event.isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

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
    AgendaCalendarView(events: MockData.events)
}