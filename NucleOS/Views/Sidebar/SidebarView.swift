//
//  SidebarView.swift
//  NucleOS
//
//  Purple sidebar with navigation items
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem?

    var body: some View {
        VStack(spacing: 0) {
            // Logo section
            VStack(spacing: 8) {
                NucleusLogo()
                    .frame(width: 32, height: 32)

                Text("NucleOS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .padding(.top, 24)
            .padding(.bottom, 32)

            // Navigation items
            ScrollView(content: {
                VStack(spacing: 4) {
                    // Main section
                    SectionLabel(title: "MAIN")

                    ForEach([NavigationItem.dashboard, .tasks, .calendar, .health], content: { item in
                        NavigationItemRow(
                            item: item,
                            isSelected: selectedItem == item,
                            action: { selectedItem = item }
                        )
                    })

                    // AI section
                    SectionLabel(title: "AI")
                        .padding(.top, 16)

                    ForEach([NavigationItem.aiBriefing, .focus], content: { item in
                        NavigationItemRow(
                            item: item,
                            isSelected: selectedItem == item,
                            action: { selectedItem = item }
                        )
                    })

                    // Other section
                    SectionLabel(title: "OTHER")
                        .padding(.top, 16)

                    ForEach([NavigationItem.shared, .settings], content: { item in
                        NavigationItemRow(
                            item: item,
                            isSelected: selectedItem == item,
                            action: { selectedItem = item }
                        )
                    })
                }
                .padding(.horizontal, 12)
            })

            Spacer()

            // User avatar at bottom
            UserAvatarView()
                .padding(.bottom, 16)
                .padding(.horizontal, 12)
        }
        .frame(width: 240)
        .background(Color.backgroundSecondary)
    }
}

struct NucleusLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentLavender.opacity(0.3), lineWidth: 1.5)
                .frame(width: 32, height: 32)

            Circle()
                .stroke(Color.accentLight.opacity(0.5), lineWidth: 1.5)
                .frame(width: 22, height: 22)

            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 12, height: 12)
        }
    }
}

struct NavigationItemRow: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 12) {
                // Purple dot indicator
                Circle()
                    .fill(isSelected ? Color.accentPrimary : Color.clear)
                    .frame(width: 6, height: 6)

                // Icon — custom asset when available, SF Symbol otherwise
                if let customIcon = item.customIconName {
                    Image(customIcon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(isSelected ? .accentLight : .textSecondary)
                } else {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                        .frame(width: 20)
                }

                // Label
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentPrimary.opacity(0.15) : Color.clear)
            )
        })
        .buttonStyle(.plain)
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
                .tracking(0.5)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct UserAvatarView: View {
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.accentPrimary, .accentLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text("ED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Edward David")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)

                Text("Free Plan")
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundCard)
        )
    }
}

#Preview {
    SidebarView(selectedItem: .constant(.dashboard))
}
