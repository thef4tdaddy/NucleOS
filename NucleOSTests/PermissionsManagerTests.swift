//
//  PermissionsManagerTests.swift
//  NucleOSTests
//
//  Tests for PermissionsManager — a new file added in this PR.
//  Since PermissionsManager wraps real EventKit authorization,
//  we test the computed properties by directly mutating the published
//  authorization status properties on the shared singleton.
//
//  Note: Real permission request methods (requestRemindersAccess /
//  requestCalendarAccess) are not tested here because they would
//  attempt to pop system permission dialogs or fail without entitlements.
//

import EventKit
import XCTest
@testable import NucleOS

@MainActor
final class PermissionsManagerTests: XCTestCase {

    // MARK: - hasRemindersAccess Tests

    func testHasRemindersAccessTrueWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        XCTAssertTrue(manager.hasRemindersAccess)
    }

    func testHasRemindersAccessTrueWhenAuthorized() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .authorized
        XCTAssertTrue(manager.hasRemindersAccess)
    }

    func testHasRemindersAccessFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        XCTAssertFalse(manager.hasRemindersAccess)
    }

    func testHasRemindersAccessFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        XCTAssertFalse(manager.hasRemindersAccess)
    }

    func testHasRemindersAccessFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        XCTAssertFalse(manager.hasRemindersAccess)
    }

    // MARK: - hasCalendarAccess Tests

    func testHasCalendarAccessTrueWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        XCTAssertTrue(manager.hasCalendarAccess)
    }

    func testHasCalendarAccessTrueWhenAuthorized() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .authorized
        XCTAssertTrue(manager.hasCalendarAccess)
    }

    func testHasCalendarAccessFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        XCTAssertFalse(manager.hasCalendarAccess)
    }

    func testHasCalendarAccessFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        XCTAssertFalse(manager.hasCalendarAccess)
    }

    func testHasCalendarAccessFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .restricted
        XCTAssertFalse(manager.hasCalendarAccess)
    }

    // MARK: - isRemindersDenied Tests

    func testIsRemindersDeniedTrueWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        XCTAssertTrue(manager.isRemindersDenied)
    }

    func testIsRemindersDeniedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        XCTAssertFalse(manager.isRemindersDenied)
    }

    func testIsRemindersDeniedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        XCTAssertFalse(manager.isRemindersDenied)
    }

    func testIsRemindersDeniedFalseWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        XCTAssertFalse(manager.isRemindersDenied)
    }

    // MARK: - isCalendarDenied Tests

    func testIsCalendarDeniedTrueWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        XCTAssertTrue(manager.isCalendarDenied)
    }

    func testIsCalendarDeniedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        XCTAssertFalse(manager.isCalendarDenied)
    }

    func testIsCalendarDeniedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        XCTAssertFalse(manager.isCalendarDenied)
    }

    // MARK: - isRemindersRestricted Tests

    func testIsRemindersRestrictedTrueWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .restricted
        XCTAssertTrue(manager.isRemindersRestricted)
    }

    func testIsRemindersRestrictedFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .denied
        XCTAssertFalse(manager.isRemindersRestricted)
    }

    func testIsRemindersRestrictedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .fullAccess
        XCTAssertFalse(manager.isRemindersRestricted)
    }

    func testIsRemindersRestrictedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        XCTAssertFalse(manager.isRemindersRestricted)
    }

    // MARK: - isCalendarRestricted Tests

    func testIsCalendarRestrictedTrueWhenRestricted() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .restricted
        XCTAssertTrue(manager.isCalendarRestricted)
    }

    func testIsCalendarRestrictedFalseWhenDenied() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .denied
        XCTAssertFalse(manager.isCalendarRestricted)
    }

    func testIsCalendarRestrictedFalseWhenFullAccess() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .fullAccess
        XCTAssertFalse(manager.isCalendarRestricted)
    }

    func testIsCalendarRestrictedFalseWhenNotDetermined() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        XCTAssertFalse(manager.isCalendarRestricted)
    }

    // MARK: - Mutual exclusivity tests (denied vs restricted)

    func testDeniedAndRestrictedAreMutuallyExclusiveForReminders() {
        let manager = PermissionsManager.shared

        manager.remindersAuthStatus = .denied
        XCTAssertTrue(manager.isRemindersDenied)
        XCTAssertFalse(manager.isRemindersRestricted)

        manager.remindersAuthStatus = .restricted
        XCTAssertFalse(manager.isRemindersDenied)
        XCTAssertTrue(manager.isRemindersRestricted)
    }

    func testDeniedAndRestrictedAreMutuallyExclusiveForCalendar() {
        let manager = PermissionsManager.shared

        manager.calendarAuthStatus = .denied
        XCTAssertTrue(manager.isCalendarDenied)
        XCTAssertFalse(manager.isCalendarRestricted)

        manager.calendarAuthStatus = .restricted
        XCTAssertFalse(manager.isCalendarDenied)
        XCTAssertTrue(manager.isCalendarRestricted)
    }

    // MARK: - Access and denied/restricted are mutually exclusive

    func testHasAccessAndIsDeniedAreMutuallyExclusiveForReminders() {
        let manager = PermissionsManager.shared

        manager.remindersAuthStatus = .fullAccess
        XCTAssertTrue(manager.hasRemindersAccess)
        XCTAssertFalse(manager.isRemindersDenied)
        XCTAssertFalse(manager.isRemindersRestricted)
    }

    func testHasAccessAndIsDeniedAreMutuallyExclusiveForCalendar() {
        let manager = PermissionsManager.shared

        manager.calendarAuthStatus = .fullAccess
        XCTAssertTrue(manager.hasCalendarAccess)
        XCTAssertFalse(manager.isCalendarDenied)
        XCTAssertFalse(manager.isCalendarRestricted)
    }

    // MARK: - Shared instance is the same object

    func testSharedInstanceIsSingleton() {
        let a = PermissionsManager.shared
        let b = PermissionsManager.shared
        XCTAssertTrue(a === b)
    }

    // MARK: - Published properties change and are observable

    func testCalendarAuthStatusCanBeUpdated() {
        let manager = PermissionsManager.shared
        manager.calendarAuthStatus = .notDetermined
        XCTAssertFalse(manager.hasCalendarAccess)

        manager.calendarAuthStatus = .fullAccess
        XCTAssertTrue(manager.hasCalendarAccess)
    }

    func testRemindersAuthStatusCanBeUpdated() {
        let manager = PermissionsManager.shared
        manager.remindersAuthStatus = .notDetermined
        XCTAssertFalse(manager.hasRemindersAccess)

        manager.remindersAuthStatus = .authorized
        XCTAssertTrue(manager.hasRemindersAccess)
    }
}