// TestingSettingsView.swift
import SwiftUI

struct TestingSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calendar")) {
                    Toggle("Use Mock Calendar Data", isOn: $appSettings.useMockCalendarData)
                }
            }
            .navigationTitle("Testing Settings")
        }
    }
}

#if DEBUG
struct TestingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TestingSettingsView()
            .environmentObject(AppSettings())
    }
}
#endif
