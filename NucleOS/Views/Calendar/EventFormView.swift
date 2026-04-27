//
//  EventFormView.swift
//  NucleOS
//
//  Create / edit calendar events with NucleOS-branded chrome.
//  NUC-71: calendar selector  NUC-74: edit + delete
//

import SwiftUI
import EventKit

enum RecurrenceFrequency: Hashable {
    case never, daily, weekly, biweekly, monthly, yearly
}

enum RecurrenceEnd: Hashable {
    case never
    case count(Int)
    case date(Date)
}

struct EventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings

    let event: NucleEvent?
    @Binding var isPresented: Bool

    // MARK: - Form state
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var location = ""
    @State private var urlString = ""
    @State private var notes = ""
    @State private var calendarColor: EventColor = .accentPrimary
    @State private var availability: EventAvailability = .busy
    @State private var reminderOffset: Int? = nil
    @State private var recurrenceFrequency: RecurrenceFrequency = .never
    @State private var recurrenceEnd: RecurrenceEnd = .never

    // NUC-71: calendar selector
    @State private var availableCalendars: [EKCalendar] = []
    @State private var selectedCalendarID: String? = nil

    // NUC-74: delete
    @State private var showingDeleteConfirmation = false

    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    private let calendarService = CalendarService()

    private var isEditing: Bool { event != nil }

    // MARK: - Init

    init(event: NucleEvent?, isPresented: Binding<Bool>) {
        self.event = event
        self._isPresented = isPresented

        if let e = event {
            _title            = State(initialValue: e.title)
            _startDate        = State(initialValue: e.startDate)
            _endDate          = State(initialValue: e.endDate)
            _isAllDay         = State(initialValue: e.isAllDay)
            _location         = State(initialValue: e.location ?? "")
            _urlString        = State(initialValue: e.url?.absoluteString ?? "")
            _notes            = State(initialValue: e.notes ?? "")
            _calendarColor    = State(initialValue: e.calendarColor)
            _availability     = State(initialValue: e.availability)
            _reminderOffset   = State(initialValue: e.reminderOffset)
            _selectedCalendarID = State(initialValue: e.calendarIdentifier)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // NucleOS header — no macOS window chrome
            headerBar

            Divider().background(Color.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    detailsSection
                    calendarSection       // NUC-71
                    availabilitySection
                    alertSection
                    repeatSection
                    colorSection

                    // NUC-74: delete button (edit mode only)
                    if isEditing {
                        deleteSection
                    }
                }
                .padding(24)
            }
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Delete Event", role: .destructive) { deleteEvent() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(title)\"?")
        }
        .onAppear { loadCalendars() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.backgroundCard)
                .foregroundColor(.textSecondary)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))

            Spacer()

            Text(isEditing ? "Edit Event" : "New Event")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            Spacer()

            if isLoading {
                ProgressView().tint(.accentPrimary).scaleEffect(0.8)
            } else {
                Button(isEditing ? "Save" : "Create") { saveEvent() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(title.isEmpty ? Color.accentPrimary.opacity(0.35) : Color.accentPrimary)
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .semibold))
                    .cornerRadius(8)
                    .disabled(title.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.backgroundCard)
    }

    // MARK: - Form sections

    private var detailsSection: some View {
        formSection(title: "Event Details") {
            VStack(alignment: .leading, spacing: 16) {
                FormTextField(title: "Title", text: $title, placeholder: "Event Title")

                HStack {
                    Text("Start")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    DatePicker("", selection: $startDate,
                               displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                if !isAllDay {
                    HStack {
                        Text("End")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 60, alignment: .leading)
                        DatePicker("", selection: $endDate,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }

                Toggle("All Day Event", isOn: $isAllDay).toggleStyle(.switch)

                FormTextField(title: "Location", text: $location, placeholder: "Location (Optional)")
                FormTextField(title: "URL", text: $urlString, placeholder: "URL (Optional)")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 72)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.backgroundCard)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))
                        )
                }
            }
        }
    }

    // NUC-71: calendar picker
    private var calendarSection: some View {
        formSection(title: "Calendar") {
            if availableCalendars.isEmpty {
                Text("No calendars available")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
            } else {
                Picker("Calendar", selection: $selectedCalendarID) {
                    ForEach(availableCalendars, id: \.calendarIdentifier) { cal in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(cgColor: cal.cgColor))
                                .frame(width: 10, height: 10)
                            Text(cal.title)
                        }
                        .tag(Optional(cal.calendarIdentifier))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    private var availabilitySection: some View {
        formSection(title: "Availability") {
            Picker("", selection: $availability) {
                Text("Busy").tag(EventAvailability.busy)
                Text("Free").tag(EventAvailability.free)
                Text("Tentative").tag(EventAvailability.tentative)
            }
            .pickerStyle(.segmented)
        }
    }

    private var alertSection: some View {
        formSection(title: "Alert") {
            Picker("Reminder", selection: $reminderOffset) {
                Text("None").tag(Int?.none)
                Text("At time of event").tag(Int?.some(0))
                Text("5 minutes before").tag(Int?.some(5))
                Text("15 minutes before").tag(Int?.some(15))
                Text("30 minutes before").tag(Int?.some(30))
                Text("1 hour before").tag(Int?.some(60))
                Text("2 hours before").tag(Int?.some(120))
                Text("1 day before").tag(Int?.some(1440))
            }
            .pickerStyle(.menu)
        }
    }

    private var repeatSection: some View {
        formSection(title: "Repeat") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Repeats", selection: $recurrenceFrequency) {
                    Text("Never").tag(RecurrenceFrequency.never)
                    Text("Daily").tag(RecurrenceFrequency.daily)
                    Text("Weekly").tag(RecurrenceFrequency.weekly)
                    Text("Bi-Weekly").tag(RecurrenceFrequency.biweekly)
                    Text("Monthly").tag(RecurrenceFrequency.monthly)
                    Text("Yearly").tag(RecurrenceFrequency.yearly)
                }
                .pickerStyle(.menu)

                if recurrenceFrequency != .never {
                    Picker("End Repeat", selection: $recurrenceEnd) {
                        Text("Never").tag(RecurrenceEnd.never)
                        Text("After 10 Occurrences").tag(RecurrenceEnd.count(10))
                        Text("On Date").tag(RecurrenceEnd.date(Date().addingTimeInterval(60*60*24*365)))
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var colorSection: some View {
        formSection(title: "Calendar Color") {
            HStack(spacing: 16) {
                ColorSwatch(color: .accentPrimary, selected: calendarColor == .accentPrimary) {
                    calendarColor = .accentPrimary
                }
                ColorSwatch(color: .accentLight, selected: calendarColor == .accentLight) {
                    calendarColor = .accentLight
                }
                ColorSwatch(color: .accentLavender, selected: calendarColor == .accentLavender) {
                    calendarColor = .accentLavender
                }
            }
        }
    }

    // NUC-74: delete section
    private var deleteSection: some View {
        Button(action: { showingDeleteConfirmation = true }) {
            HStack {
                Spacer()
                Image(systemName: "trash")
                Text("Delete Event")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadCalendars() {
        availableCalendars = calendarService.fetchCalendars()
        // Default to the event's calendar or the store default
        if selectedCalendarID == nil {
            selectedCalendarID = PermissionsManager.shared.eventStore
                .defaultCalendarForNewEvents?.calendarIdentifier
        }
    }

    private func saveEvent() {
        guard !title.isEmpty else { return }
        isLoading = true

        let url = urlString.isEmpty ? nil : URL(string: urlString)
        let eventToSave = NucleEvent(
            id: event?.id ?? UUID(),
            eventIdentifier: event?.eventIdentifier,
            calendarIdentifier: selectedCalendarID,
            title: title,
            startDate: startDate,
            endDate: isAllDay ? startDate : endDate,
            calendarColor: calendarColor,
            isAllDay: isAllDay,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            url: url,
            availability: availability,
            reminderOffset: reminderOffset
        )

        Task {
            do {
                if isEditing {
                    try await calendarService.updateEvent(eventToSave, calendarIdentifier: selectedCalendarID)
                } else {
                    try await calendarService.createEvent(eventToSave, calendarIdentifier: selectedCalendarID)
                }
                NotificationCenter.default.post(name: NSNotification.Name("CalendarDataChanged"), object: nil)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func deleteEvent() {
        guard let event else { return }
        isLoading = true
        Task {
            do {
                try await calendarService.deleteEvent(event)
                NotificationCenter.default.post(name: NSNotification.Name("CalendarDataChanged"), object: nil)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - formSection helper

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            )
        }
    }
}

// MARK: - Reusable sub-views

struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
        }
    }
}

struct ColorSwatch: View {
    let color: EventColor
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(colorFromEventColor(color))
                .frame(width: 24, height: 24)
                .overlay(
                    selected ? Circle()
                        .stroke(Color.accentPrimary, lineWidth: 2)
                        .frame(width: 30, height: 30) : nil
                )
        }
        .buttonStyle(.plain)
    }

    private func colorFromEventColor(_ eventColor: EventColor) -> Color {
        switch eventColor {
        case .accentPrimary:  return .accentPrimary
        case .accentLight:    return .accentLight
        case .accentLavender: return .accentLavender
        case .custom(let hex): return Color(hex: hex)
        }
    }
}
