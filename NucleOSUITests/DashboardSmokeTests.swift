//
//  DashboardSmokeTests.swift
//  NucleOSUITests
//
//  Swift Testing UI smoke tests for the Dashboard.
//  Requires NucleOSUITests target to be added to the Xcode project.
//

import Testing
import XCTest

@Suite("Dashboard Smoke Tests")
final class DashboardSmokeTests {

    let app = XCUIApplication()

    // MARK: - Launch

    @Test("App launches without crash")
    func appLaunchesWithoutCrash() {
        app.launch()
        #expect(app.state == .runningForeground)
        app.terminate()
    }

    @Test("Dashboard view appears after launch")
    func dashboardViewAppears() {
        app.launch()
        // The Dashboard content area should exist
        let dashboard = app.otherElements["DashboardView"]
        #expect(dashboard.exists)
        app.terminate()
    }

    @Test("Health strip is visible on dashboard")
    func healthStripVisible() {
        app.launch()
        let healthStrip = app.otherElements["HealthStripView"]
        #expect(healthStrip.waitForExistence(timeout: 3))
        app.terminate()
    }

    @Test("Sidebar navigation items are present")
    func sidebarNavigationItemsPresent() {
        app.launch()
        // NavigationSplitView sidebar should have at least one item
        let sidebar = app.splitGroups.firstMatch
        #expect(sidebar.exists)
        app.terminate()
    }

    @Test("Tasks panel is visible on dashboard")
    func tasksPanelVisible() {
        app.launch()
        let tasksPanel = app.otherElements["TasksPanel"]
        #expect(tasksPanel.waitForExistence(timeout: 3))
        app.terminate()
    }

    @Test("Calendar panel is visible on dashboard")
    func calendarPanelVisible() {
        app.launch()
        let calendarPanel = app.otherElements["CalendarPanel"]
        #expect(calendarPanel.waitForExistence(timeout: 3))
        app.terminate()
    }

    @Test("AI briefing section is visible on dashboard")
    func aiBriefingSectionVisible() {
        app.launch()
        let aiBriefing = app.otherElements["AIBriefingView"]
        #expect(aiBriefing.waitForExistence(timeout: 3))
        app.terminate()
    }
}
