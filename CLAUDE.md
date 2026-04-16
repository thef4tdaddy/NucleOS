# NucleOS

A macOS-first life dashboard app. Beautiful dark purple UI that acts as a frontend shell over Apple's ecosystem. No backend, no subscription, privacy-first.

## Vision
Fantastical meets Bevel meets Linear — but yours, free, with AI. A "mission control for your life" that syncs through Apple and is shareable with family.

## Design
- Dark purple aesthetic — deep blacks (#08060f, #0b0915) with lavender accents (#c4b5fd, #7c5cf0)
- Fixed but beautiful layout — not rearrangeable widgets
- Simple modern OS-style, inspired by Copilot Money app and Bevel
- Dark mode first, light mode later

## Architecture
Apple ecosystem is the brain, NucleOS is the frontend:
- Reminders → EventKit (tasks)
- Calendar → EventKit (events)
- Health → HealthKit (steps, heart rate, sleep, calories)
- Sync → CloudKit (iCloud + Family Sharing)
- NO Core Data, NO custom backend

## LLM Layer (priority order)
1. MLX + Phi-3 mini (bundled, on-device, default, offline)
2. Groq (free cloud tier, fast)
3. Anthropic Claude (premium, user's own API key)
4. OpenAI (optional)
All providers implement a common `LLMProvider` Swift protocol.

## App Structure
- Full window macOS app + menu bar companion
- NavigationSplitView: sidebar + main content area
- Menu bar: lightweight always-on quick access

## Folder Structure
NucleOS/
├── Views/
│   ├── Dashboard/     ← main home view
│   ├── Tasks/         ← Reminders frontend
│   ├── Calendar/      ← EventKit frontend
│   ├── Health/        ← HealthKit frontend (Bevel-inspired)
│   ├── Sidebar/       ← navigation sidebar
│   └── Menubar/       ← menu bar popover
├── Models/            ← Swift data models
├── Services/          ← EventKit, HealthKit, CloudKit wrappers
├── AI/                ← LLM provider protocol + implementations
├── Extensions/        ← Swift extensions and helpers
├── ContentView.swift  ← root view, NavigationSplitView
└── NucleOSApp.swift   ← app entry, menu bar setup

## Current Stack
- SwiftUI + Swift
- macOS 14+ target
- M1 MacBook Air (Apple Silicon)
- Xcode, Claude Code in terminal alongside

## Build Order
1. NavigationSplitView shell + purple sidebar
2. Dashboard layout (stat cards, health strip, task panel, calendar panel, AI briefing)
3. EventKit integration (Reminders + Calendar)
4. HealthKit integration
5. MLX + Phi-3 mini on-device AI
6. Menu bar companion
7. CloudKit family sharing
8. Additional LLM providers (Groq, Anthropic, OpenAI)

## Design Tokens
Background primary: #08060f
Background secondary: #0b0915
Background card: #0d0b1a
Border: #17122a
Accent primary: #5b3fd4
Accent light: #7c5cf0
Accent lavender: #c4b5fd
Text primary: #ede9ff
Text secondary: #b8aedd
Text muted: #6a5a8a
Text dim: #3a2f52