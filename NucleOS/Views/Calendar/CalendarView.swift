//
//  CalendarView.swift
//  NucleOS
//
//  Full calendar view — Day / Week / Month / List modes.
//  NUC-72: single header, date nav in all views
//  NUC-73: calendar filter popover
//

import SwiftUI
import EventKit

/// Full-page view for Calendar. Supports Day, Week, Month, and List modes.
struct CalendarView: View {

    enum ViewMode: String, CaseIterable {
        case day   = "Day"
        case week  = "Week"
        case month = "Month"
        case list  = "List"
    }

    @State private var viewMode: ViewMode = .day
    @State private var selectedDate = Date()
    @State private var events: [NucleEvent] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var permissionDenied = false
    @State private var loadTask: Task<Void, Never>?
    @State private var isCreatingEvent = false
    @State private var isEditingEvent: NucleEvent?
    @State private var quickAddText = ""
    @State private var showingQuickAdd = false

    // NUC-73: calendar filter
    @State private var showingCalendarFilter = false
    @State private var allCalendars: [EKCalendar] = []
    @State private var visibleCalendarIDs: Set<String> = []

    private let calendarService = CalendarService()
    private let mockService = MockCalendarService()
    @EnvironmentObject var appSettings: AppSettings

    private var calendarProvider: CalendarServiceProtocol {
        appSettings.useMockCalendarData ? mockService : calendarService
    }

    private var cal: Calendar { .current }

    // Events filtered by visible calendars
    private var filteredEvents: [NucleEvent] {
        guard !visibleCalendarIDs.isEmpty else { return events }
        return events.filter { event in
            guard let calID = event.calendarIdentifier else { return true }
            return visibleCalendarIDs.contains(calID)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider().background(Color.border)

            if permissionDenied {
                PermissionBanner(permission: .calendar)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                Spacer()
            } else if let err = error {
                ErrorStateView(message: err, retry: { startLoadEvents() })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                contentView
            }
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $isCreatingEvent) {
            EventFormView(event: nil, isPresented: $isCreatingEvent)
                .frame(minWidth: 480, minHeight: 540)
        }
        .sheet(item: $isEditingEvent) { event in
            EventFormView(event: event, isPresented: Binding(
                get: { isEditingEvent != nil },
                set: { if !$0 { isEditingEvent = nil } }
            ))
            .frame(minWidth: 480, minHeight: 540)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddEventView(text: $quickAddText, isPresented: $showingQuickAdd)
                .frame(minWidth: 440, minHeight: 380)
        }
        .popover(isPresented: $showingCalendarFilter, arrowEdge: .top) {
            CalendarFilterPopover(
                calendars: allCalendars,
                visibleIDs: $visibleCalendarIDs
            )
            .frame(width: 280)
        }
        .task(priority: .userInitiated) { await loadEvents() }
        .onChange(of: viewMode) { _, _ in startLoadEvents() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CalendarDataChanged"))) { _ in
            startLoadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if permissionDenied { startLoadEvents() }
        }
        .onAppear { loadCalendarList() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Icon + title
            HStack(spacing: 10) {
                Image("icon-calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Calendar")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(dateRangeLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // Date navigation — present in all modes (NUC-72)
            HStack(spacing: 4) {
                Button(action: navigateBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .frame(width: 28, height: 28)
                        .background(Color.accentPrimary.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: {
                    selectedDate = Date()
                    startLoadEvents()
                }) {
                    Text("Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentPrimary.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: navigateForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .frame(width: 28, height: 28)
                        .background(Color.accentPrimary.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Custom view mode switcher
            HStack(spacing: 2) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { viewMode = mode }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(viewMode == mode ? Color.accentPrimary : Color.clear)
                        .foregroundColor(viewMode == mode ? .white : .textMuted)
                        .cornerRadius(6)
                }
            }
            .padding(3)
            .background(Color.backgroundCard)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))

            // Action buttons
            if isLoading {
                ProgressView().tint(.accentPrimary).scaleEffect(0.7)
            }

            // NUC-73: filter button
            Button(action: { showingCalendarFilter.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(
                        (!allCalendars.isEmpty && visibleCalendarIDs.count < allCalendars.count)
                        ? .accentLavender : .accentPrimary
                    )
            }
            .buttonStyle(.plain)
            .help("Filter calendars")

            Button(action: { showingQuickAdd = true }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentPrimary)
            }
            .buttonStyle(.plain)
            .help("Quick add event")

            Button(action: { isCreatingEvent = true }) {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.accentPrimary)
            }
            .buttonStyle(.plain)
            .help("Add event")

            Button(action: startLoadEvents) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.accentPrimary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .help("Refresh")
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 16)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .day:
            DayTimelineView(
                date: selectedDate,
                events: filteredEvents.filter { cal.isDate($0.startDate, inSameDayAs: selectedDate) },
                onEditEvent: { event in isEditingEvent = event }
            )

        case .week:
            WeekCalendarView(
                selectedDate: $selectedDate,
                events: filteredEvents,
                onEditEvent: { event in isEditingEvent = event }
            )

        case .month:
            ScrollView {
                MonthCalendarView(selectedDate: $selectedDate, events: filteredEvents)
                    .padding(32)
            }

        case .list:
            listView
        }
    }

    private var listView: some View {
        Group {
            if filteredEvents.isEmpty && !isLoading {
                EmptyStateView(message: "No events scheduled")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(groupedEventsByDay, id: \.key) { day, dayEvents in
                            DayEventsSection(date: day, events: dayEvents) { event in
                                isEditingEvent = event
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
    }

    // MARK: - Helpers

    private var dateRangeLabel: String {
        let f = DateFormatter()
        switch viewMode {
        case .day:
            f.dateFormat = "EEEE, MMMM d, yyyy"
            return f.string(from: selectedDate)
        case .week:
            let start = cal.date(
                from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
            ) ?? selectedDate
            let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
            f.dateFormat = "MMM d"
            return "\(f.string(from: start)) – \(f.string(from: end))"
        case .month:
            f.dateFormat = "MMMM yyyy"
            return f.string(from: selectedDate)
        case .list:
            return "Next 30 days"
        }
    }

    private var groupedEventsByDay: [(key: Date, value: [NucleEvent])] {
        let grouped = Dictionary(grouping: filteredEvents) { e in
            cal.startOfDay(for: e.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private func navigateBack() {
        selectedDate = offsetDate(selectedDate, by: -1)
        startLoadEvents()
    }

    private func navigateForward() {
        selectedDate = offsetDate(selectedDate, by: 1)
        startLoadEvents()
    }

    private func offsetDate(_ date: Date, by amount: Int) -> Date {
        switch viewMode {
        case .day, .list:
            return cal.date(byAdding: .day, value: amount, to: date) ?? date
        case .week:
            return cal.date(byAdding: .weekOfYear, value: amount, to: date) ?? date
        case .month:
            return cal.date(byAdding: .month, value: amount, to: date) ?? date
        }
    }

    private func startLoadEvents() {
        loadTask?.cancel()
        loadTask = Task { await loadEvents() }
    }

    private func loadEvents() async {
        isLoading = true
        error = nil
        permissionDenied = false

        do {
            switch viewMode {
            case .day, .week, .month:
                events = try await calendarProvider.fetchEvents(for: selectedDate)
            case .list:
                events = try await calendarProvider.fetchUpcomingEvents(days: 30)
            }
        } catch CalendarServiceError.permissionDenied {
            permissionDenied = true
            events = []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
        loadTask = nil
    }

    private func loadCalendarList() {
        guard !appSettings.useMockCalendarData else { return }
        allCalendars = calendarService.fetchCalendars()
        let saved = UserDefaults.standard.stringArray(forKey: "visible_calendar_ids")
        if let saved {
            visibleCalendarIDs = Set(saved)
        } else {
            visibleCalendarIDs = Set(allCalendars.map { $0.calendarIdentifier })
        }
    }
}

// MARK: - Calendar Filter Popover (NUC-73)

struct CalendarFilterPopover: View {
    let calendars: [EKCalendar]
    @Binding var visibleIDs: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Calendars")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("All") {
                    visibleIDs = Set(calendars.map { $0.calendarIdentifier })
                    persist()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.accentPrimary)

                Text("·").foregroundColor(.textMuted).padding(.horizontal, 4)

                Button("None") {
                    visibleIDs = []
                    persist()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.accentPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(Color.border)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(calendars, id: \.calendarIdentifier) { cal in
                        Button(action: {
                            if visibleIDs.contains(cal.calendarIdentifier) {
                                visibleIDs.remove(cal.calendarIdentifier)
                            } else {
                                visibleIDs.insert(cal.calendarIdentifier)
                            }
                            persist()
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(cgColor: cal.cgColor))
                                    .frame(width: 12, height: 12)
                                Text(cal.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Image(systemName: visibleIDs.contains(cal.calendarIdentifier)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(visibleIDs.contains(cal.calendarIdentifier)
                                                     ? .accentPrimary : .textMuted)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .background(Color.backgroundCard)
    }

    private func persist() {
        UserDefaults.standard.set(Array(visibleIDs), forKey: "visible_calendar_ids")
    }
}

// MARK: - Day events section (list view, NUC-74: tap to edit)

struct DayEventsSection: View {
    let date: Date
    let events: [NucleEvent]
    var onEdit: ((NucleEvent) -> Void)? = nil

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            VStack(spacing: 8) {
                ForEach(events.sorted { $0.startDate < $1.startDate }, id: \.id) { event in
                    EventCardView(event: event, onEdit: { onEdit?(event) })
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var dayLabel: String {
        if calendar.isDateInToday(date)    { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    private var dateLabel: String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Event card (list view)

struct EventCardView: View {
    let event: NucleEvent
    var onEdit: (() -> Void)? = nil

    @State private var showingDeleteConfirmation = false
    @State private var cardOffset = CGSize.zero
    @State private var isSwiped = false

    @EnvironmentObject var appSettings: AppSettings
    private let calendarService = CalendarService()
    private let mockService = MockCalendarService()

    private var provider: CalendarServiceProtocol {
        appSettings.useMockCalendarData ? mockService : calendarService
    }

    var body: some View {
        ZStack {
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

            HStack(spacing: 16) {
                Rectangle()
                    .fill(colorFrom(event.calendarColor))
                    .frame(width: 4, height: 60)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock").font(.system(size: 11))
                            Text(timeRange).font(.system(size: 12))
                        }
                        .foregroundColor(.textMuted)

                        if let loc = event.location {
                            HStack(spacing: 6) {
                                Image(systemName: "location").font(.system(size: 11))
                                Text(loc).font(.system(size: 12)).lineLimit(1)
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
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            )
            .offset(x: cardOffset.width)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        if g.translation.width < 0 {
                            cardOffset = CGSize(width: max(-80, g.translation.width), height: 0)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut) {
                            if cardOffset.width < -40 {
                                cardOffset = CGSize(width: -80, height: 0)
                                isSwiped = true
                            } else {
                                cardOffset = .zero
                                isSwiped = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    withAnimation(.easeInOut) { cardOffset = .zero; isSwiped = false }
                } else {
                    onEdit?()
                }
            }
            .confirmationDialog("Delete Event", isPresented: $showingDeleteConfirmation) {
                Button("Delete Event", role: .destructive) {
                    Task {
                        try? await provider.deleteEvent(event)
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CalendarDataChanged"), object: nil)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this event?")
            }
        }
    }

    private var timeRange: String {
        if event.isAllDay { return "All Day" }
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: event.startDate)) – \(f.string(from: event.endDate))"
    }

    private func colorFrom(_ c: EventColor) -> Color {
        switch c {
        case .accentPrimary:  return .accentPrimary
        case .accentLight:    return .accentLight
        case .accentLavender: return .accentLavender
        case .custom(let h):  return Color(hex: h)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppSettings())
}
