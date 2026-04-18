# NucleOS

**Your life, one place.**

[![codecov](https://codecov.io/gh/thef4tdaddy/NucleOS/branch/main/graph/badge.svg)](https://codecov.io/gh/thef4tdaddy/NucleOS)

A macOS app that brings your calendar, tasks, health, and personal library together. Built for you, not for everyone.

---

## What is this?

You know how everyone says you need 12 different apps to "stay organized"? Calendar in one place, tasks somewhere else, health data buried in the Health app, notes scattered across three different services?

Yeah, I got tired of that too.

NucleOS is a personal life OS. It's not trying to be everything to everyone. It's a single app that pulls together the stuff that actually matters — your calendar, your tasks, your health metrics, your personal library — and gives you a clean, beautiful interface to see it all at once.

No subscriptions. No cloud syncing through some third-party service. No selling your data. Just your Mac talking to your iPhone and iPad through iCloud, the way Apple designed it.

This is for people who want their life dashboard to be _theirs_. If you're looking for the next SaaS app with a monthly fee and a "teams" plan, this isn't it.

## Features

**Calendar & Tasks**
Real-time view of your Apple Calendar events and Reminders. Not a replacement — a better frontend. Your data stays in Apple's ecosystem.

**Health Dashboard**
Steps, heart rate, sleep, calories. Pulled straight from HealthKit. Bevel-inspired design that actually looks good.

**Personal Library** _(coming soon)_
Books, articles, highlights. Your personal knowledge base. No vendor lock-in.

**AI Briefing**
On-device AI (MLX + Phi-3 mini) gives you a daily rundown. Runs locally on your Mac. Your data never leaves your machine unless you explicitly choose a cloud provider.

**Family Sharing**
Share views with family via CloudKit. Because sometimes you want your spouse to know you have that dentist appointment.

**Menu Bar Companion** _(coming soon)_
Quick glance at what's next without opening the full app.

## Philosophy

Apple's ecosystem is the brain. NucleOS is just a really nice frontend.

- **Privacy first**: Your calendar is in Calendar.app, your tasks in Reminders.app, your health in Health.app. NucleOS reads from them, displays them beautifully, but never tries to own your data.
- **No backend**: Everything syncs through iCloud. No servers to maintain, no databases to manage.
- **No subscription**: You own the app. Forever. No monthly fees, no "pro" tiers.
- **Local AI**: Default AI runs on your Mac via MLX. Want to use Claude or GPT-4? Bring your own API key.

This is the anti-SaaS. Your data is yours. Your tools should work for you.

## Tech Stack

Built with the good stuff:

- **SwiftUI** — Modern, declarative, fast
- **EventKit** — Calendar and Reminders integration
- **HealthKit** — Health data (read-only, obviously)
- **CloudKit** — Family sharing via iCloud
- **MLX + Phi-3 mini** — On-device AI that runs locally

Optional cloud AI providers (if you want them):
- Groq (fast, free tier)
- Anthropic Claude (premium, your API key)
- OpenAI (your API key)

All AI providers implement the same `LLMProvider` protocol. Swap them out whenever you want.

## Requirements

- macOS 14+ (Sonoma or later)
- Apple Silicon recommended (M1/M2/M3/M4 for optimal performance)
- Xcode 15+ if you're building from source

## Getting Started

Clone it, open it, run it:

```bash
git clone https://github.com/thef4tdaddy/NucleOS.git
cd NucleOS
open NucleOS.xcodeproj
```

Hit `Cmd + R` in Xcode. That's it.

## Roadmap

Check the [GitHub milestones](https://github.com/thef4tdaddy/NucleOS/milestones) for what's being worked on.

Current focus:
- EventKit integration (calendar + tasks) — **in progress**
- HealthKit integration
- MLX local AI
- Menu bar companion
- Personal library module

## License

MIT. Do whatever you want with it.

---

Built by [@thef4tdaddy](https://github.com/thef4tdaddy) because I wanted a better life dashboard.
