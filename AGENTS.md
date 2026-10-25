# AGENTS.md — Universal Agent Contract for agent-loop-kit

> **Any AI coding agent working in this repository reads this file first.**  
> Claude Code, Antigravity, Gemini CLI, Cursor, Codex, Cline, Windsurf, Aider, Copilot, DeepSeek, Qwen — all of them.  
> The tool-specific pointer files at this root (`agent.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`) are **symlinks to this file**, ensuring a single, drift-free contract.

---

## 1. Executive Context & The Problem This Solves

When an AI coding agent attempts large, multi-step engineering tasks alone, it tends to:
1. Delete or weaken existing unit tests to make a failing build pass.
2. Hallucinate non-existent packages, mock objects, or API flags.
3. Get trapped in recursive error loops, burning quota without making progress.
4. Leak secrets, execute dangerous shell commands (`rm`, `sudo`), or overwrite critical configurations.

**`agent-loop-kit` enforces an architectural Separation of Powers:**
* **The Builder**: Writes code and unit tests for one step at a time on an isolated branch.
* **The Reviewer**: Operates independently in a throwaway detached git worktree (`git worktree add --detach`), executing mechanical test gates, secret scans, mutation tests, and diff audits.
* **The Multi-Brain Router (`supervisor-router`)**: Cascades across multiple AI model providers (Claude Code, OpenRouter, DeepSeek, Gemini, local Ollama) so the loop runs continuously without stalling when a single vendor's quota exhausts.

---

## 2. Ultraview System Audit (Current Architecture & State)

| Subsystem | Components | Verification Status |
|---|---|---|
| **Core Loop CLI** | `bin/agent-loop`, `bin/loop`, `bin/agy-loop`, `bin/agy-resume` | Fully tested; portable aliases; zero-downtime conversation resumption. |
| **Safety Kernel** | `bin/agy-safe` (blocks `sudo`, `su`, `git push`, remote sync, outside `rm`) | Active on PATH; intercepts destructive commands with exit code 97. |
| **Multi-Brain Router** | `bin/supervisor-router` (Claude -> OpenRouter -> DeepSeek -> Gemini -> Ollama) | Integrated cooldown cache at `~/.cache/agent-loop/`; automated failover. |
| **Reviewer Engine** | `skills/agent-supervisor/`, `skills/agent-supervisor/templates/gate.sh` | Detached worktree test execution; test deletion & skip detection. |
| **Adversarial Prober** | `skills/agent-supervisor/scripts/adversarial-check.py` | Mutation testing; vacuous assertion detection; scope boundary enforcement. |
| **Session Manager** | `bin/agy-sessions`, `bin/agyr` | Python-backed session ledger (`sessions.jsonl`); transcript pruner. |
| **Demo & Smoke Gate** | `examples/demo-project/run-demo.sh` | Self-contained demo verifying gate passes with 0 leaks and 3 unit tests. |
| **CI & Hygiene** | `.github/workflows/ci.yml`, `scan.sh` | ShellCheck clean; Gitleaks dir/git clean; 0 scrub hits. |

---

## 3. Universal Read Order for Any Agent

Before modifying or adding code in this repository, follow this sequence:
1. **This file (`AGENTS.md`)**: The root contract and non-negotiable rules.
2. **`README.md`**: High-level conceptual overview, visual state machine, and quickstart.
3. **`docs/ARCHITECTURE.md`**: Deep dive into state transitions, evidence collection, and tamper detection.
4. **`docs/CONTRIBUTING_TASKS.md`**: The 25 pre-scoped contributor issues (gates, notifiers, adapters).
5. **`loop.conf.example`**: Configuration schema for customizing builders and reviewers.

---

## 4. Multi-Brain Supervisor & Quota Management

When reviewing commits or testing tasks, agents must adhere to the multi-brain routing protocol:

```
                          SUPERVISOR CASCADE FLOW
   ┌────────────────────────────────────────────────────────────────────────┐
   │ 1. Claude Code CLI (Sonnet / Opus)                                     │
   │    -> If active & quota available: primary high-IQ step reviewer.      │
   │    -> If 429 / usage_limit_reached: cooldown logged; cascade proceeds. │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │ 2. Frontier Fallbacks (OpenRouter / DeepSeek / Cloudflare AI)          │
   │    -> Qwen3-Coder 480B, DeepSeek V4.1 Flash, GPT-OSS 120B.             │
   │    -> Prefix-caching optimized (rubric + schema first in KV cache).    │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │ 3. Headless Fallbacks (Antigravity / Gemini 3.8 Flash High)            │
   │    -> Fast, low-latency, structured JSON enforcement.                  │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │ 4. Local Offline Fallback (Ollama: DeepSeek-R1 / Llama3.2)             │
   │    -> 100% offline, zero-quota, runs on local GPU/CPU.                 │
   └────────────────────────────────────────────────────────────────────────┘
```

* **Router CLI**: Run `supervisor-router --status` to view active providers and cooldown timers.
* **Cache location**: `~/.cache/agent-loop/quota-status.json`.

---

## 5. Non-Negotiable Operational Invariants

Every agent operating in this repository must strictly obey these invariants:

1. **Strict Air-Gap & Secret Protection**:
   - NEVER hardcode API keys, personal names, phone numbers, internal hostnames, or private IP ranges (RFC 1918 subnets).
   - If you encounter a secret during a run, report it by `file:line rule` only. NEVER echo or log the secret value.
   - All code must pass `scan.sh` (Gitleaks dir, Gitleaks git, and regex scrub patterns).

2. **Atomic Commits & Conventional Commits**:
   - Keep commits small (<150 lines of diff where possible).
   - Use Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`.
   - Sign commits with `git commit -s` (Developer Certificate of Origin).

3. **No Reviewer Tampering**:
   - The Builder agent must NEVER edit files under `.supervision/`, `gate.sh`, or reviewer rubrics.
   - `agy-loop` verifies SHA256 tamper checksums against a baseline outside the repository before each review pass.

4. **Preserve Compatibility**:
   - All shell scripts must remain strictly POSIX / bash compliant and pass `shellcheck` with 0 errors and 0 warnings.
   - Support both `main` and `master` default branch conventions via `${BASE_BRANCH:-main}`.

5. **Human Authority**:
   - Automated agents never execute `git push` or deploy to external networks.
   - Only the repository owner publishes releases or changes repository visibility.

---

## 6. How to Verify Your Work (Testing Commands)

Before committing changes, execute the full mechanical verification suite:

```bash
# 1. Check syntax of all shell scripts
for f in bin/* skills/agent-supervisor/scripts/*.sh skills/agent-supervisor/templates/*.sh examples/demo-project/*.sh; do
  [ -f "$f" ] && bash -n "$f"
done

# 2. Run ShellCheck linter
shellcheck bin/agent-loop bin/loop bin/agy-loop bin/agy-safe bin/agy-resume bin/install-links.sh \
  skills/agent-supervisor/scripts/*.sh skills/agent-supervisor/templates/*.sh examples/demo-project/*.sh

# 3. Compile Python utilities
python3 -m py_compile bin/agy-sessions bin/supervisor-router skills/agent-supervisor/scripts/adversarial-check.py

# 4. Run the demo smoke test in a detached worktree
cd examples/demo-project && ./run-demo.sh && cd ../..

# 5. Run the metal detector scan (Gitleaks + Scrub patterns)
bash ../scan.sh .
```

---

## 7. Contributor Roadmap & Good First Issues

When contributing new capabilities, align with the modular architecture in `docs/CONTRIBUTING_TASKS.md`:
* **Pluggable Gates**: Adding language-specific linters/checkers (Biome for TS, Ruff for Python, Cargo Clippy for Rust, Golangci-lint for Go).
* **Notification Handlers**: Adding webhook dispatchers (Discord, Slack, Matrix, ntfy.sh).
* **Builder CLI Adapters**: Adding integration wrappers for other coding agents (Aider, Codex, OpenCode).
