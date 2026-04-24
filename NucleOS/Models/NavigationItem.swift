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
        case .dashboard: return "square.grid.2x2"
        case .tasks: return "checklist"
        case .calendar: return "calendar"
        case .health: return "heart.fill"
        case .aiBriefing: return "sparkles"
        case .focus: return "timer"
        case .shared: return "person.2.fill"
        case .settings: return "gearshape.fill"
        }
    }

    /// Custom image asset name when a branded icon exists; `nil` falls back to SF Symbol.
    var customIconName: String? {
        switch self {
        case .tasks:      return "icon-tasks"
        case .calendar:   return "icon-calendar"
        case .health:     return "icon-health-body"
        case .aiBriefing: return "icon-ai"
        default:          return nil
        }
    }
}
