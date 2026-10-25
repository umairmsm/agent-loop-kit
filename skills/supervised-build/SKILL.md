---
name: supervised-build
description: |
  Run a written task file step by step under supervisor review: one commit per step, then wait for the reviewer's verdict before the next step.
  Use when the user says "/supervised-build <task file>", "do the task in docs/supervision/TASK_...", or "run the supervised task".
  The argument is the task file path. With no argument, pick the open task (see "Choosing the task").
metadata:
  version: v0.1.0
  owner: loop-maintainer
---

# Supervised build

You are the **builder**. A separate reviewer checks every step. The repository owner merges and deploys. You never do the reviewer's or the owner's job.

## Choosing the task
- If the user gave a file path, use it.
- If not: list `docs/supervision/TASK_*.md` whose matching `REPORT_*.md` does not exist yet.
  - Exactly one → use it, and say which one.
  - Zero or several → list them and ask the user. Don't guess.

## Before the first step
1. Read `AGENTS.md`, `CLAUDE.md` and `SESSION_LOG.md` if they exist, then the whole task file. Where they conflict, the task file's Hard rules win for this task, and AGENTS/CLAUDE win over this skill.
2. Create the branch the task names from the current tip of `main` or the specified base branch. Never commit directly to the base branch.
3. Run the baseline checks the task lists. If the baseline isn't green, stop and report (no commits).

## Rules that always apply (even if the task file forgets them)
- **Never push, merge, deploy, or touch production, DNS, or a live server.**
- **Never write `.supervision/review.json`.** Never run, edit or start anything in `.supervision/bin/`, any reviewer or supervisor script, or another model to judge your work. Only the reviewer writes verdicts.
- **Never search for credentials, tokens or API keys** (no `env | grep`, no grepping config, home or secret files). If you need access you don't have → BLOCKED.
- **No paid calls** (paid APIs, third-party LLM routers) unless the task file explicitly allows the exact call.
- Test-first. Never weaken, skip or delete an existing test, and never update a snapshot unless the task says so.
- Only change the files the task allows. A needed file that the task doesn't name → BLOCKED, with your recommendation.
- **Report honestly.** Put failures, skipped items and partial results in the summary. Never say "done" for something you didn't verify.
- Never commit `.supervision/`.

## The loop (for every step)
1. Do the step. Run every check the task lists and read the **raw** output, not a summary.
2. Commit once, using Conventional Commits with the step ID in the subject.
3. Check that `git status --porcelain` is clean for the paths the task lists.
4. Get the full sha: `git rev-parse HEAD`.
5. Write `.supervision/ag_status.json`, replacing the whole file:
   `{"step":"<n>","state":"READY_FOR_REVIEW","commit":"<full sha>","summary":"<what changed; test counts; anything that failed>","question":null}`
6. Wait for the verdict. Poll every 30 s for up to 60 minutes:
   `for i in $(seq 1 120); do grep -q "<full sha>" .supervision/review.json 2>/dev/null && break; sleep 30; done; cat .supervision/review.json`
7. Act on the verdict:
   - `APPROVED` → go to the next step.
   - `CHANGES_REQUIRED` → **start the fixes in the same turn.** Never end your turn while a step is open. Make a new commit, then go back to 3.
   - `ESCALATED` → keep polling. The owner is deciding.
   - No verdict after 60 minutes → poll again. Don't move on.

Stay on the task branch until the final verdict.

## BLOCKED (a decision the task doesn't cover)
Write `{"step":"<n>","state":"BLOCKED","commit":null,"summary":"<what happened>","question":"<options + your recommendation>"}`, then wait as in step 6.

## Finish
When every step is APPROVED:
1. Write the report the task names (default `docs/supervision/REPORT_<TASK>.md`). Cover each "Definition of done" item with evidence: commands, counts, shas.
2. Commit it.
3. Write `{"step":"final","state":"DONE","commit":"<sha>","summary":"<report path>","question":null}`.
