//
//  CalendarComponents.swift
//  NucleOS
//
//  Calendar panel and event row
//

import SwiftUI

/// Dashboard panel that lists today's calendar events from EventKit.
struct CalendarPanelView: View {
    @State private var events: [NucleEvent] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var permissionDenied = false
    @State private var isCreatingEvent = false

    private let calendarService = CalendarService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: { isCreatingEvent = true }, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
            }

            if isLoading && events.isEmpty {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in EventShimmerRow() }
                }
            } else if permissionDenied {
                PermissionBanner(permission: .calendar)
            } else if let error = error {
                ErrorStateView(message: error, retry: {
                    Task { await loadEvents() }
                })
            } else if events.isEmpty {
                EmptyStateView(
                    message: "Nothing scheduled",
                    subtext: "Your day is wide open"
                )
            } else {
                ScrollView(content: {
                    VStack(spacing: 12) {
                        ForEach(events.prefix(4), content: { event in
                            EventRow(event: event)
                        })
                    }
                })
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )
        )
        .sheet(isPresented: $isCreatingEvent) {
            EventFormView(event: nil, isPresented: $isCreatingEvent)
        }
        .task(priority: .userInitiated) {
            await loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if permissionDenied {
                Task { await loadEvents() }
            }
        }
    }

    /// Fetches today's events from Calendar; sets `permissionDenied` if access is not granted.
    private func loadEvents() async {
        isLoading = true
        error = nil
        permissionDenied = false

        do {
            events = try await calendarService.fetchTodayEvents()
        } catch CalendarServiceError.permissionDenied {
            permissionDenied = true
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

/// A single compact event row used inside ``CalendarPanelView``.
struct EventRow: View {
    /// The event to display.
    let event: NucleEvent

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(colorFromEventColor(event.calendarColor))
                .frame(width: 3, height: 32)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(event.startDate, isAllDay: event.isAllDay))
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// Returns `"All Day"` for all-day events, or a short time string for timed events.
    private func formatTime(_ date: Date, isAllDay: Bool) -> String {
        if isAllDay {
            return "All Day"
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
