//
//  NucleOSApp.swift
//  NucleOS
//
//  Created by Edward David on 4/16/26.
//

import SwiftUI

@main
struct NucleOSApp: App {
    @StateObject private var appSettings = AppSettings()

    init() {
        SentryConfig.setup()
        // Pre-warm the shared EKEventStore so first EventKit fetch is fast
        _ = PermissionsManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}
