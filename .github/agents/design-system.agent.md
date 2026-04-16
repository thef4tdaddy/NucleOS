# NucleOS — Design System Agent

Use this agent for any UI, visual, or layout work.

## Source of Truth
Color+Theme.swift contains all design tokens. Never hardcode hex values. Ever.

## Palette
Background primary:   nucleosBackground
Background secondary: nucleosBackgroundSecondary  
Background card:      nucleosCard
Border:               nucleosBorder
Accent primary:       nucleosAccent
Accent light:         nucleosAccentLight
Accent lavender:      nucleosLavender
Text primary:         nucleosTextPrimary
Text secondary:       nucleosTextSecondary
Text muted:           nucleosTextMuted
Text dim:             nucleosTextDim

## Design Rules
- Dark mode first, always — light mode is future
- Fixed layout — never make widgets rearrangeable
- Inspired by Copilot Money + Bevel — premium, dark, glanceable
- Health section is Bevel-inspired — rich, immersive, not clinical
- Cards use 0.5pt borders, nucleosBorder color
- Border radius: 10-12pt for cards, 8pt for elements
- No gradients except the AI briefing top border line
- Sidebar is 196pt fixed width
- Typography: two weights only — 400 regular, 500 medium

## Component Patterns
Health strip — compact, full width, progress bars, not individual cards
Stat cards — 4 column grid, large number, small label above, sub-label below
Panel — header with title + action, divider, body with list items
AI briefing — dark panel, purple gradient top line, orb glyph, model label

## Never
- Change the core palette without human approval
- Use gradients for backgrounds
- Use light mode colors
- Hardcode any hex value
