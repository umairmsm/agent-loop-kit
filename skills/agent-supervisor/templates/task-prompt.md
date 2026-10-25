# Task: {{TASK_TITLE}}

You are working autonomously in `{{REPO_PATH}}`. Work through every step below, in order, until the definition of done is met. Don't ask for confirmation between steps. Stop early only for one of the stop conditions.

## Hard rules (never break these)
- Work on a new branch, `{{BUILDER_BRANCH}}`, created from the current tip of `{{BASE_BRANCH}}`. Never commit to `{{BASE_BRANCH}}` or `main`. Never push, merge, or open or modify a PR.
- No paid API calls, no network calls to production services, and never publish or deploy anything.
- Never read, print or copy secrets (credential files, `.env`, key files, tokens).
- Test-first for every fix: write the failing test, run it, and **see it fail for the right reason**. Then fix the code and see it pass.
- Never weaken, skip, delete or mark as expected-failure an existing test to make the suite pass. If an existing test conflicts with this spec, stop (stop condition 2).
- After every step, run the project's test, lint and format checks: {{CHECK_COMMANDS}}. All of them must be clean before you commit that step.
- Make one commit per step, in Conventional Commit style, with the step or finding ID in the subject.

## Supervision protocol (mandatory: an independent reviewer checks every step)
A reviewer (Claude Code) watches `.supervision/` and checks each step in a separate worktree. You never review or approve your own steps.

1. **After committing a step**, write `.supervision/ag_status.json`, replacing the whole file:
   `{"step": "<n>", "state": "READY_FOR_REVIEW", "commit": "<full sha>", "summary": "<what changed, test count>", "question": null}`
2. **Wait for the verdict.** Don't start the next step. Poll every 30 s for up to 60 minutes:
   `for i in $(seq 1 120); do grep -q "<full sha>" .supervision/review.json 2>/dev/null && break; sleep 30; done; cat .supervision/review.json`
3. **Act on the verdict:**
   - `APPROVED`: start the next step.
   - `CHANGES_REQUIRED`: fix exactly the listed items, make a new commit, and go back to point 1 with the same step number.
   - `ESCALATED`: the owner is deciding. Keep polling, and don't proceed until the verdict changes.
4. **If you need a decision this spec doesn't cover**, write `{"step": "<n>", "state": "BLOCKED", "commit": null, "summary": "...", "question": "<the decision, with 2-3 options and your recommendation>"}`, then wait as in point 2, matching on your question. Never guess on security, data or safety decisions.
5. **If no verdict arrives within 60 minutes**, that's stop condition 6: stop and write the final report.
6. **When all steps are approved**, write `{"step": "final", "state": "DONE", "commit": "<sha>", "summary": "<final report path>", "question": null}`.

Never edit `.supervision/review.json`. Never commit `.supervision/`.

## Steps
{{STEPS}}
<!-- Write each step as:
### Step N: <ID> <title>
Problem: <what's wrong, with evidence>
Failing tests to write first: <named tests, each with its exact assertion>
Fix: <the exact design; decide it here so the builder never has to>
-->

## Definition of done (check every item and report each one)
{{DONE_CRITERIA}}
- No pushes, no network calls, no paid calls, and no secrets read.
- One commit per step on `{{BUILDER_BRANCH}}`, each one APPROVED by the reviewer.

## Stop conditions (stop, commit nothing broken, and report)
1. The baseline checks aren't green before you change anything.
2. An existing test contradicts this spec, or a fix would require weakening a test.
3. A fix needs a network call, a new paid service, or reading a secret.
4. The same step fails its checks 3 times in a row after honest fix attempts.
5. An instruction here conflicts with the repo's `AGENTS.md` or `CLAUDE.md`. Those files win.
6. No reviewer verdict arrives within 60 minutes of a status write.

## Final report (always write it, even if stopped)
- Every definition-of-done item with PASS or FAIL and evidence (the command and its last lines of output).
- The commits (`git log --oneline {{BASE_BRANCH}}..{{BUILDER_BRANCH}}`).
- Each step or finding with the test that covers it, or "not confirmed" with the reason.
- Open risks, and anything you decided that this spec didn't cover.
