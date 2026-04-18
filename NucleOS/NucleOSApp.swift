//
//  NucleOSApp.swift
//  NucleOS
//
//  Created by Edward David on 4/16/26.
//

import SwiftUI

@main
struct NucleOSApp: App {

    init() {
        SentryConfig.setup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
