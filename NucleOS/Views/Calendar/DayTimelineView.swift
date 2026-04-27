//
//  DayTimelineView.swift
//  NucleOS
//
//  Proper scrollable hour-based timeline for the day view.
//  Events are positioned as colored blocks proportional to their duration.
//

import SwiftUI
import Combine

/// Vertical scrollable timeline showing a single day's events on an hour grid.
struct DayTimelineView: View {
    let date: Date
    let events: [NucleEvent]
    var onEditEvent: ((NucleEvent) -> Void)? = nil

    @State private var currentTime = Date()
    @State private var selectedEvent: NucleEvent?

    // 60pt per hour keeps events readable
    private let hourHeight: CGFloat = 60
    // Width reserved for the "9 AM" labels
    private let labelWidth: CGFloat = 52

    private let calendar = Calendar.current
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var allDayEvents: [NucleEvent] { events.filter(\.isAllDay) }
    private var timedEvents: [NucleEvent] { events.filter { !$0.isAllDay } }
    private var isToday: Bool { calendar.isDateInToday(date) }

    private func yPosition(for date: Date) -> CGFloat {
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        return CGFloat(h) * hourHeight + CGFloat(m) / 60.0 * hourHeight
    }

    private var currentTimeY: CGFloat { yPosition(for: currentTime) }

    private func eventHeight(for event: NucleEvent) -> CGFloat {
        let secs = event.endDate.timeIntervalSince(event.startDate)
        return max(hourHeight * CGFloat(secs) / 3600.0, 28)
    }

    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0:  return "12 AM"
        case 12: return "12 PM"
        default: return hour < 12 ? "\(hour) AM" : "\(hour - 12) PM"
        }
    }

    private func eventColor(_ event: NucleEvent) -> Color {
        switch event.calendarColor {
        case .accentPrimary:  return .accentPrimary
        case .accentLight:    return .accentLight
        case .accentLavender: return .accentLavender
        case .custom(let h):  return Color(hex: h)
        }
    }

    private func timeRange(_ event: NucleEvent) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // All-day strip
                    if !allDayEvents.isEmpty {
                        HStack(alignment: .center, spacing: 8) {
                            Text("ALL DAY")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.textMuted)
                                .tracking(0.5)
                                .frame(width: labelWidth, alignment: .trailing)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(allDayEvents, id: \.id) { event in
                                        Text(event.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(eventColor(event).opacity(0.25))
                                            .cornerRadius(4)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundCard)

                        Divider().background(Color.border)
                    }

                    // Hourly timeline
                    ZStack(alignment: .topLeading) {
                        // Hour rows — grid background
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HStack(alignment: .top, spacing: 0) {
                                    Text(formatHour(hour))
                                        .font(.system(size: 10))
                                        .foregroundColor(.textDim)
                                        .frame(width: labelWidth, alignment: .trailing)
                                        .padding(.trailing, 8)
                                        .offset(y: -7)
                                    Rectangle()
                                        .fill(Color.border)
                                        .frame(height: 0.5)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(height: hourHeight)
                                .id(hour)
                            }
                        }

                        // Event blocks
                        ForEach(timedEvents, id: \.id) { event in
                            HStack(spacing: 0) {
                                Spacer().frame(width: labelWidth + 8)

                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(eventColor(event))
                                        .frame(width: 3)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                            .lineLimit(1)

                                        if eventHeight(for: event) > 38 {
                                            Text(timeRange(event))
                                                .font(.system(size: 10))
                                                .foregroundColor(.textMuted)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                                .frame(height: eventHeight(for: event))
                                .background(eventColor(event).opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(.trailing, 16)
                                .onTapGesture {
                            if let onEditEvent { onEditEvent(event) }
                            else { selectedEvent = event }
                        }
                            }
                            .offset(y: yPosition(for: event.startDate))
                        }

                        // Current time indicator (today only)
                        if isToday {
                            HStack(spacing: 0) {
                                Spacer().frame(width: labelWidth + 4)
                                Circle()
                                    .fill(Color.accentWarm)
                                    .frame(width: 8, height: 8)
                                Rectangle()
                                    .fill(Color.accentWarm)
                                    .frame(height: 1.5)
                                    .frame(maxWidth: .infinity)
                            }
                            .offset(y: currentTimeY - 4)
                        }
                    }
                    .frame(height: CGFloat(24) * hourHeight)
                    .padding(.horizontal, 16)
                }
            }
            .onAppear {
                let scrollHour = isToday
                    ? max(calendar.component(.hour, from: Date()) - 1, 0)
                    : 8
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { proxy.scrollTo(scrollHour, anchor: .top) }
                }
            }
        }
        .onReceive(timer) { t in
            if isToday { currentTime = t }
        }
        .sheet(item: $selectedEvent) { event in
            EventFormView(event: event, isPresented: Binding(
                get: { selectedEvent != nil },
                set: { if !$0 { selectedEvent = nil } }
            ))
            .frame(minWidth: 500, minHeight: 560)
        }
    }
}

#Preview {
    DayTimelineView(date: Date(), events: MockData.events)
        .frame(width: 700, height: 600)
        .background(Color.backgroundPrimary)
}
