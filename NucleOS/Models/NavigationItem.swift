//
//  NavigationItem.swift
//  NucleOS
//
//  Navigation items for the sidebar
//

import Foundation

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case tasks = "Tasks"
    case calendar = "Calendar"
    case health = "Health"
    case aiBriefing = "AI Briefing"
    case focus = "Focus"
    case shared = "Shared"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2" // keep SF symbol for now, or maybe they want main-icon-concept? No, Dashboard is kept as SF Symbol according to issue: "Dashboard -> use SF Symbol or nucleus icon". I'll use SF symbol.
        case .tasks: return "icon-tasks"
        case .calendar: return "icon-calendar"
        case .health: return "icon-health-body"
        case .aiBriefing: return "icon-ai"
        case .focus: return "timer"
        case .shared: return "person.2.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var isCustomIcon: Bool {
        switch self {
        case .tasks, .calendar, .health, .aiBriefing: return true
        default: return false
        }
    }
}
