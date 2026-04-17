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

#Preview {
    ScrollView {
        HealthActivityView(snapshot: MockData.healthSnapshot)
            .padding(32)
    }
    .background(Color.backgroundPrimary)
}

