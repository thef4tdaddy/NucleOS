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
│   ├── Dashboard/     ← main home view (DashboardView + Health/Stats/Tasks/Calendar/AIBriefing components)
│   ├── Tasks/         ← Reminders frontend (read-only)
│   ├── Calendar/      ← EventKit frontend (day/week/month range)
│   ├── Health/        ← HealthKit frontend, Bevel-inspired (HealthView, ActivityView, SleepCard, WeeklyStepsCard)
│   ├── Sidebar/       ← purple navigation sidebar
│   └── Menubar/       ← menu bar popover (planned)
├── Models/            ← NucleTask, NucleEvent, HealthSnapshot, NavigationItem, MockData
├── Services/          ← EventKit, HealthKit, CloudKit, AIBriefingService wrappers — BUILT
├── ViewModels/        ← HealthViewModel, AIBriefingViewModel
├── AI/                ← LLMProvider protocol, providers, HealthSummaryPromptBuilder — BUILT
├── Extensions/        ← KeychainHelper, Color+Theme, Date+Dashboard
├── Config/            ← SentryConfig
├── ContentView.swift  ← root view, NavigationSplitView
└── NucleOSApp.swift   ← app entry, Sentry init

Note: AIBriefingService lives in Services/ (not AI/) because it acts as an
orchestration service that routes between providers, consistent with the
Services/ pattern used by RemindersService, CalendarService, HealthService.

## Current Stack
- SwiftUI + Swift
- macOS 14+ target
- M1 MacBook Air (Apple Silicon)
- Xcode, Claude Code in terminal alongside

## Build Order
1. ✅ NavigationSplitView shell + purple sidebar
2. ✅ Dashboard layout (stat cards, health strip, task panel, calendar panel, AI briefing)
3. ✅ EventKit integration (Reminders + Calendar) — read-only; mutations (add/complete/delete) not yet implemented
4. ✅ HealthKit integration — steps, heart rate, sleep, calories with permission state machine
5. ✅ MLX + Phi-3 mini on-device AI — actor-isolated, zero network, offline inference
6. ✅ Groq provider — llama3-8b-8192, OpenAI-compatible, rate-limit handling, Keychain storage
7. ✅ AI Briefing layer — multi-provider orchestration (MLX → Groq → Claude → OpenAI), health context opt-in
8. ✅ Error tracking — Sentry integration with traced operations
9. ✅ Test suite — 17 unit tests + 1 UI smoke test, mocks for all services
10. ⏳ Menu bar companion — planned, not yet built
11. ⏳ Task mutations — addTask(), completeTask(), deleteTask() stubs exist in RemindersService
12. ⏳ Claude provider — Keychain key defined, throws notImplemented
13. ⏳ OpenAI provider — Keychain key defined, throws notImplemented
14. ⏳ CloudKit family sharing — protocol stub + SharedData model, no sync logic yet

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