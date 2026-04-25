// MonthCalendarView.swift
import SwiftUI

/// A month grid calendar. Tapping a day selects it; event pills (up to 3) appear under the day number.
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let events: [NucleEvent]
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current

    // Weekday letter headers Sun–Sat
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
    }

    /// Dates in the month plus leading blanks to align to Sunday.
    private var gridDates: [Date?] {
        let startWeekday = calendar.component(.weekday, from: monthStart) - 1 // 0 = Sunday
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<1
        var dates: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in range {
            dates.append(calendar.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        return dates
    }

    private func eventsOn(_ date: Date) -> [NucleEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func eventColor(_ event: NucleEvent) -> Color {
        switch event.calendarColor {
        case .accentPrimary:  return .accentPrimary
        case .accentLight:    return .accentLight
        case .accentLavender: return .accentLavender
        case .custom(let h):  return Color(hex: h)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: jumpToToday) {
                    Text(monthYearString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(gridDates.indices, id: \.self) { i in
                    if let date = gridDates[i] {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            events: eventsOn(date),
                            eventColorFn: eventColor
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(minHeight: 52)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
        )
    }

    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private func changeMonth(by offset: Int) {
        if let d = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = d
        }
    }

    private func jumpToToday() {
        displayedMonth = Date()
        selectedDate = Date()
    }
}

/// A single day cell with day number and up to 3 event pills.
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let events: [NucleEvent]
    let eventColorFn: (NucleEvent) -> Color

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 3) {
            // Day number
            Text(dayNumber)
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : isToday ? .accentPrimary : .textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentPrimary : Color.clear)
                )

            // Event pills — up to 3, then "+N more"
            VStack(spacing: 2) {
                ForEach(events.prefix(2), id: \.id) { event in
                    Text(event.title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(eventColorFn(event).opacity(0.3))
                        .cornerRadius(3)
                }

                if events.count > 2 {
                    Text("+\(events.count - 2) more")
                        .font(.system(size: 9))
                        .foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .frame(minHeight: 56, alignment: .top)
        .background(isSelected ? Color.accentPrimary.opacity(0.12) : Color.clear)
        .cornerRadius(6)
    }
}

#Preview {
    MonthCalendarView(selectedDate: .constant(Date()), events: MockData.events)
        .frame(width: 600)
        .background(Color.backgroundPrimary)
}
