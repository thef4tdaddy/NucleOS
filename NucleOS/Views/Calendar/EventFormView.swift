//
//  EventFormView.swift
//  NucleOS
//
//  Form for creating and editing calendar events
//

import SwiftUI
import EventKit

enum RecurrenceFrequency: Hashable {
    case never
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly
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

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var location = ""
    @State private var calendarColor: EventColor = .accentPrimary
    @State private var isLoading = false
    @State private var error: String?
    @State private var recurrenceFrequency: RecurrenceFrequency = .never
    @State private var recurrenceEnd: RecurrenceEnd = .never
    @State private var notes = ""
    @State private var urlString = ""
    @State private var availability: EventAvailability = .busy
    @State private var reminderOffset: Int? = nil

    private let calendarService = CalendarService()

    init(event: NucleEvent?, isPresented: Binding<Bool>) {
        self.event = event
        self._isPresented = isPresented

        if let event = event {
            _title = State(initialValue: event.title)
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _location = State(initialValue: event.location ?? "")
            _calendarColor = State(initialValue: event.calendarColor)
            _notes = State(initialValue: event.notes ?? "")
            _urlString = State(initialValue: event.url?.absoluteString ?? "")
            _availability = State(initialValue: event.availability)
            _reminderOffset = State(initialValue: event.reminderOffset)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // NucleOS branded header — no macOS window chrome
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.backgroundCard)
                    .foregroundColor(.textSecondary)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.border, lineWidth: 1))

                Spacer()

                Text(event == nil ? "New Event" : "Edit Event")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                if isLoading {
                    ProgressView().tint(.accentPrimary).scaleEffect(0.8)
                } else {
                    Button(event == nil ? "Create" : "Save") { saveEvent() }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(title.isEmpty ? Color.accentPrimary.opacity(0.35) : Color.accentPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(title.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.backgroundCard)

            Divider().background(Color.border)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event Details
                    formSection(title: "Event Details") {
                        VStack(alignment: .leading, spacing: 16) {
                            FormTextField(title: "Title", text: $title, placeholder: "Event Title")

                            HStack {
                                Text("Start")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 60, alignment: .leading)
                                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .disabled(isAllDay)
                                    .labelsHidden()
                            }

                            if !isAllDay {
                                HStack {
                                    Text("End")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                }
                            }

                            Toggle("All Day Event", isOn: $isAllDay)
                                .toggleStyle(.switch)

                            FormTextField(title: "Location", text: $location, placeholder: "Location (Optional)")
                            FormTextField(title: "URL", text: $urlString, placeholder: "URL (Optional)")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.backgroundCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.border, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }

                    // Availability
                    formSection(title: "Availability") {
                        Picker("", selection: $availability) {
                            Text("Busy").tag(EventAvailability.busy)
                            Text("Free").tag(EventAvailability.free)
                            Text("Tentative").tag(EventAvailability.tentative)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Alert
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

                    // Repeat
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

                    // Calendar Color
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
                .padding(24)
            }
            .background(Color.backgroundPrimary)
        }
        .background(Color.backgroundPrimary)
        .alert("Error", isPresented: $error.isNotEmpty) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error ?? "")
        }
        .task {
            if let event = event {
                title = event.title
                startDate = event.startDate
                endDate = event.endDate
                isAllDay = event.isAllDay
                location = event.location ?? ""
                calendarColor = event.calendarColor
            }
        }
    }

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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.border, lineWidth: 1)
                    )
            )
        }
    }

    private func saveEvent() {
        guard !title.isEmpty else { return }

        isLoading = true
        error = nil

        let eventURL = URL(string: urlString)
        let eventToSave = NucleEvent(
            id: event?.id ?? UUID(),
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarColor: calendarColor,
            isAllDay: isAllDay,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            url: eventURL,
            availability: availability,
            reminderOffset: reminderOffset
        )

        Task {
            do {
                if event == nil {
                    try await calendarService.createEvent(eventToSave)
                } else {
                    try await calendarService.updateEvent(eventToSave)
                }
                dismiss()
                await loadEvents()
            } catch {
                self.error = "Failed to save event: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func loadEvents() async {
        if appSettings.useMockCalendarData {
            // Mock implementation - no-op for now
        } else {
            // Real implementation would refresh events
        }
    }
}

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
                        .frame(width: 28, height: 28) : nil
                )
        }
        .buttonStyle(.plain)
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
