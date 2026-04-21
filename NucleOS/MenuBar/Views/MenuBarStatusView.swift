//
//  MenuBarStatusView.swift
//  NucleOS
//
//  Quick-glance status view shown in the menu bar popover.
//  Displays pending tasks, the next calendar event, and a health summary.
//  All data is read from MenuBarState — no direct service calls.
//

import SwiftUI

// MARK: - MenuBarStatusView

/// The primary read-only status surface inside the menu bar popover.
///
/// Three collapsible sections — Tasks, Next Event, Health — each degrade
/// gracefully to a single-line empty state when data is unavailable.
/// Width is fixed at 300pt to fit comfortably in a standard macOS popover.
struct MenuBarStatusView: View {

    @ObservedObject var state: MenuBarState

    var body: some View {
        VStack(spacing: 8) {
            TasksSection(pendingCount: state.pendingTaskCount)
            NextEventSection(event: state.nextEvent)
            HealthSection(snapshot: state.healthSnapshot)
        }
        .padding(14)
        .frame(width: 300)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Tasks Section

/// Compact tasks section: shows pending count or an "All clear" badge.
private struct TasksSection: View {

    let pendingCount: Int

    var body: some View {
        MenuBarSectionCard {
            HStack(spacing: 10) {
                MenuBarSectionIcon(systemName: "checklist", color: .accentLavender)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tasks")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)

                    if pendingCount > 0 {
                        Text(pendingCount == 1 ? "1 task remaining today" : "\(pendingCount) tasks remaining today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.accentLavender)
                            Text("All clear")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.accentLavender)
                        }
                    }
                }

                Spacer()

                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentLavender)
                        .frame(minWidth: 20)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.accentPrimary.opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.accentPrimary.opacity(0.35), lineWidth: 0.5)
                                )
                        )
                }
            }
        }
    }
}

// MARK: - Next Event Section

/// Compact next-event section: shows event title + time, or "No events today".
private struct NextEventSection: View {

    let event: NucleEvent?

    var body: some View {
        MenuBarSectionCard {
            HStack(spacing: 10) {
                MenuBarSectionIcon(systemName: "calendar", color: .accentLight)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Event")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)

                    if let event = event {
                        Text(event.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text("No events today")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if let event = event {
                    Text(formatEventTime(event))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    private func formatEventTime(_ event: NucleEvent) -> String {
        if event.isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.startDate)
    }
}

// MARK: - Health Section

/// Compact health section: shows step progress bar + count, or a no-data state.
private struct HealthSection: View {

    let snapshot: HealthSnapshot?

    var body: some View {
        MenuBarSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    MenuBarSectionIcon(systemName: "figure.walk", color: .accentPrimary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textMuted)

                        if let snapshot = snapshot {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(snapshot.steps.formatted())
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Text("/ \(snapshot.stepGoal.formatted()) steps")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                        } else {
                            Text("No health data")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    if let snapshot = snapshot {
                        Text("\(Int(snapshot.stepsProgress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentPrimary)
                    }
                }

                if let snapshot = snapshot {
                    StepProgressBar(progress: snapshot.stepsProgress)
                }
            }
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {

    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.border)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentPrimary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Shared Section Card

/// A card container consistent with the NucleOS dark purple design language.
private struct MenuBarSectionCard<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.border, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Section Icon

private struct MenuBarSectionIcon: View {

    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
                .frame(width: 28, height: 28)

            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Previews

#Preview("With Data") {
    MenuBarStatusView(state: .preview)
}

#Preview("Empty States") {
    MenuBarStatusView(state: .previewEmpty)
}

#Preview("Single Task") {
    MenuBarStatusView(state: MenuBarState(
        pendingTaskCount: 1,
        nextEvent: NucleEvent(
            title: "Weekly All-Hands",
            startDate: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            endDate: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date(),
            calendarColor: .accentPrimary
        ),
        healthSnapshot: HealthSnapshot(
            steps: 10_500,
            stepGoal: 10_000,
            heartRate: 68.0,
            sleepDuration: 8 * 3600,
            activeCalories: 2_300
        )
    ))
}
