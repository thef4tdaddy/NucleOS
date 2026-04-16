---
name: ai-layer
description: Custom Copilot cloud agent for ai-layer
target: github-copilot
---

# NucleOS — AI Layer Agent

Use this agent for any LLM, MLX, or AI provider work.

## Architecture
All LLM calls go through LLMProvider protocol. Never call a provider directly from a view.

## Provider Protocol — Sacred, Never Change Shape
protocol LLMProvider {
    var name: String { get }
    var isAvailable: Bool { get }
    func complete(prompt: String) async throws -> String
    func stream(prompt: String) -> AsyncThrowingStream<String, Error>
}

## Provider Priority
1. MLX + Phi-3 mini — bundled, on-device, default, works offline
2. Groq — free cloud tier, fast, Llama 3 / Gemma
3. Anthropic — premium, user's own API key
4. OpenAI — optional, user's own API key

## MLX (Default Provider)
- Use MLX Swift package
- Phi-3 mini 4-bit quantized model bundled in app
- Runs entirely on device — no internet, no API key
- Optimized for Apple Silicon M-series
- ~2GB model size, fast on M1+

## Groq Provider
- Base URL: https://api.groq.com/openai/v1
- OpenAI-compatible API
- User provides API key in Settings
- Default model: llama3-8b-8192
- Free tier, generous limits

## Anthropic Provider
- Use Anthropic messages API
- User provides API key in Settings
- Model: claude-sonnet-4-20250514
- For users with existing Claude subscription

## OpenAI Provider
- Standard OpenAI API
- User provides API key in Settings
- Model: gpt-4o-mini default

## AI Features
- Morning briefing — summarize day, tasks, health
- Task suggestions — break down overdue tasks
- Smart scheduling — suggest focus blocks
- All prompts are local first — MLX handles them by default

## Settings Storage
- API keys stored in Keychain — never UserDefaults
- Selected provider stored in UserDefaults
- Never log API keys anywhere

## Never
- Call LLM APIs from views directly
- Store API keys in UserDefaults or plain text
- Make AI features require internet by default
- Change the LLMProvider protocol shape without human approval
