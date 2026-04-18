//
//  PermissionsManagerTests.swift
//  NucleOSTests
//
//  Tests for PermissionsManager computed properties by directly mutating
//  the published authorization status properties on the shared singleton.
//  Real permission request methods are not tested here — they would attempt
//  to pop system permission dialogs or fail without entitlements.
//

import EventKit
import Foundation
import Testing
@testable import NucleOS

@MainActor
@Suite("Permissions Manager")
struct PermissionsManagerTests {

    // MARK: - hasRemindersAccess

    @Test("hasRemindersAccess is true when fullAccess")
    func hasRemindersAccessTrueWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        #expect(manager.hasRemindersAccess)
    }

    @Test("hasRemindersAccess is true when authorized")
    func hasRemindersAccessTrueWhenAuthorized() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .authorized
        #expect(manager.hasRemindersAccess)
    }

    @Test("hasRemindersAccess is false when denied")
    func hasRemindersAccessFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        #expect(!manager.hasRemindersAccess)
    }

    @Test("hasRemindersAccess is false when notDetermined")
    func hasRemindersAccessFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        #expect(!manager.hasRemindersAccess)
    }

    @Test("hasRemindersAccess is false when restricted")
    func hasRemindersAccessFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        #expect(!manager.hasRemindersAccess)
    }

    // MARK: - hasCalendarAccess

    @Test("hasCalendarAccess is true when fullAccess")
    func hasCalendarAccessTrueWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        #expect(manager.hasCalendarAccess)
    }

    @Test("hasCalendarAccess is true when authorized")
    func hasCalendarAccessTrueWhenAuthorized() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .authorized
        #expect(manager.hasCalendarAccess)
    }

    @Test("hasCalendarAccess is false when denied")
    func hasCalendarAccessFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        #expect(!manager.hasCalendarAccess)
    }

    @Test("hasCalendarAccess is false when notDetermined")
    func hasCalendarAccessFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        #expect(!manager.hasCalendarAccess)
    }

    @Test("hasCalendarAccess is false when restricted")
    func hasCalendarAccessFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .restricted
        #expect(!manager.hasCalendarAccess)
    }

    // MARK: - isRemindersDenied

    @Test("isRemindersDenied is true when denied")
    func isRemindersDeniedTrueWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        #expect(manager.isRemindersDenied)
    }

    @Test("isRemindersDenied is false when notDetermined")
    func isRemindersDeniedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        #expect(!manager.isRemindersDenied)
    }

    @Test("isRemindersDenied is false when fullAccess")
    func isRemindersDeniedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        #expect(!manager.isRemindersDenied)
    }

    @Test("isRemindersDenied is false when restricted")
    func isRemindersDeniedFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        #expect(!manager.isRemindersDenied)
    }

    // MARK: - isCalendarDenied

    @Test("isCalendarDenied is true when denied")
    func isCalendarDeniedTrueWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        #expect(manager.isCalendarDenied)
    }

    @Test("isCalendarDenied is false when notDetermined")
    func isCalendarDeniedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        #expect(!manager.isCalendarDenied)
    }

    @Test("isCalendarDenied is false when fullAccess")
    func isCalendarDeniedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        #expect(!manager.isCalendarDenied)
    }

    // MARK: - isRemindersRestricted

    @Test("isRemindersRestricted is true when restricted")
    func isRemindersRestrictedTrueWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        #expect(manager.isRemindersRestricted)
    }

    @Test("isRemindersRestricted is false when denied")
    func isRemindersRestrictedFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        #expect(!manager.isRemindersRestricted)
    }

    @Test("isRemindersRestricted is false when fullAccess")
    func isRemindersRestrictedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        #expect(!manager.isRemindersRestricted)
    }

    @Test("isRemindersRestricted is false when notDetermined")
    func isRemindersRestrictedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        #expect(!manager.isRemindersRestricted)
    }

    // MARK: - isCalendarRestricted

    @Test("isCalendarRestricted is true when restricted")
    func isCalendarRestrictedTrueWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .restricted
        #expect(manager.isCalendarRestricted)
    }

    @Test("isCalendarRestricted is false when denied")
    func isCalendarRestrictedFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        #expect(!manager.isCalendarRestricted)
    }

    @Test("isCalendarRestricted is false when fullAccess")
    func isCalendarRestrictedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        #expect(!manager.isCalendarRestricted)
    }

    @Test("isCalendarRestricted is false when notDetermined")
    func isCalendarRestrictedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        #expect(!manager.isCalendarRestricted)
    }

    // MARK: - Mutual exclusivity

    @Test("denied and restricted are mutually exclusive for reminders")
    func deniedAndRestrictedAreMutuallyExclusiveForReminders() {
        let manager = PermissionsManager.shared

        manager.remindersAuthStatus = .denied
        #expect(manager.isRemindersDenied)
        #expect(!manager.isRemindersRestricted)

        manager.remindersAuthStatus = .restricted
        #expect(!manager.isRemindersDenied)
        #expect(manager.isRemindersRestricted)
    }

    @Test("denied and restricted are mutually exclusive for calendar")
    func deniedAndRestrictedAreMutuallyExclusiveForCalendar() {
        let manager = PermissionsManager.shared

        manager.calendarAuthStatus = .denied
        #expect(manager.isCalendarDenied)
        #expect(!manager.isCalendarRestricted)

        manager.calendarAuthStatus = .restricted
        #expect(!manager.isCalendarDenied)
        #expect(manager.isCalendarRestricted)
    }

    @Test("hasAccess and isDenied are mutually exclusive for reminders")
    func hasAccessAndIsDeniedAreMutuallyExclusiveForReminders() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        #expect(manager.hasRemindersAccess)
        #expect(!manager.isRemindersDenied)
        #expect(!manager.isRemindersRestricted)
    }

    @Test("hasAccess and isDenied are mutually exclusive for calendar")
    func hasAccessAndIsDeniedAreMutuallyExclusiveForCalendar() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        #expect(manager.hasCalendarAccess)
        #expect(!manager.isCalendarDenied)
        #expect(!manager.isCalendarRestricted)
    }

    // MARK: - Published properties are observable

    @Test("calendarAuthStatus can be updated")
    func calendarAuthStatusCanBeUpdated() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        #expect(!manager.hasCalendarAccess)
        manager.calendarAuthStatus = .fullAccess
        #expect(manager.hasCalendarAccess)
    }

    @Test("remindersAuthStatus can be updated")
    func remindersAuthStatusCanBeUpdated() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        #expect(!manager.hasRemindersAccess)
        manager.remindersAuthStatus = .authorized
        #expect(manager.hasRemindersAccess)
    }
}
