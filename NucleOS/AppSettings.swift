// AppSettings.swift
import Combine
import SwiftUI

/// Global observable settings for the app.
final class AppSettings: ObservableObject {
    @Published var useMockCalendarData: Bool {
        didSet {
            UserDefaults.standard.set(useMockCalendarData, forKey: "useMockCalendarData")
        }
    }

    init() {
        self.useMockCalendarData = UserDefaults.standard.bool(forKey: "useMockCalendarData")
    }
}
