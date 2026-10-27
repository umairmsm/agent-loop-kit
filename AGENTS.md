# AGENTS.md — Universal Agent Contract for agent-loop-kit

> **Any AI coding agent working in this repository reads this file first.**
> Claude Code, Antigravity, Gemini CLI, Cursor, Codex, Cline, Windsurf, Aider, Copilot, DeepSeek, Qwen — all of them.
> The tool-specific pointer files at this root (`agent.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`) are **symlinks to this file**. Never replace them with separate files.

*Last verified against the code: 2026-10-27.* If a statement here disagrees with the code, the code wins: fix this file in the same commit.

---

## 1. What this repository is

`agent-loop-kit` runs an AI **builder** through a written task file, **one step and one commit at a time**, while a separate **gate** (scripts) and **reviewer** (a different model) check every commit before the next step starts.

AI builders left alone tend to delete or weaken tests to get green, invent packages and flags, loop on the same error until the quota is gone, and run dangerous shell commands. The kit separates the powers:

* **Builder**: writes code and tests for one step on a feature branch. It never writes verdicts and never edits `.supervision/`.
* **Gate** (`gate.sh`, no AI): runs the tests, lint and probes on the commit in a throwaway detached worktree, then scans for removed or skipped tests, secrets and protected paths.
* **Reviewer**: reads the diff against the step's spec and the gate log, then answers `APPROVED` or `CHANGES_REQUIRED` with a fix list, or flags `escalate` for a human.
* **Human**: merges, deploys, and changes repository visibility. Nothing in this kit does those.

---

## 2. What is in the repository (checked 2026-10-27)

| Path | What it is |
|---|---|
| `bin/agy-loop` (+ `agent-loop`, `loop`) | The unattended step runner: build, gate, review, retry, escalate. Supports `--from-step N`, `--review-only <sha>`, `--rebaseline`, step tags `[security]` and `[content]`. |
| `bin/agy-resume` | Re-runs a cut-off Antigravity turn in the same conversation. |
| `bin/agy-safe` | Command guard (blocks `sudo`, `su`, `git push`, remote sync, `rm` outside the project). Blocked actions exit with code 97. |
| `bin/agy-sessions`, `bin/agyr` | Session ledger and archive/prune helpers (Python). |
| `bin/supervisor-router` | Multi-model reviewer with failover (Python). See section 4. |
| `bin/brain` (+ `model`, `s`) | Shows which model the router prefers, and switches it. |
| `bin/install-links.sh` | Symlinks the commands, skills and agents into `~/.local/bin` and `~/.claude`. |
| `skills/agent-supervisor/` | The reviewer skill, its `gate.sh` template and `adversarial-check.py` (mutation and vacuous-assertion checks). |
| `skills/supervised-build/`, `skills/brain/` | Builder-side skill and the `/brain` skill. |
| `agents/` | `gate-runner.md`, `step-reviewer.md`, `security-reviewer.md` (Claude Code agent definitions). |
| `docs/` | `ARCHITECTURE.md`, `CONTRIBUTING_TASKS.md`, `SPEC_TEMPLATE.md`, `SUPERVISOR_PLAYBOOK.md`. |
| `examples/demo-project/` | A self-contained demo (`run-demo.sh`) that must pass. |
| `loop.conf.example` | Per-project settings, copied to `.supervision/loop.conf` in the target repo. |
| `.github/workflows/ci.yml` | CI: syntax, ShellCheck, Gitleaks, demo. |

Verified on 2026-10-27: ShellCheck reports 0 findings on the linted shell files, `examples/demo-project/run-demo.sh` passes, and Gitleaks finds no leaks in the working tree or the git history.

---

## 3. Read order for any agent

1. This file.
2. `README.md`: overview and quickstart.
3. `docs/ARCHITECTURE.md`: state transitions, evidence collection, tamper detection.
4. `docs/SPEC_TEMPLATE.md`: the shape of a task file that works.
5. `docs/SUPERVISOR_PLAYBOOK.md`: what a supervisor (human or AI) may fix and what must go to the owner.
6. `docs/CONTRIBUTING_TASKS.md`: pre-scoped contributor issues.
7. `loop.conf.example`: the settings you can change.

---

## 4. How a review is routed (read this before touching `review()` in `bin/agy-loop`)

`agy-loop` chooses the reviewer in this order. The first match wins:

1. **`supervisor-router`**, if it is on `PATH` or sits beside `agy-loop`. **This overrides `REVIEWER`.**
2. **`REVIEWER="agy"`** in `loop.conf`: calls `agy-review`, which is **not shipped in this repository yet** (see section 7). If it is missing, the loop stops with a clear message.
3. **Default**: `claude -p --agent step-reviewer` (and `security-reviewer` for `[security]` steps).

`supervisor-router` tries providers in order and moves on when one fails, times out or is out of quota: Claude Code, then OpenRouter models, DeepSeek, Cloudflare Workers AI, Antigravity models, then local Ollama. The order is `DEFAULT_CASCADE` in `bin/supervisor-router`.

* `SUPERVISOR_CASCADE` replaces that list. It is **space-separated**, for example `SUPERVISOR_CASCADE="claude agy:gemini-3.8-flash-high ollama:deepseek-r1:latest"`.
* The `preferred_model` in `~/.config/agent-loop/config.json` is **always put first, even if it is not in `SUPERVISOR_CASCADE`**. Change it with `brain <1-6|name>`, or look at it with `brain` and `brain status`.
* `--second-opinion` (or `SUPERVISOR_SECOND_OPINION=1`) asks a second model and combines the answers. Security steps do this automatically.
* API keys come from the environment or `~/.config/agent-loop/credentials.env` (keep it mode 600). `brain key` prompts for one without echoing it. Never commit it.
* Provider cooldowns are cached in `~/.cache/agent-loop/quota-status.json`.

**Privacy rule.** Every provider the router tries receives the step spec, the git diff and the gate evidence. Free and low-cost tiers may log requests or train on them, and **the router does not send any data-retention opt-out headers** (the module docstring mentions Zero Data Retention, but the code only sends an `X-Title` header). For a private or client repository, restrict the cascade to providers you trust and set `preferred_model` to one of them, or do not install the router.

---

## 5. Non-negotiable invariants

1. **Secrets and personal data stay out.**
   - Never commit API keys, personal names, phone numbers, internal hostnames or private IP ranges.
   - If you find a secret during a run, report it as `file:line rule` only. Never print or log the value.
   - Before staging a commit, run Gitleaks (section 6). Maintainers also run a private scrub scan (`scan.sh`, kept outside this repository because its pattern list is not public).
2. **Small, conventional commits.**
   - Keep diffs small (under about 150 lines where possible).
   - Use Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`.
   - Contributions should be signed off (`git commit -s`). CI does not enforce this yet. An AI agent must not add a sign-off on a person's behalf.
3. **No reviewer tampering.**
   - The builder never edits `.supervision/`, `gate.sh`, the reviewer rubrics or `agy-loop`.
   - `agy-loop` compares SHA-256 checksums of these files with a baseline stored **outside the repository** (`~/.local/state/agy-loop/<repo>/tamper.sha256`) before every review. Only a human runs `agy-loop <task> --rebaseline`, and never while a loop is running.
4. **Never weaken a test to pass.** No deleted, skipped or loosened assertions. If a test is wrong, say why in the commit and name the replacement.
5. **Compatibility.** Shell scripts stay bash-compliant and pass `shellcheck` with 0 findings. Support both `main` and `master` through `${BASE_BRANCH:-main}`.
6. **Human authority.** Automated agents never run `git push`, merge, deploy, or change repository visibility. Only the owner publishes.
7. **Reviewers are read-only.** A reviewer must not commit, reset, check out, stash or edit the checkout. `agy-loop` voids a verdict if `HEAD` or the working tree changed during the review.

---

## 6. How to verify your work

Run these before every commit (from the repository root):

```bash
# 1. Syntax: bash -n for shell scripts, py_compile for Python (same logic as CI)
for f in bin/* skills/agent-supervisor/scripts/* skills/agent-supervisor/templates/*.sh examples/demo-project/*.sh; do
  [ -f "$f" ] || continue
  if head -n 1 "$f" | grep -q python; then python3 -m py_compile "$f"; else bash -n "$f"; fi
done

# 2. ShellCheck (0 findings required)
shellcheck bin/agent-loop bin/loop bin/agy-loop bin/agy-safe bin/agy-resume bin/install-links.sh \
  skills/agent-supervisor/scripts/*.sh skills/agent-supervisor/templates/*.sh examples/demo-project/*.sh

# 3. Demo smoke test (needs a git checkout)
(cd examples/demo-project && ./run-demo.sh)

# 4. Secret scan, working tree and history
gitleaks dir . --no-banner --redact
gitleaks git . --no-banner --redact
```

`python3 -m py_compile` creates `__pycache__/`, which is git-ignored. Do not use `bash -n` on `bin/agy-sessions` or `bin/supervisor-router`: they are Python.

---

## 7. Known gaps (do not claim these work until they are shipped)

* **`REVIEWER="agy"` needs scripts that are not in this repository yet.** `bin/agy-loop` calls `agy-review`, `agy-claims-audit` and `review-text-to-json`, and a companion `agy-supervise` watchdog and `loop-status` command exist in the maintainer's setup. None of them is shipped here. Until they are, only the default Claude reviewer and `supervisor-router` work out of the box.
* **The read-only git guard is not in `agy-safe`.** The maintainer's setup blocks git write commands for reviewers with an `AGY_READONLY=1` mode; that change is not in this repository's `bin/agy-safe`.
* **Data retention.** See the privacy rule in section 4: do not assume zero retention.
* **CI shows the demo and static checks only.** There is no unit-test suite for `supervisor-router` or `agy-loop` yet.

---

## 8. Contributing

Align new work with `docs/CONTRIBUTING_TASKS.md`:
* **Pluggable gates**: language-specific checks (Biome, Ruff, Cargo Clippy, golangci-lint).
* **Notifiers**: webhook dispatchers (Discord, Slack, Matrix, ntfy).
* **Builder adapters**: wrappers for other coding agents (Aider, Codex, OpenCode).
* **Closing the gaps in section 7**: ship `agy-review`, `agy-claims-audit`, `review-text-to-json`, `agy-supervise`, `loop-status` and the `AGY_READONLY` guard, each with ShellCheck-clean code and a demo or test.
