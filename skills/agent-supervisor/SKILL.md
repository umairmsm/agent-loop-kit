---
name: agent-supervisor
description: Supervise another coding agent (Antigravity, Codex, Gemini, a second Claude) through a multi-step fix or build, step by step, without the owner babysitting. The builder commits one step at a time and waits; Claude independently gates each commit in a throwaway worktree (tests, lint, probes, removed-test and secret scans), writes APPROVED / CHANGES_REQUIRED / ESCALATED, and escalates security, data and scope decisions to the owner. Use when the user wants an agent to "run unattended", "fix everything in one go", "babysit Antigravity/Codex", "review each step", or wants this supervision setup on a new project.
---

# Agent supervisor

You are the **reviewer**. Another agent is the **builder**. The repo is the only channel between you: the builder writes `.supervision/ag_status.json`, and you write `.supervision/review.json`. You never edit the builder's code, never push or merge, and only the owner merges.

## Setup (once per project)
For a new project that will run `agy-loop`, follow `templates/new-project-setup.md` (it covers the steps below plus secrets, probes, loop.conf and proving the gate).
1. **Install the channel.** Run `bash ~/.claude/skills/agent-supervisor/scripts/init.sh` from inside the repo. It copies `gate.sh` into `.supervision/bin/`, creates `.supervision/gate.conf` (it detects Python/uv, Node, Go or Rust), and gitignores `.supervision/`.
2. **Fill in `.supervision/gate.conf`.** Set `BASE_BRANCH`, the test, lint and format commands, `PROTECTED_PATHS`, and **probes**. Probes are small scripts in `.supervision/bin/` that prove the specific bug is fixed by exercising it directly. Write a probe for each critical item, and run it on the current HEAD first to confirm it shows the failure. A probe caught an emergency-stop bug that 61 passing tests missed.
3. **Write the task prompt.** Start from `templates/task-prompt.md`. Decide every design choice in the prompt, so the builder never has to. Give each step named failing tests with exact assertions, plus a definition of done and the stop conditions. Commit the prompt to `BASE_BRANCH`, and tell the builder to branch from the current tip.
4. **Smoke-test the gate.** Run `.supervision/bin/gate.sh HEAD`. It must finish and write `.supervision/evidence/<sha>.txt`.
5. **Start the watcher.** Use the Monitor tool with command `bash ~/.claude/skills/agent-supervisor/scripts/watch.sh` and `timeout_ms` 1800000. Re-arm it every time it expires.
6. **Tell the owner the exact line to give the builder:** "Read AGENTS.md, then execute <prompt path> exactly, end to end, including the supervision protocol."

## Tiered review (token budget)
Run the cheap tiers first, and only spend main-session (Opus) reasoning where judgement is needed. Read `references/lessons.md` once per session; it lists the real failure modes these tiers check for.

| Tier | Who | Model | Does |
|---|---|---|---|
| 1 | `gate-runner` subagent | haiku | runs gate.sh, returns a PASS/FAIL table, detects a broken gate and re-runs |
| 2 | `step-reviewer` subagent | sonnet | diff vs spec, test-assertion quality, live checks; drafts the verdict and fix list |
| 3 | main session | as set | escalations only: security, production, DNS/infra, data, deps, scope; plus the final DONE review and owner reporting |

Model choice is set in the subagent frontmatter, so no `/model` switch is needed. To change a tier, edit the `model:` line in `~/.claude/agents/<name>.md`.

## On each `BUILDER_STATUS` event (or a new commit without a status; statuses often lag up to 2 min)
- **`READY_FOR_REVIEW`:**
  1. Agent tool → `gate-runner` with the full sha. If it returns `GATE_BROKEN` twice, check the gate yourself.
  2. Agent tool → `step-reviewer` with: full sha, previous approved sha, spec path + step number, and the gate-runner block.
  3. If the reviewer returns `escalate: false` and the verdict is clear, write it to `review.json` as drafted, with the **full** sha from `git rev-parse`. Spot-check one live claim yourself only if the step is user-visible.
  4. If `escalate: true`, or the gate FAILs for an unclear reason, or the reviewer is unsure: review it yourself (tier 3) before writing the verdict; push-notify the owner if their decision is needed.
  `APPROVED` needs **all** of these: tests and lint green; no removed or skipped tests (desktop-only guards are fine); secret scan clean; the step's probes flipped where expected; every spec item done; no unasked-for scope.
- **Accepted removals:** when you approve a step that replaces or removes a test, add the test name to `.supervision/accepted_removals.txt` (one per line). gate-runner and step-reviewer then stop flagging it on later steps.
- **`BLOCKED`:** answer only if the spec or the repo's rules clearly decide it. If the question touches security, data, money, scope or architecture, write `ESCALATED`, send the owner a PushNotification, and ask them.
- **`DONE`:** run the gate on the final commit, verify every definition-of-done item yourself, and report to the owner: the verdict, the evidence, open risks, and the merge recommendation.
- **A commit lands without a status write, or the builder skips a wait:** gate it anyway. Write `CHANGES_REQUIRED` naming the protocol breach, and tell the owner.

## Verdict format (`.supervision/review.json`, replacing the whole file)
```json
{"step": "<n>", "commit": "<full sha from the status>", "verdict": "APPROVED|CHANGES_REQUIRED|ESCALATED", "notes": "<evidence summary; for CHANGES_REQUIRED, a numbered list of exact fixes>"}
```
The builder matches on the full sha, so copy it exactly. For a `BLOCKED` answer, put the builder's question text in `commit`.

## Rules
- Run checks only in detached worktrees (gate.sh does this). Never switch branches or edit files in the shared checkout, because the builder works there.
- Approve on evidence, never on the builder's own summary. Builder summaries have overstated fixes before.
- A different model family reviews than builds, so their blind spots don't overlap.
- Paid model calls, pushes, merges, deploys and owner-only decisions (such as ratifying ADRs) are never yours to approve.
- Keep owner notifications for escalations and the final result.

## Unattended running (so the owner doesn't babysit)
- Builders ask permission for **file edits** separately from commands. Allowlisting commands isn't enough. Start Antigravity with `agy --mode accept-edits` (or press shift+tab in a session). Keep risky commands (push, merge, sudo, curl, rm) off the allowlist so they still ask the owner.
- **Tamper detection is mandatory once edits are auto-accepted.** After writing each verdict, save a private copy and checksums of `.supervision/bin/*` outside the repo (your scratchpad). Before every review, verify both. A changed gate script or a `review.json` you didn't write is an immediate stop: tell the owner.

## Fully unattended: `agy-loop` & `supervisor-router` (Multi-Brain Failover)
- `agy-loop <task.md>` runs each `### Step N` as a headless `agy -p` build, then `gate.sh`, then a review.
- The supervisor uses `supervisor-router` to cascade across independent model families:
  1. `claude` (Claude Code CLI: Sonnet / Opus)
  2. `openrouter:` (Qwen3-Coder 480B, DeepSeek V4.1 Flash, GPT-OSS 120B)
  3. `deepseek:` (DeepSeek direct API - 1M context)
  4. `agy:` (Antigravity Sonnet, GPT-OSS, Gemini Flash)
  5. `ollama:` (DeepSeek-R1, Qwen2.5-7B, Llama 3.2 local offline fallback)
- **Key Commands for the Supervisor Router:**
  - `supervisor-router --status` : Check active models, cooldown countdowns, and key status.
  - `supervisor-router --switch` : Interactively switch the active primary model.
  - `supervisor-router --info`   : View real-time provider HUD telemetry.
  - `supervisor-router --set-key <provider>` : Set API keys securely (`chmod 600` in `~/.config/agent-loop/credentials.env`).
  - *On-the-fly prompt:* Running `supervisor-router` interactively will automatically prompt for missing keys on the fly.
- A step headed `### Step N [security]` goes to the Opus `security-reviewer` (mutation and bypass passes); other steps go to the Sonnet `step-reviewer`. The loop retries a step up to 3 times, and stops with an ntfy alert on BLOCKED, an escalation, a tampered gate or a failed preflight. It never pushes.
- Task header: `` Branch `x` ``, `` Base `y` `` (for stacked packages), `` Scope `regex` `` (exported as `GATE_SCOPE`). Per-repo settings go in `.supervision/loop.conf`: `REVIEW_TOOLS_EXTRA`, `PREFLIGHT`, `BUILD_EXTRA`, `HANDOFF`.
- The gate gets `BASE_BRANCH`, `GATE_SCOPE`, `GATE_PARENT` and `GATE_PG_PROJECT` from the loop, so `gate.conf` should default them with `${VAR:-…}`. Add a revert-check probe (e.g. `probe-revert.sh`): the step's tests must fail on the parent code.
- `--review-only <sha> --from-step N` gates and reviews an existing commit without writing `review.json`. Use it to test a reviewer on known history before trusting it. `--rebaseline` accepts deliberate edits to gate or reviewer files; the baseline lives in `~/.local/state/agy-loop/<repo>/`.
- Never run the loop on a package a manual reviewer is still supervising. Two reviewers overwrite each other's verdicts.
- Sessions: the loop records every agy session in `~/.local/state/agy-loop/sessions.jsonl`, and `agy-sessions archive --loop-done --yes` moves the finished ones out of `/resume`. `agy-sessions stats` shows the backlog. Archive only with agy closed.
