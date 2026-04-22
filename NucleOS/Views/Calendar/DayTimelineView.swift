//
//  DayTimelineView.swift
//  NucleOS
//
//  Timeline view showing events for a specific day
//

import SwiftUI

/// Timeline view showing events for a specific day in chronological order.
struct DayTimelineView: View {
    let date: Date
    let events: [NucleEvent]
    @State private var selectedEvent: NucleEvent?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(dayHeader)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)
                .disabled(true) // Disabled until add functionality is implemented
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Timeline
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(events.sorted { $0.startDate < $1.startDate }, id: \.id) { event in
                        EventTimelineCard(event: event)
                            .onTapGesture {
                                selectedEvent = event
                            }
                    }

                    if events.isEmpty {
                        EmptyStateView(message: "No events today")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundPrimary)
        .sheet(item: $selectedEvent) { event in
            EventFormView(event: event, isPresented: $selectedEvent)
        }
    }

    private var dayHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

/// A card showing a single event in timeline format with time indicator.
struct EventTimelineCard: View {
    let event: NucleEvent

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time indicator
            VStack(spacing: 4) {
                Text(formatTime(event.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)

                if !event.isAllDay {
                    Rectangle()
                        .fill(Color.border)
                        .frame(width: 2, height: 40)
                        .overlay(
                            Circle()
                                .fill(Color.accentPrimary)
                                .frame(width: 8, height: 8)
                        )
                }
            }

            // Event content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    if let location = event.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                            Text(location)
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                        }
                    }
                }

                HStack {
                    Text(event.isAllDay ? "All Day" : formatTimeRange(event.startDate, event.endDate))
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)

                    Spacer()

                    // Color indicator
                    Rectangle()
                        .fill(colorFromEventColor(event.calendarColor))
                        .frame(width: 20, height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
            )
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatTimeRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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