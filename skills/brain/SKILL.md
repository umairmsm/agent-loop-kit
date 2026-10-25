---
name: brain
description: View and switch the active AI supervisor model (Claude, Qwen3-Coder 480B, DeepSeek, Gemini, Local Ollama) and view token budget/context telemetry.
---

# Multi-Brain Supervisor Model Controller

Use this skill whenever the user asks to switch models, check context window size, view token telemetry, or check supervisor health.

## Quick CLI Usage
Run using Bash:
- `brain`: Display the active model HUD, context window size, and token telemetry.
- `brain 1` or `brain claude`: Switch primary supervisor to Claude 3.5 / 4.
- `brain 2` or `brain qwen`: Switch primary supervisor to Qwen3-Coder 480B (1M context, $0).
- `brain 3` or `brain deepseek`: Switch primary supervisor to DeepSeek V4.1 Flash (1M context).
- `brain 4` or `brain gemini`: Switch primary supervisor to Gemini 3.8 Flash High (1M context).
- `brain 5` or `brain local`: Switch primary supervisor to Local DeepSeek-R1 (100% offline).
- `brain status`: Display all providers, rate-limit cooldowns, and readiness.
- `brain key`: Configure API key securely without leaking in logs.

When the user asks to switch a model or check telemetry, run the `brain` command via Bash and report the updated status.
