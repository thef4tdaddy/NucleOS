# NucleOS

> Your life's mission control — built on Apple's ecosystem, enhanced by AI

![NucleOS Screenshot](docs/screenshot-placeholder.png)
*Screenshot coming soon*

## What is NucleOS?

NucleOS is a macOS-first life dashboard app with a beautiful dark purple UI that acts as a frontend shell over Apple's ecosystem. It's privacy-first, requires no backend, no subscription, and syncs seamlessly through iCloud.

Think Fantastical meets Bevel meets Linear — but yours, free, and powered by on-device AI.

## Key Features

- **📋 Unified Task Management** - Frontend for Apple Reminders with a modern, powerful interface
- **📅 Smart Calendar** - EventKit integration with intelligent views and AI-powered insights
- **❤️ Health Dashboard** - Beautiful HealthKit integration tracking steps, heart rate, sleep, and calories
- **✨ AI Briefing** - On-device AI (MLX + Phi-3 mini) provides daily insights and intelligent assistance
- **👨‍👩‍👧‍👦 Family Sharing** - CloudKit-powered sharing with family members via iCloud
- **⚡️ Menu Bar Companion** - Lightweight always-on quick access to your most important data
- **🎨 Beautiful Dark Purple Aesthetic** - Fixed, polished layout inspired by modern design systems

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **EventKit** - Native integration with Reminders and Calendar
- **HealthKit** - Deep health data integration
- **CloudKit** - iCloud syncing and Family Sharing
- **MLX + Phi-3 mini** - On-device AI (bundled, offline-first)
- **Groq, Anthropic Claude, OpenAI** - Optional cloud AI providers

All AI providers implement a common `LLMProvider` Swift protocol for seamless switching.

## Requirements

- **macOS 14.0+** (Sonoma or later)
- **Apple Silicon recommended** (M1/M2/M3 for optimal MLX performance)
- **Xcode 15.0+** for development

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/thef4tdaddy/NucleOS.git
   cd NucleOS
   ```

2. **Open in Xcode**
   ```bash
   open NucleOS.xcodeproj
   ```

3. **Build and run**
   - Press `Cmd + R` or click the Run button
   - Select your Mac as the destination

## Roadmap

NucleOS follows a progressive development approach:

1. ✅ **NavigationSplitView shell** - Purple sidebar and navigation structure
2. ✅ **Dashboard layout** - Stat cards, health strip, task panel, calendar panel, AI briefing
3. 🚧 **EventKit integration** - Reminders + Calendar data
4. 🔜 **HealthKit integration** - Real health metrics
5. 🔜 **MLX + Phi-3 mini** - On-device AI
6. 🔜 **Menu bar companion** - Quick access widget
7. 🔜 **CloudKit family sharing** - iCloud sync across devices
8. 🔜 **Additional LLM providers** - Groq, Anthropic, OpenAI support

## Architecture

NucleOS is designed with a clear separation of concerns:

- Apple's ecosystem (Reminders, Calendar, Health) is the **brain**
- NucleOS is the **beautiful frontend**
- No Core Data, no custom backend, privacy-first

See [CLAUDE.md](CLAUDE.md) for detailed architecture and development guidance.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details

---

Built with ❤️ by [thef4tdaddy](https://github.com/thef4tdaddy)
