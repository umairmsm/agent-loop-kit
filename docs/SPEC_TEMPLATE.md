# Task: <one-line goal> (<ID prefix, e.g. FEAT-01>)

You are working autonomously in `<repo path>`. Read `AGENTS.md` and `CLAUDE.md` first. They win if anything conflicts, except: <named owner decision, with date>.

**Why:** <link to the plan or issue, and one sentence on the value>.

Branch `<feature/branch>`   Base `main`

## Already done (don't redo; build on it)
- <commit sha: what exists, with file paths and function names>

## Hard rules
- **Rule zero: <what must not change>.** For example: Existing public API identical, all regression tests pass after every step.
- **Architecture:** <project standards: language version, linting, formatting rules, architecture layers>.
- **Tests are never weakened, skipped or re-snapshotted,** except where explicitly specified.
- **Local only.** No staging, live, server, DNS, or external production network calls. No new dependencies without explicit owner approval.
- **Commits:** one per step, Conventional Commits, step ID in the subject. Never edit `.supervision/`, and never write verdicts.

### Step 1: <ID-01>, <name>   [tags: security, if applicable]
- **Change:** <files and functions; exact behaviour; exact error codes/messages>
- **Tests:** `<tests/path_test.py>`: <test names and exactly what each asserts, with "equals" vs "contains" stated>
- **Revert-check:** <the fixing lines to disable and the test that must then fail>
- **Done when:** <the commands that must be green, e.g. `pytest tests/test_feature.py`, `ruff check .`>

### Step 2: <ID-02>, <name>
- …

### Step N: <ID-0N>, docs and report
- `docs/supervision/REPORT_<TASK>.md`: what changed, anything not done and why, and the verification steps for the owner.

## Definition of done
- Every step is APPROVED by the reviewer. The gate is clean: full test suite, lint 0, all probes ok, secret scan clean.
- All baseline tests remain passing.
