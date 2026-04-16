//
//  CalendarComponents.swift
//  NucleOS
//
//  Calendar panel and event row
//

import SwiftUI

struct CalendarPanelView: View {
    @State private var events: [NucleEvent] = []
    @State private var isLoading = false
    @State private var error: String?

    private let calendarService = CalendarService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.accentPrimary)
                }

                Button(action: {}, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
                .disabled(true) // Disabled until add functionality is implemented
            }

            if let error = error {
                ErrorStateView(message: error)
            } else if events.isEmpty && !isLoading {
                EmptyStateView(message: "No events today")
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
        .task(priority: .userInitiated, operation: {
            await loadEvents()
        })
    }

    private func loadEvents() async {
        isLoading = true
        error = nil

        do {
            events = try await calendarService.fetchTodayEvents()
        } catch CalendarServiceError.permissionDenied {
            // Fall back to mock data
            events = try? await MockCalendarService().fetchTodayEvents() ?? []
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct EventRow: View {
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

    private func formatTime(_ date: Date, isAllDay: Bool) -> String {
        if isAllDay {
            return "All Day"
        }

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
