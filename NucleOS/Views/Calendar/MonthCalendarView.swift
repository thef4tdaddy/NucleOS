// MonthCalendarView.swift
import SwiftUI

/// A grid view representing a month calendar.
/// Shows a dot under days that have events.
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let events: [NucleEvent]
    @State private var displayedMonth: Date = Date()

    private var daysInMonth: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        // Start at first day of month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<1
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(date)
            }
        }
        return dates
    }

    private func hasEvents(on date: Date) -> Bool {
        let calendar = Calendar.current
        return events.contains(where: { calendar.isDate($0.startDate, inSameDayAs: date) })
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Button(action: jumpToToday) {
                    Text(monthYearString)
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .foregroundColor(.textPrimary)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \ .self) { date in
                    DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), hasEvent: hasEvents(on: date))
                        .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding()
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func changeMonth(by offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func jumpToToday() {
        displayedMonth = Date()
        selectedDate = Date()
    }
}

/// A single day cell used inside ``MonthCalendarView``.
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvent: Bool
    var body: some View {
        VStack {
            Text(dayNumber)
                .font(.subheadline)
                .foregroundColor(isSelected ? .accentPrimary : .textPrimary)
            if hasEvent {
                Circle()
                    .fill(Color.accentPrimary)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(isSelected ? Color.accentPrimary.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// Simple blur view for glassmorphism effect
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    MonthCalendarView(selectedDate: .constant(Date()), events: [])
}
