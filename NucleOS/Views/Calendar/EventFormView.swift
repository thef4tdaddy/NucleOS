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
    @State private var location: String?
    @State private var calendarColor: EventColor = .accentPrimary
    @State private var isLoading = false
    @State private var error: String?
    @State private var recurrenceFrequency: RecurrenceFrequency = .never
    @State private var recurrenceEnd: RecurrenceEnd = .never

    private let calendarService = CalendarService()

    init(event: NucleEvent?, isPresented: Binding<Bool>) {
        self.event = event
        self._isPresented = isPresented

        if let event = event {
            _title = State(initialValue: event.title)
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _location = State(initialValue: event.location)
            _calendarColor = State(initialValue: event.calendarColor)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .disabled(isAllDay)

                    if !isAllDay {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }

                    Toggle("All Day", isOn: $isAllDay)
                        .toggleStyle(.switch)

                    TextField("Location (Optional)", text: $location)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Repeat")) {
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

                Section(header: Text("Calendar Color")) {
                    HStack {
                        ColorSwatch(color: .accentPrimary, selected: calendarColor == .accentPrimary) {
                            calendarColor = .accentPrimary
                        }
                        Text("Primary")
                    }

                    HStack {
                        ColorSwatch(color: .accentLight, selected: calendarColor == .accentLight) {
                            calendarColor = .accentLight
                        }
                        Text("Light")
                    }

                    HStack {
                        ColorSwatch(color: .accentLavender, selected: calendarColor == .accentLavender) {
                            calendarColor = .accentLavender
                        }
                        Text("Lavender")
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveEvent) {
                        Text(event == nil ? "Create" : "Save")
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $error.isNotEmpty, actions: {
                Button("OK", role: .cancel) { }
            }) {
                Text(error ?? "")
            }
            .task {
                if let event = event {
                    title = event.title
                    startDate = event.startDate
                    endDate = event.endDate
                    isAllDay = event.isAllDay
                    location = event.location
                    calendarColor = event.calendarColor
                }
            }
        }
    }

    private func saveEvent() {
        guard !title.isEmpty else { return }

        isLoading = true
        error = nil

        let eventToSave = NucleEvent(
            id: event?.id ?? UUID(),
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarColor: calendarColor,
            isAllDay: isAllDay,
            location: location
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
        do {
            if appSettings.useMockCalendarData {
                // Mock implementation - no-op for now
            } else {
                // Real implementation would refresh events
            }
        } catch {
            // Handle error
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