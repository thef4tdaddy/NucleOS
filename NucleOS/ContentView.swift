//
//  ContentView.swift
//  NucleOS
//
//  Root view with NavigationSplitView
//

import SwiftUI

struct ContentView: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                SidebarView(selectedItem: $selectedItem)
            },
            detail: {
                Group {
                    switch selectedItem {
                    case .dashboard:
                        DashboardView()
                    case .tasks:
                        TasksView()
                    case .calendar:
                        CalendarView()
                    case .health:
                        PlaceholderView(title: "Health")
                    case .aiBriefing:
                        PlaceholderView(title: "AI Briefing")
                    case .focus:
                        PlaceholderView(title: "Focus")
                    case .shared:
                        PlaceholderView(title: "Shared")
                    case .settings:
                        PlaceholderView(title: "Settings")
                    case .none:
                        PlaceholderView(title: "Select an item")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundPrimary)
            }
        )
        .navigationSplitViewStyle(.balanced)
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

#Preview {
    ContentView()
}
