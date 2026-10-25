# Supervisor Playbook (for any LLM, or the repository owner)

Read this when an autonomous loop has stopped or alerted. You may be an LLM reviewer, another agent, or a human supervisor. Work from the repository root.

## 1. Inspect State (Read-Only)
```bash
grep -E "STOP|APPROVED|CHANGES_REQUIRED|ESCALAT" .supervision/loop.log | tail -8
cat .supervision/review.json            # verdict, fix_list, notes of the last review
git log --oneline -5; git status --short
```

## 2. Decision Matrix

| Stop Cause | Safe to Fix Yourself | Escalate to Owner |
|---|---|---|
| **Environment gate failure**: Docker down, missing dev dependency, port conflict, flaky test | Fix local environment (git-ignored files only), then restart loop | Anything requiring server, DNS, infrastructure or security alterations |
| **"Failed review 3 times"**: Fix list contains minor code or test discrepancies inside the step's scope | Make minimal targeted fix, run tests, commit as a supervisor fix, then re-review: `agy-loop <task> --review-only <sha> --from-step N` | The fix list requires a scope, architectural, or policy decision |
| **ESCALATED / BLOCKED** | Only if the reason is a fact you can unambiguously verify locally | Security, secrets, financial logic, production impact, data deletion, new dependencies |
| **Tamper alert / Dirty tree** | Nothing | Always escalate: investigate modified files, clean git status, rebaseline if changes were deliberate |

## 3. Invariants (Never Break These)
- Never write `.supervision/review.json` manually from the builder side.
- Never edit `.supervision/bin` or the gate configuration while a loop runs without running `--rebaseline`.
- Never merge, push, or touch external networks or production systems.
- Never weaken, delete, or skip a test to pass the gate.
- Never read, log, or commit secret credentials or tokens.

## 4. Commands Reference
```bash
agy-loop docs/supervision/TASK_X.md                                   # Run loop from current step
agy-loop docs/supervision/TASK_X.md --review-only <sha> --from-step N # Run gate + review on one commit
agy-loop docs/supervision/TASK_X.md --from-step N                     # Resume loop starting from step N
agy-loop docs/supervision/TASK_X.md --rebaseline                     # Update tamper-detection checksums
```
