# agent-loop-kit

> **Autonomous multi-agent supervision loop:** Builder agents write code step-by-step; Claude Code independently gates, tests, and reviews each commit before it lands.

[![CI](https://github.com/umairmsm/agent-loop-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/umairmsm/agent-loop-kit/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Good First Issues](https://img.shields.io/badge/Contribute-25%20Good%20First%20Issues-brightgreen.svg)](docs/CONTRIBUTING_TASKS.md)

---

## 1. ELI10: What is this?

When you ask an AI coding agent to complete a big, multi-step task on its own, it often behaves like an over-eager student without a teacher:
* It hallucinates packages that don't exist.
* It deletes or skips failing tests to get a "green" build.
* It gets stuck in infinite loops when hitting an error.
* It accidentally prints API keys or runs destructive commands.

**`agent-loop-kit` creates a Separation of Powers.**
Instead of trusting one agent to do everything, we split the job between **two independent agents**:
1. **The Builder** (Antigravity / Codex / Aider): Works on a branch, writing code and tests for one step at a time.
2. **The Reviewer** (Claude Code): Operates in an isolated worktree. It mechanically runs test suites, linters, and probes (`gate.sh`), adversarial security mutations, and reviews diffs against the written spec.

```
   ┌───────────────────────┐                    ┌───────────────────────┐
   │     BUILDER AGENT     │                    │    REVIEWER AGENT     │
   │  (Antigravity / CLI)  │                    │     (Claude Code)     │
   │                       │                    │                       │
   │ Writes code & tests   │                    │ Gates each commit     │
   │ Commits Step N        ├──────────┐         │ Runs test suite       │
   │                       │          │         │ Catches regressions   │
   └───────────────────────┘          ▼         └───────────▲───────────┘
                              .supervision/                 │
                              ├── ag_status.json ───────────┘
                              └── review.json
```

**The human supervisor only reviews and merges when the entire task is finished.**

---

## 2. 5-Minute Quickstart

### Prerequisites
- Bash (Linux / macOS / WSL2)
- Git (2.28+)
- Python 3.10+
- [Gitleaks](https://github.com/gitleaks/gitleaks) & [ShellCheck](https://www.shellcheck.net/)

### Installation
Clone this repository and run the link installer:
```bash
git clone https://github.com/umairmsm/agent-loop-kit.git
cd agent-loop-kit
bash bin/install-links.sh --loop
```
This symlinks the CLI tools (`agent-loop` / `loop`, `agy-loop`, `agy-safe`, `agy-resume`, `agy-sessions`) into `~/.local/bin` and registers the `agent-supervisor` skill with Claude Code.

### Try the Demo
Test the gate and evidence engine in under 30 seconds:
```bash
cd examples/demo-project
./run-demo.sh
```
You will see `gate.sh` create a detached worktree, run the test suite, scan for secrets, and write `.supervision/evidence/<sha>.txt`.

---

## 3. How It Works

### The Supervision State Machine
Every task is defined in a structured specification (see [`docs/SPEC_TEMPLATE.md`](docs/SPEC_TEMPLATE.md)).
1. **The Step Commit**: The Builder executes Step N, runs project tests, and commits once with a Conventional Commit message.
2. **Status Handoff**: The Builder writes `.supervision/ag_status.json` with state `READY_FOR_REVIEW`.
3. **The Mechanical Gate (`gate.sh`)**: The Reviewer checks out the commit in a throwaway detached git worktree (`git worktree add --detach`) so the Builder's shared working tree is never touched. It runs:
   - Environment & runtime sanity checks
   - Full test suite (`TEST_CMD`)
   - Linter & formatter (`LINT_CMD`, `FORMAT_CMD`)
   - Secret scan (`gitleaks`)
   - Test-deletion detector: compares test counts and names against the base branch. If the builder deleted or skipped tests, the gate fails immediately.
   - Project probes: custom scripts verifying specific bugs stay fixed.
4. **Multi-Brain Reviewer Cascade (`supervisor-router`)**: The Reviewer runs an adversarial inspection using the best available high-IQ model. If Claude hits subscription limits or 429 quota exhaustion, `supervisor-router` automatically cascades to Gemini 3.8 Flash High, GPT-OSS 120B, or local DeepSeek-R1 via Ollama without stopping the build!
   - Standard steps are reviewed by `step-reviewer` (Sonnet / Gemini) against the spec.
   - Steps marked `[security]` trigger `security-reviewer` (Opus / Flash Thinking) which attempts mutation testing and adversarial input bypasses.
5. **Verdict**:
   - `APPROVED`: The Builder proceeds to Step N+1.
   - `CHANGES_REQUIRED`: The Builder immediately starts fixes in the same turn without human intervention.
   - `ESCALATED`: The loop pauses and notifies the repository owner.

---

## 4. Built-In OS Safety Guard (`agy-safe`)

Unattended agents should never be given unrestricted shell access. `bin/agy-safe` wraps the builder process with OS-level shims:
- **Blocked entirely**: `sudo`, `su`, `shred`, `mkfs`, `dd`.
- **Blocked network actions**: `git push` (disabled unless explicitly authorized), `ssh`, `rsync`.
- **Destructive file commands**: `rm` commands targeting paths outside the repository workspace or `/tmp` exit with error code 97.
- **Upload protection**: `curl` / `wget` with non-GET or payload-upload flags (`-d`, `--data`, `-F`, `-X POST`) are intercepted.

---

## 5. System Limits & Non-Goals

- **Not a Magic Fix for Bad Specs**: An agent loop is only as good as the task prompt. If your specification has ambiguous requirements, the reviewer will halt or ask for clarification.
- **Git Hygiene Required**: The project must use Git. The gate requires commit history to perform detached worktree verification and revert checks.
- **Local First**: Designed for local development machines, homelabs, or dedicated runner VMs. Not intended for direct deployment to live production servers.

---

## 6. Community & Contributing

We actively welcome community contributions! Check out our [Contributor Task Board](docs/CONTRIBUTING_TASKS.md) for 25 pre-scoped `good first issue` tickets:
- Adding pluggable gates (Biome, Ruff, Clippy, Go, Hadolint)
- Adding notification hooks (Discord, Slack, Matrix, ntfy.sh)
- Adding builder CLI adapters (Aider, Codex, OpenCode, Cursor)

Please see [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 7. License

MIT License. Copyright (c) 2026 [umairmsm](https://github.com/umairmsm).
