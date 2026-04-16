//
//  CalendarComponents.swift
//  NucleOS
//
//  Calendar panel and event row
//

import SwiftUI

struct CalendarPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calendar")
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
                EventRow(time: "9:00 AM", title: "Team Standup", color: .accentPrimary)
                EventRow(time: "11:00 AM", title: "Product Review", color: .accentLavender)
                EventRow(time: "2:00 PM", title: "Design Sync", color: .accentLight)
                EventRow(time: "4:30 PM", title: "1:1 with Manager", color: Color(hex: "ff6b6b"))
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

struct EventRow: View {
    let time: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(color)
                .frame(width: 3, height: 32)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
