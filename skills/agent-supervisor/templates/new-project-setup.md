# Set up the supervised agy-loop for a new project

Paste this to Claude Code, started inside the project's repo. Fill in the two lines at the top, or leave them blank and Claude asks.

```
Use the agent-supervisor skill to set up the supervised agy-loop for this project,
following templates/new-project-setup.md in that skill. Adapt everything to this project; copy nothing blindly from another one.
First work for the loop: <what you want built next, or "propose it">
Things that must never happen here: <e.g. "post to a real account", "touch the live database", or "ask me">
```

---

## What Claude does with it (the setup checklist)

Do these in order. Stop and ask the owner at every **[owner]** item; decide everything else yourself, and say what you decided.

### 1. Understand the project before touching anything
- Read `AGENTS.md`, `CLAUDE.md`, `PROJECT.md`, the README and the roadmap. Note the stack, test runner, lint/format commands, branch naming rule and base branch.
- Check `.supervision/` already exists (an older manual setup) and `ls .supervision/loop.lock`: if a loop or a manual reviewer is active on this repo, stop. Two reviewers overwrite each other's verdicts.
- Run the test suite once on the base branch. If it is not green, report it; the loop cannot start on a red baseline.

### 2. Find what can hurt, and make the builder unable to reach it
List every way a builder session on this machine could do real damage here, then check each one is blocked, not just forbidden in a prompt:
- **Secrets the builder can read**: credential files, `.env`, tokens under `~/.config/<project>/`. The builder runs as the owner's user, so `chmod 600` does not stop it.
- **Outward actions**: publishing, posting, sending email, deploying, DNS, paid API calls, production databases, real payments.
- `agy-safe` already blocks push, ssh, sudo, rm outside the workspace and curl uploads. Anything beyond that needs a project fix (a separate OS user, credentials moved out of reach, a PREFLIGHT that refuses to start while they are readable).
- **[owner]** Present the list with a recommended fix for each gap. Do not start a loop while a gap is open unless the owner accepts it in writing.

### 3. Install and adapt the gate
- `bash skills/agent-supervisor/scripts/init.sh`, then rewrite `.supervision/gate.conf` for this project:
  - `BASE_BRANCH="${BASE_BRANCH:-<base>}"` and `GATE_SCOPE="${GATE_SCOPE:-}"`, so agy-loop can override both.
  - `TEST_CMD`, `LINT_CMD`, `FORMAT_CMD` exactly as the project runs them. If the gate's worktree needs dependencies (node_modules, a venv), borrow the main checkout's by symlink if needed.
  - `PROTECTED_PATHS`: schema and migrations, CI, deploy, auth, money, safety code, decision records, the agent rule files. **[owner]** confirm the list.
  - If a dev server serves the shared checkout rather than the gate worktree, add the "shared checkout is at the reviewed sha and clean" guard.

### 4. Write the probes (the part that actually catches bad work)
Every project gets these, ported to its language:
- **revert**: the step's new or changed tests must fail on the parent commit (e.g. `probe-revert.sh`). Runs last, only when `GATE_PARENT` is set.
- **scope**: the step changed only files matching `GATE_SCOPE` (e.g. `probe-scope.sh`).
- **secret scan**: patterns for this project's real key formats, not only general API keys.

Then add project probes: one per rule that must never break, each printing one line and exiting non-zero on failure. Examples: SEO tags and 404s for a website, tenant isolation on a multi-tenant database for a SaaS app, kill switch and "nothing reaches a real account" for a publishing system. **Run every probe on the current HEAD**; a probe meant to catch a known bug must show it failing before the fix.

### 5. Configure the loop
Write `.supervision/loop.conf`:
- `REPO_MAIN`, plus `REVIEW_TOOLS_EXTRA` so the reviewers can run this project's tests and probes.
- `PREFLIGHT`: whatever the gate needs (docker, disk space, dependencies), plus the step 2 secret checks.
- `BUILD_EXTRA`: the project's hard rules in two or three lines, and the exact checks to paste into the summary.
- `HANDOFF=".supervision/HANDOFF.md"`.

### 6. Prove it before trusting it
- `.supervision/bin/gate.sh HEAD` must finish and write `.supervision/evidence/<sha>.txt` with every probe line present.
- Pick one past commit with a known outcome and run `agy-loop <task> --review-only <sha> --from-step 1`. The reviewer's verdict must match what really happened.
- Run `agy-loop <task> --rebaseline` once so the tamper baseline covers the new gate files.

### 7. Write the first task file
Start from `templates/task-prompt.md` and put it under `.supervision/tasks/` or `docs/supervision/`:
- Header: `` Branch `<builder branch, using the repo's naming rule>` ``, `` Base `<base>` ``, `` Scope `<regex>` ``.
- One `### Step N: <ID> <title>` per commit-sized change. Add `[security]` to the heading of any step that touches auth, isolation, secrets, money or safety code, so the Opus security-reviewer tries to break it.
- Decide every design choice in the file ("Decisions made for you"), and give each step named failing tests with exact assertions.
- **[owner]** show the task file and get approval.

### 8. Hand over
Give the owner the exact start command (`tmux new -s <name> agy-loop <task file>`), what the notifications mean, and a short list of what was set up and which decisions are still theirs. Never start the loop yourself, never push, never merge.

### Afterwards
Add any new failure mode the run teaches to `references/lessons.md` in the skill.
