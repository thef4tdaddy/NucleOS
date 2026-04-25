//
//  PermissionBanner.swift
//  NucleOS
//
//  Purple warning banner shown when the user has denied or restricted access
//  to Calendar, Reminders, or Health. Tapping "Open Settings" deep-links to
//  the relevant System Settings privacy pane.
//

import SwiftUI

// MARK: - Permission type

/// Identifies which system permission the banner is requesting.
enum PermissionType {
    case reminders
    case calendar
    case health

    var message: String {
        switch self {
        case .reminders: return "NucleOS needs Reminders access to show your tasks"
        case .calendar:  return "NucleOS needs Calendar access to show your events"
        case .health:    return "NucleOS needs Health access to show your metrics"
        }
    }

    var settingsURL: URL {
        switch self {
        case .reminders:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")!
        case .calendar:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!
        case .health:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Health")!
        }
    }
}

// MARK: - Banner view

/// Compact banner that prompts the user to grant a denied permission.
///
/// Place this at the top of any view whose content requires the given permission.
/// The banner dismisses automatically when the app returns to the foreground
/// with the permission granted — handled by the parent view's foreground observer.
struct PermissionBanner: View {
    let permission: PermissionType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.accentLavender)

            Text(permission.message)
                .font(.system(size: 13))
                .foregroundColor(.accentLavender)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Open Settings") {
                NSWorkspace.shared.open(permission.settingsURL)
            }
            .nucleosPrimaryButton()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentPrimary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentLavender.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PermissionBanner(permission: .reminders)
        PermissionBanner(permission: .calendar)
        PermissionBanner(permission: .health)
    }
    .padding(24)
    .background(Color.backgroundPrimary)
    .frame(width: 600)
}
