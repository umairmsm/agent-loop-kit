# Architecture: agent-loop-kit

`agent-loop-kit` enforces an autonomous **Separation of Powers** between coding agents. One agent builds; an independent reviewer gates, tests, and critiques every commit.

---

## 1. Core Principle: Separation of Powers

Single-agent loops frequently hallucinate, weaken test suites to make them pass, or loop endlessly when stuck. `agent-loop-kit` solves this by strictly isolating the Builder from the Reviewer:

```
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│          BUILDER AGENT          │           │         REVIEWER AGENT          │
│   (Antigravity / Codex / Aider) │           │          (Claude Code)          │
│                                 │           │                                 │
│  1. Commits step on git branch  │           │  3. Runs gate.sh in worktree    │
│  2. Writes ag_status.json       │           │  4. Runs step/security reviewer │
│  7. Fixes code on review fail   │           │  5. Writes review.json          │
└────────────────┬────────────────┘           └────────────────▲────────────────┘
                 │                                             │
                 ▼                                             │
          ┌────────────────────────────────────────────────────┴┐
          │            The Supervision Channel (.supervision/)  │
          │  - ag_status.json (Builder's state & SHA)           │
          │  - review.json    (Reviewer's verdict & fix_list)   │
          │  - evidence/      (Raw logs of tests, lints, probes)│
          └─────────────────────────────────────────────────────┘
```

The repository itself is the only communication channel between agents. The Builder never runs reviewer tooling, and the Reviewer never edits the Builder's code.

---

## 2. The Supervision State Machine

```
              ┌────────────────────────────────────────────────┐
              │             Builder commits Step N             │
              └───────────────────────┬────────────────────────┘
                                      │
                                      ▼
                      Writes ag_status.json (READY_FOR_REVIEW)
                                      │
                                      ▼
                        ┌───────────────────────────┐
                        │      gate.sh Runs         │
                        │ (Isolated detached worktree)│
                        └─────────────┬─────────────┘
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                     Gate PASS                 Gate FAIL
                         │                         │
                         ▼                         ▼
              ┌────────────────────┐      ┌─────────────────┐
              │  Reviewer Subagent │      │ CHANGES_REQUIRED│
              │ (Diff vs Spec)     │      │ (Fixes list)    │
              └──────────┬─────────┘      └────────┬────────┘
                         │                         │
             ┌───────────┴───────────┐             │
             │                       │             │
        APPROVED              CHANGES_REQUIRED     │
             │                       │             │
             ▼                       ▼             │
      Step N+1 Starts        Builder fixes in turn ◄
```

---

## 3. Tiered Review Architecture

To optimize model token budgets and latency:
1. **Tier 1 (Mechanical Gate)**: `gate.sh` runs inside a throwaway git worktree (`git worktree add --detach`). It executes runtime tests, linters, formatters, secret scanners (`gitleaks`), test-deletion checkers, and custom project probes.
2. **Tier 2 (Standard Reviewer - Sonnet)**: `agents/step-reviewer.md` checks diff against the written task specification, verifies test quality, and conducts live checks.
3. **Tier 3 (Adversarial Security Reviewer - Opus)**: `agents/security-reviewer.md` automatically activates on steps tagged `[security]`. It mutates scoping lines and attempts concrete bypass attacks before signing off.
4. **Escalations (Human/Supervisor)**: Decisions involving secrets, schema changes, payments, or infrastructure always trigger `escalate: true`.

---

## 4. Tamper Resistance

When running autonomous builder agents with auto-accepted file edits (`accept-edits` mode), `agent-loop-kit` guards against prompt injection or rogue agents approving their own work:
- Checksums of `.supervision/bin`, gate configurations, and reviewer rubrics are recorded outside the repo in `~/.local/state/agy-loop/<repo>/tamper-baseline.sha256`.
- If a builder edits reviewer files, `agy-loop` halts instantly with a tamper alert.
- The builder is blocked from writing `review.json` or invoking reviewer scripts.

---

## 5. Multi-Brain Supervisor Cascade (Zero-Downtime Architecture)

To ensure the loop never halts due to vendor rate limits or subscription quota exhaustion:
- The supervisor router (`bin/supervisor-router`) dynamically cascades across active providers in priority order:
  1. `Claude Code` (Sonnet / Opus)
  2. `Gemini 3.8 Flash High` (via Antigravity / Google AI Studio)
  3. `GPT-OSS 120B` (open model fallback)
  4. `DeepSeek-R1` (Local via Ollama - 100% offline, zero-quota, runs on your own hardware)
- Provider health and quota cooldowns are tracked in `~/.cache/agent-loop/quota-status.json`. If a provider returns 429 or quota exhaustion, it is put on cooldown and the next provider is engaged in seconds without human intervention.

