//
//  PermissionsManager.swift
//  NucleOS
//
//  Handles EventKit permissions for Reminders and Calendar
//

import Combine
import EventKit
import Foundation

@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published var remindersAuthStatus: EKAuthorizationStatus = .notDetermined
    @Published var calendarAuthStatus: EKAuthorizationStatus = .notDetermined

    let eventStore = EKEventStore()

    private init() {
        updateAuthorizationStatuses()
    }

    // MARK: - Authorization Status

    func updateAuthorizationStatuses() {
        remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
        calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Request Permissions

    // NOTE: requestFullAccessToReminders() requires NSRemindersFullAccessUsageDescription in Info.plist
    // Add a user-facing description like "NucleOS needs full access to your reminders to display and manage tasks"
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

    var hasRemindersAccess: Bool {
        remindersAuthStatus == .fullAccess || remindersAuthStatus == .authorized
    }

    var hasCalendarAccess: Bool {
        calendarAuthStatus == .fullAccess || calendarAuthStatus == .authorized
    }

    var isRemindersDenied: Bool {
        remindersAuthStatus == .denied
    }

    var isCalendarDenied: Bool {
        calendarAuthStatus == .denied
    }

    var isRemindersRestricted: Bool {
        remindersAuthStatus == .restricted
    }

    var isCalendarRestricted: Bool {
        calendarAuthStatus == .restricted
    }
}