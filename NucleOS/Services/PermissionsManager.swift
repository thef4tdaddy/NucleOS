//
//  PermissionsManager.swift
//  NucleOS
//
//  Handles EventKit permissions for Reminders and Calendar
//

import Combine
import EventKit
import Foundation

/// Centralised manager for EventKit authorization status and permission requests.
/// All mutations are isolated to the `@MainActor` so published values drive SwiftUI updates safely.
@MainActor
final class PermissionsManager: ObservableObject {
    /// The singleton instance shared across the app.
    static let shared = PermissionsManager()

    /// Current authorization status for Reminders.
    @Published var remindersAuthStatus: EKAuthorizationStatus = .notDetermined
    /// Current authorization status for Calendar events.
    @Published var calendarAuthStatus: EKAuthorizationStatus = .notDetermined

    /// The shared `EKEventStore` used by all EventKit services.
    let eventStore = EKEventStore()

    /// Initialises the shared instance and reads the current authorization statuses.
    private init() {
        updateAuthorizationStatuses()
    }

    // MARK: - Authorization Status

    /// Reads the current EventKit authorization status for Reminders and Calendar
    /// and updates the published properties.
    func updateAuthorizationStatuses() {
        remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
        calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Request Permissions

    // NOTE: requestFullAccessToReminders() requires NSRemindersFullAccessUsageDescription in Info.plist
    // Add a user-facing description like "NucleOS needs full access to your reminders to display and manage tasks"
    /// Requests full Reminders access and updates `remindersAuthStatus`.
    /// - Returns: `true` if access was granted.
    func requestRemindersAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
            return granted
        } catch {
            print("Error requesting reminders access: \(error)")
            // Re-query actual system status instead of assuming .denied
            remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
            return false
        }
    }

    /// Requests full Calendar access and updates `calendarAuthStatus`.
    /// - Returns: `true` if access was granted.
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            print("Error requesting calendar access: \(error)")
            // Re-query actual system status instead of assuming .denied
            calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    // MARK: - Permission Checks

    /// `true` when the app has full or legacy authorized access to Reminders.
    var hasRemindersAccess: Bool {
        remindersAuthStatus == .fullAccess
    }

    /// `true` when the app has full or legacy authorized access to Calendar.
    var hasCalendarAccess: Bool {
        calendarAuthStatus == .fullAccess
    }

    /// `true` when the user has explicitly denied Reminders access.
    var isRemindersDenied: Bool {
        remindersAuthStatus == .denied
    }

    /// `true` when the user has explicitly denied Calendar access.
    var isCalendarDenied: Bool {
        calendarAuthStatus == .denied
    }

    /// `true` when Reminders access is restricted by parental controls or a device policy.
    var isRemindersRestricted: Bool {
        remindersAuthStatus == .restricted
    }

    /// `true` when Calendar access is restricted by parental controls or a device policy.
    var isCalendarRestricted: Bool {
        calendarAuthStatus == .restricted
    }
}
