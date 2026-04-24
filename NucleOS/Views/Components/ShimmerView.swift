//
//  ShimmerView.swift
//  NucleOS
//
//  Reusable shimmer/skeleton loader components for dashboard panels.
//  Animated gradient sweeps left-to-right using nucleosCard + nucleosAccent palette.
//

import SwiftUI

// MARK: - Base shimmer rectangle

/// A rounded rectangle that animates a left-to-right highlight sweep.
/// Size is controlled by the caller's `.frame()` modifier.
struct ShimmerView: View {
    let cornerRadius: CGFloat

    @State private var phase: CGFloat = 0

    init(cornerRadius: CGFloat = 6) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.border)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.accentPrimary.opacity(0),
                            Color.accentPrimary.opacity(0.12),
                            Color.accentPrimary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width)
                    .offset(x: -geo.size.width + geo.size.width * 2 * phase)
                    .clipped()
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Task / reminder shimmer row

/// Skeleton row matching the shape of a `TaskRow` — circle + two text bars.
struct TaskShimmerRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ShimmerView(cornerRadius: 8)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 6) {
                ShimmerView()
                    .frame(height: 12)
                ShimmerView()
                    .frame(width: 80, height: 10)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Calendar event shimmer row

/// Skeleton row matching the shape of an `EventRow` — colour bar + two text bars.
struct EventShimmerRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ShimmerView(cornerRadius: 1.5)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                ShimmerView()
                    .frame(height: 10)
                ShimmerView()
                    .frame(height: 12)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Health metric shimmer block

/// Skeleton card matching the shape of a `HealthMetricCard`.
struct HealthMetricShimmerBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ShimmerView(cornerRadius: 4)
                    .frame(width: 16, height: 16)
                Spacer()
                ShimmerView()
                    .frame(width: 40, height: 10)
            }

            VStack(alignment: .leading, spacing: 6) {
                ShimmerView()
                    .frame(width: 60, height: 20)
                ShimmerView(cornerRadius: 2)
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

// MARK: - AI briefing shimmer

/// Two text-bar skeletons matching the shape of a generated briefing.
struct AIBriefingShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShimmerView()
                .frame(height: 13)
            ShimmerView()
                .frame(height: 13)
            ShimmerView()
                .frame(width: 200, height: 13)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        TaskShimmerRow()
        EventShimmerRow()
        HStack(spacing: 16) {
            HealthMetricShimmerBlock()
            HealthMetricShimmerBlock()
        }
        AIBriefingShimmer()
    }
    .padding(24)
    .background(Color.backgroundPrimary)
    .frame(width: 600)
}
