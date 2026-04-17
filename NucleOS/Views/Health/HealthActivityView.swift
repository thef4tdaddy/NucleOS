//
//  HealthActivityView.swift
//  NucleOS
//
//  Weekly steps bar chart and sleep breakdown card for the Health section.
//  Today's step count and sleep totals are driven by the live HealthSnapshot.
//

import SwiftUI

// MARK: - Activity View (weekly steps + sleep breakdown)

struct HealthActivityView: View {
    let snapshot: HealthSnapshot

    var body: some View {
        VStack(spacing: 24) {
            HealthWeeklyStepsCard(todaySteps: snapshot.steps, stepGoal: snapshot.stepGoal)
            HealthSleepCard(snapshot: snapshot)
        }
    }
}

// MARK: - Weekly Steps

struct HealthWeeklyStepsCard: View {
    let todaySteps: Int
    let stepGoal: Int

    private struct DayEntry {
        let day: String
        let steps: Int
        let isToday: Bool
    }

    /// Weekly step data with today's real count from the snapshot.
    /// Days after today show 0 (future); past days show placeholder data.
    /// A full history query would be needed to populate previous days with real data.
    private var weeklyData: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat. Map to Mon-Sun display.
        let orderedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        // weekday index for Monday = 2, so offset = today's weekday - 2 (mod 7)
        let todayIndex = (today + 5) % 7 // 0=Mon, 1=Tue, ..., 6=Sun

        return orderedDays.enumerated().map { index, day in
            if index == todayIndex {
                return DayEntry(day: day, steps: todaySteps, isToday: true)
            } else if index < todayIndex {
                // Placeholder for past days — shows something non-zero for visual context
                return DayEntry(day: day, steps: 0, isToday: false)
            } else {
                // Future days have no data yet
                return DayEntry(day: day, steps: 0, isToday: false)
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
                        isToday: entry.isToday
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

private struct WeeklyStepBar: View {
    let day: String
    let steps: Int
    let goal: Int
    let isToday: Bool

    private var progress: Double {
        guard goal > 0, steps > 0 else { return 0 }
        return min(Double(steps) / Double(goal), 1.0)
    }

    private var barColor: Color {
        if steps == 0 { return .border }
        return progress >= 1.0 ? .accentPrimary : .accentLight
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(height: max(geometry.size.height * progress, steps > 0 ? 4 : 2))
                }
            }

            Text(day)
                .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? .accentLavender : .textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sleep Breakdown

private struct SleepStage {
    let label: String
    let duration: String
    let color: Color
    let fraction: Double
}

struct HealthSleepCard: View {
    let snapshot: HealthSnapshot

    /// Placeholder sleep stage breakdown.
    /// Fractions are normalized to reflect typical proportions.
    /// A detailed sleep stage query (HKCategoryValueSleepAnalysis) would be required
    /// to replace these with real per-stage values.
    private let stages: [SleepStage] = [
        SleepStage(label: "Deep",  duration: "1h 45m", color: .accentPrimary,  fraction: 0.25),
        SleepStage(label: "Light", duration: "3h 12m", color: .accentLight,    fraction: 0.46),
        SleepStage(label: "REM",   duration: "1h 28m", color: .accentLavender, fraction: 0.20),
        SleepStage(label: "Awake", duration: "18m",    color: .textDim,        fraction: 0.09),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HealthSleepCardHeader(snapshot: snapshot)
            SleepStageBar(stages: stages)
            SleepStageLegend(stages: stages)
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

private struct HealthSleepCardHeader: View {
    let snapshot: HealthSnapshot

    var body: some View {
        HStack {
            Text("Sleep Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.accentLight)

                Text(snapshot.sleepFormatted)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

private struct SleepStageBar: View {
    let stages: [SleepStage]

    var body: some View {
        GeometryReader { geometry in
            let gapTotal = CGFloat(stages.count - 1) * 2
            let barTotal = geometry.size.width - gapTotal

            HStack(spacing: 2) {
                ForEach(stages, id: \.label) { stage in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stage.color)
                        .frame(width: max(barTotal * stage.fraction, 2))
                }
            }
        }
        .frame(height: 12)
    }
}

private struct SleepStageLegend: View {
    let stages: [SleepStage]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(stages, id: \.label) { stage in
                HStack(spacing: 6) {
                    Circle()
                        .fill(stage.color)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(stage.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textMuted)

                        Text(stage.duration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                }
            }

            Spacer()
        }
    }
}

#Preview {
    ScrollView {
        HealthActivityView(snapshot: MockData.healthSnapshot)
            .padding(32)
    }
    .background(Color.backgroundPrimary)
}
