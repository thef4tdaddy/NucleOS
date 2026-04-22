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
    @State private var loadTask: Task<Void, Never>? = nil
    @State private var showingMockData = false
    @State private var selectedDate = Date()
    @State private var showMonthView = false
    @State private var showingDayTimeline = false
    @State private var isCreatingEvent = false
    @State private var isEditingEvent: NucleEvent?
    @State private var quickAddText = ""
    @State private var showingQuickAdd = false

    private let calendarService = CalendarService()
    private let mockService = MockCalendarService()
    @EnvironmentObject var appSettings: AppSettings

    private var calendarProvider: CalendarServiceProtocol {
        appSettings.useMockCalendarData ? mockService : calendarService
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                Text("Calendar")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()

                Button(action: {
                    withAnimation {
                        selectedDate = Date()
                        startLoadEvents()
                    }
                }) {
                    Text("Today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Picker("View", selection: $showMonthView) {
                    Text("Month").tag(true)
                    Text("List").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 12)

            if showMonthView {
                MonthCalendarView(selectedDate: $selectedDate, events: events)
                    .frame(maxHeight: 300)
                Divider()
                // Day timeline when a date is selected
                if showingDayTimeline {
                    DayTimelineView(date: selectedDate, events: events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) })
                }
            } else {
                // Existing list view content (unchanged, but wrapped)
                CalendarListContent()
            }
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $isCreatingEvent) {
            EventFormView(event: nil, isPresented: $isCreatingEvent)
        }
        .sheet(isPresented: $isEditingEvent, onDismiss: {
            isEditingEvent = nil
        }) { event in
            EventFormView(event: event, isPresented: $isEditingEvent)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddEventView(text: $quickAddText, isPresented: $showingQuickAdd)
        }
    }

    @ViewBuilder
    private func CalendarListContent() -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Image("icon-calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

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

                Button(action: { showingQuickAdd = true }, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Quick add event")

                Button(action: { isCreatingEvent = true }, label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Add event")

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
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(groupedEventsByDay, id: \.key, content: { day, dayEvents in
                            DayEventsSection(date: day, events: dayEvents)
                        })
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Color.backgroundPrimary)
        .task(priority: .userInitiated) {
            await loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CalendarDataChanged"))) { _ in
            startLoadEvents()
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
            if showMonthView {
                let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))!
                guard let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) else { return }
                events = try await calendarProvider.fetchEvents(from: monthStart, to: monthEnd)
            } else {
                if selectedDays == 1 {
                    events = try await calendarProvider.fetchTodayEvents()
                } else {
                    events = try await calendarProvider.fetchUpcomingEvents(days: selectedDays)
                }
            }
        } catch CalendarServiceError.permissionDenied {
            showingMockData = true
            do {
                if showMonthView {
                    let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))!
                    guard let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) else { return }
                    events = try await mockService.fetchEvents(from: monthStart, to: monthEnd)
                } else {
                    if selectedDays == 1 {
                        events = try await mockService.fetchTodayEvents()
                    } else {
                        events = try await mockService.fetchUpcomingEvents(days: selectedDays)
                    }
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
    @State private var showingDeleteConfirmation = false
    @State private var offset = CGSize.zero
    @State private var isSwiped = false

    @EnvironmentObject var appSettings: AppSettings
    private let calendarService = CalendarService()
    private let mockService = MockCalendarService()

    private var calendarProvider: CalendarServiceProtocol {
        appSettings.useMockCalendarData ? mockService : calendarService
    }

    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .frame(width: 80, height: .infinity)
                        .background(Color.red)
                }
                .buttonStyle(.plain)
            }

            // Main card
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
            .onDrag {
                let itemProvider = NSItemProvider(object: event.id.uuidString as NSString)
                return itemProvider
            }
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            offset = CGSize(width: max(-80, gesture.translation.width), height: 0)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut) {
                            if offset.width < -40 {
                                offset = CGSize(width: -80, height: 0)
                                isSwiped = true
                            } else {
                                offset = .zero
                                isSwiped = false
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.easeInOut) {
                    offset = .zero
                    isSwiped = false
                }
            }
            .confirmationDialog("Delete Event", isPresented: $showingDeleteConfirmation) {
                Button("Delete Event", role: .destructive) {
                    Task {
                        try? await calendarProvider.deleteEvent(event)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
        }
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
