# NucleOS — Copilot Instructions

## Project
macOS life dashboard. SwiftUI frontend over Apple ecosystem services. Dark purple aesthetic. No backend.

## Code Rules
- SwiftUI only — no UIKit unless absolutely unavoidable
- No force unwraps (!) — use guard/if let
- Use async/await for all async operations
- Use @MainActor for UI updates
- Keep views under 200 lines — extract subviews aggressively
- Never put business logic in views
- Every service needs a protocol for mocking
- Never hardcode hex colors — use Color+Theme.swift tokens
- Never add Core Data
- Never hardcode API keys or credentials

## Commits
Follow conventional commits strictly:
feat(scope): description
fix(scope): description
style(scope): description
refactor(scope): description
chore(scope): description

## Branching
- Never push to `main` or `develop` directly
- Always branch from `develop`
- Always PR into `develop`
- Branch naming: feature/*, fix/*, style/*, refactor/*, chore/*

## PR Rules
- Always fill out PULL_REQUEST_TEMPLATE.md completely
- Include screenshots if any UI changed
- Note any new dependencies
