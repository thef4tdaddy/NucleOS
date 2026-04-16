# NucleOS — Main Agent

Read CLAUDE.md first. Always. It has the full vision, design tokens, architecture, and build order.

## What You Are
The main NucleOS coding agent. You handle general tasks across the codebase. For specialized tasks use the appropriate agent file.

## Folder Ownership
- Views/ — UI components, SwiftUI views
- Models/ — Swift data models
- Services/ — Apple service wrappers
- AI/ — LLM provider protocol and implementations
- Extensions/ — Swift helpers and extensions

## Specialist Agents
Point Copilot at these for domain-specific work:
- design-system.agent.md — any UI, colors, layout work
- apple-services.agent.md — EventKit, HealthKit, CloudKit
- ai-layer.agent.md — LLM providers, MLX, on-device AI

## Build Order
1. NavigationSplitView shell + sidebar
2. Dashboard layout with mock data
3. EventKit — Reminders + Calendar
4. HealthKit integration
5. MLX + Phi-3 mini on-device AI
6. Menu bar companion
7. CloudKit family sharing
8. Additional LLM providers

## Always Ask a Human Before
- Changing app architecture
- Adding third-party dependencies
- Modifying NucleOSApp.swift root structure
- Changing color palette or design tokens
- Anything touching CloudKit family data
- Any monetization logic
