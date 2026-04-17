//
//  HealthSleepCard.swift
//  NucleOS
//
//  Sleep breakdown card for the Health section.
//  Total sleep duration is driven by the live HealthSnapshot.
//

import SwiftUI

// MARK: - Sleep Stage Model

private struct SleepStage {
    let label: String
    let duration: String
    let color: Color
    let fraction: Double
}

// MARK: - Sleep Card

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

// MARK: - Sleep Card Header

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

// MARK: - Sleep Stage Bar

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

// MARK: - Sleep Stage Legend

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
