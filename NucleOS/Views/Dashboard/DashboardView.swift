//
//  DashboardView.swift
//  NucleOS
//
//  Main dashboard with health, stats, tasks, calendar, and AI briefing
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning, Edward")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Thursday, April 16")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)

                // Health strip
                HealthStripView()
                    .padding(.horizontal, 32)

                // 4-column stat row
                StatsRowView()
                    .padding(.horizontal, 32)

                // 2-column grid: Tasks + Calendar
                HStack(spacing: 20) {
                    TasksPanelView()
                    CalendarPanelView()
                }
                .padding(.horizontal, 32)

                // AI Briefing panel
                AIBriefingPanelView()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Health Strip
struct HealthStripView: View {
    var body: some View {
        HStack(spacing: 16) {
            HealthMetricCard(
                icon: "figure.walk",
                label: "Steps",
                value: "8,234",
                goal: "10,000",
                progress: 0.82,
                color: .accentLavender
            )

            HealthMetricCard(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "72",
                goal: "avg",
                progress: 0.7,
                color: .accentPrimary
            )

            HealthMetricCard(
                icon: "bed.double.fill",
                label: "Sleep",
                value: "7h 23m",
                goal: "8h",
                progress: 0.92,
                color: .accentLight
            )

            HealthMetricCard(
                icon: "flame.fill",
                label: "Calories",
                value: "1,847",
                goal: "2,200",
                progress: 0.84,
                color: Color(hex: "ff6b6b")
            )
        }
    }
}

struct HealthMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let goal: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textMuted)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("/ \(goal)")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.border)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
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

// MARK: - Stats Row
struct StatsRowView: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(label: "Tasks Today", value: "7", subtitle: "3 completed")
            StatCard(label: "Events", value: "4", subtitle: "2 upcoming")
            StatCard(label: "Completed This Week", value: "23", subtitle: "+5 from last week")
            StatCard(label: "Focus Time", value: "3h 12m", subtitle: "Today")
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textMuted)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
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

// MARK: - Tasks Panel
struct TasksPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                }
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

// MARK: - Calendar Panel
struct CalendarPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentPrimary)
                }
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

// MARK: - AI Briefing Panel
struct AIBriefingPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentLavender)

                Text("AI Briefing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("Updated 2m ago")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Good morning! Here's your daily briefing:")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)

                BriefingBullet(text: "You have 4 events today, including a design sync at 2pm")
                BriefingBullet(text: "You're 82% towards your step goal — consider a walk after lunch")
                BriefingBullet(text: "3 tasks are due today, 2 marked high priority")
                BriefingBullet(text: "Your sleep was 7h 23m last night, slightly below your 8h goal")
            }

            Button(action: {}) {
                Text("Ask AI a question")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentPrimary)
            }
            .buttonStyle(.plain)
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

struct BriefingBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    DashboardView()
}
