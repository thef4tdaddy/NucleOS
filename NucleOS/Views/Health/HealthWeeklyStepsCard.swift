//
//  HealthWeeklyStepsCard.swift
//  NucleOS
//
//  Weekly steps bar chart card for the Health section.
//  Today's step count is driven by the live HealthSnapshot.
//

import SwiftUI

// MARK: - Weekly Steps Card

struct HealthWeeklyStepsCard: View {
    let todaySteps: Int
    let stepGoal: Int

    private struct DayEntry {
        let day: String
        let steps: Int
        let isToday: Bool
        let isDataAvailable: Bool
    }

    /// Weekly step data with today's real count from the snapshot.
    /// Today's bar uses the live `todaySteps` value from the snapshot.
    /// Past/future days are marked as unavailable because a per-day history query is
    /// outside the scope of the current `HealthSnapshot` model (which only captures today's totals).
    private var weeklyData: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat. Map to Mon-Sun display.
        let orderedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        // weekday index for Monday = 2, so offset = today's weekday - 2 (mod 7)
        let todayIndex = (today + 5) % 7 // 0=Mon, 1=Tue, ..., 6=Sun

        return orderedDays.enumerated().map { index, day in
            if index == todayIndex {
                return DayEntry(day: day, steps: todaySteps, isToday: true, isDataAvailable: true)
            } else {
                // Past and future days: data unavailable (per-day history requires HKStatisticsCollectionQuery)
                return DayEntry(day: day, steps: 0, isToday: false, isDataAvailable: false)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Steps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("This week")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.day) { entry in
                    WeeklyStepBar(
                        day: entry.day,
                        steps: entry.steps,
                        goal: stepGoal,
                        isToday: entry.isToday,
                        isDataAvailable: entry.isDataAvailable
                    )
                }
            }
            .frame(height: 80)
        }
        .padding(20)
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

// MARK: - Weekly Step Bar

private struct WeeklyStepBar: View {
    let day: String
    let steps: Int
    let goal: Int
    let isToday: Bool
    let isDataAvailable: Bool

    private var progress: Double {
        guard isDataAvailable, goal > 0, steps > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    private var barColor: Color {
        guard isDataAvailable else { return .border.opacity(0.3) }
        if steps == 0 { return .border }
        return progress >= 1.0 ? .accentPrimary : .accentLight
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    if isDataAvailable {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(height: max(geometry.size.height * progress, steps > 0 ? 4 : 2))
                    } else {
                        // Placeholder visual for unavailable data
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor)
                            .frame(height: 2)
                    }
                }
            }

            Text(day)
                .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? .accentLavender : .textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
