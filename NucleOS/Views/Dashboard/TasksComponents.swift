//
//  TasksComponents.swift
//  NucleOS
//
//  Tasks panel and task row
//

import SwiftUI

struct TasksPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {}, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                })
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                TaskRow(title: "Review quarterly goals", isCompleted: false)
                TaskRow(title: "Update project documentation", isCompleted: true)
                TaskRow(title: "Team sync at 2pm", isCompleted: false)
                TaskRow(title: "Prepare presentation slides", isCompleted: false)
                TaskRow(title: "Code review for PR #234", isCompleted: true)
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
    }
}

struct TaskRow: View {
    let title: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .accentPrimary : .textMuted)
                .font(.system(size: 16))

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(isCompleted ? .textMuted : .textPrimary)
                .strikethrough(isCompleted)

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
