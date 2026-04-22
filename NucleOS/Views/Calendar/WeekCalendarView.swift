//
//  WeekCalendarView.swift
//  NucleOS
//
//  Week view for calendar showing 7 days with horizontal scrolling
//

import SwiftUI

/// Horizontal week view calendar showing events for each day.
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let events: [NucleEvent]
    @State private var displayedWeek: Date = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private var weekDates: [Date] {
        var dates: [Date] = []
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: displayedWeek)) else { return [] }

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                dates.append(date)
            }
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(weekHeaderString)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            // Days header
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.textMuted)

                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .accentPrimary : .textPrimary)
                            .frame(width: 36, height: 36)
                            .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.accentPrimary.opacity(0.2) : Color.clear)
                            .cornerRadius(18)
                            .onTapGesture {
                                selectedDate = date
                            }

                        if hasEvents(on: date) {
                            Circle()
                                .fill(Color.accentPrimary)
                                .frame(width: 6, height: 6)
                        } else {
                            Color.clear.frame(height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Events per day
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: 8) {
                            ForEach(eventsForDate(date), id: \.id) { event in
                                EventWeekCard(event: event)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.backgroundPrimary)
    }

    private var weekHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedWeek)
    }

    private func changeWeek(by offset: Int) {
        if let newWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: displayedWeek) {
            displayedWeek = newWeek
        }
    }

    private func hasEvents(on date: Date) -> Bool {
        events.contains { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    private func eventsForDate(_ date: Date) -> [NucleEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }
}

/// Compact event card for week view.
struct EventWeekCard: View {
    let event: NucleEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textPrimary)
                .lineLimit(2)

            Text(formatTime(event.startDate))
                .font(.system(size: 10))
                .foregroundColor(.textMuted)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorFromEventColor(event.calendarColor).opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorFromEventColor(event.calendarColor), lineWidth: 1)
        )
    }

    private func formatTime(_ date: Date) -> String {
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
    WeekCalendarView(selectedDate: .constant(Date()), events: MockData.events)
}