# Supervision lessons (learned on real runs; every review applies these)

## Trust and evidence
- **Builder "done" claims are not evidence.** A builder log claimed "all steps executed" but skipped essential security flags. A builder report claimed production caching was active; it wasn't. Verify every claim against the repository, the dev site, or explicit test evidence.
- An auditor's suggested fix can be dangerous. "Require ip <Cloudflare ranges>" would have blocked every visitor if the reverse proxy already restores REMOTE_ADDR to the visitor IP. Check how the platform actually behaves before approving infrastructure advice.

## Gate mechanics
- **Dev server serves the shared checkout, not the gate worktree** (containers and similar). The gate must prove the shared checkout is at the reviewed sha and clean before trusting container-backed tests and probes.
- **Status writes lag commits.** The builder often commits first and writes ag_status.json up to 2 minutes later. Gate the commit anyway; don't call it a protocol breach unless the status never arrives.
- **Broken worktree ≠ failing code.** "cannot remove working tree", an empty reviewed sha, or a collapsed test count means re-run the gate (prune first).
- **verdict.commit must be the FULL sha** from git rev-parse. The builder matches on it; a wrong or short sha leaves it waiting forever.
- Desktop-only `test.skip(project !== 'desktop')` guards are expected run-once guards, not weakened tests.

## Spec conformance (the usual misses)
- Guards and conditions (for example, early return if a conflicting module is active).
- Additions to existing test lists (for example, adding new routes to the a11y audit).
- Exact copy: "Page not found" vs "Page Not Found (404)"; curly quotes; no prefixes like "Category:".
- Duplicated files committed to satisfy a container path. Require a single source plus runtime staging.
- New files not named in the spec: accept if needed-by-spec, but check every area they affect.

## Safety-kernel and security work (always escalate to the main session)
- **Passing tests can hide a fake fix.** A test asserted that an invalid ID was *not* valid, which documents the bug instead of fixing it. The new helper existed but nothing called it. Read what each test asserts; check that the new code is actually called.
- **Revert-check every fix.** Disable the fix lines in a scratch worktree and rerun the step's tests; they must fail. This exposed a refresh lock that did nothing. A test that passes without the fix proves nothing.
- **Never hold a DB transaction across network I/O or human input.** Prompting or network requests during an open transaction blocks other operations. Read secrets and prompts before opening the transaction.
- **Network I/O, same rule.** A credential refresh held a database write lock across network calls, which blocked emergency operations.
- **In-process locks don't serialize processes.** `threading.Lock` doesn't cover worker processes plus a manual run. Use file locks or DB-level compare-and-swap, and test with real multiprocessing.
- **Test seams become bypasses.** `isinstance(connector, Mock)` exempted any Mock from the isolation gate. Production code must never import `unittest.mock`; exempt only explicitly named fake classes.
- **Python can't keep a secret from same-user code.** An importable "private" sentinel let any same-user process forge an authorization token. Real boundaries are OS users, file ownership and sudo, not module privacy.
- **Env and path overrides are bypasses.** Environment variables and paths let a caller pick the trust root. Resolve security paths from root-owned config or standard paths, never the caller's environment.
- **A root-run script must not execute agent-writable code.** Install root-owned copies in isolated directories; run commands with sanitized environments; hash-lock runtime and build dependencies.
- **An independent model family earns its cost.** Cross-family audits (e.g. Claude reviewing Codex/Antigravity or vice-versa) find critical issues that a single model family misses.

## Production and outward-facing work (always escalate to the main session)
- Edge proxy stacking (e.g. CDN in front of another CDN) causes 429s for real visitors. Watch for duplicate proxy layers.
- Email "sent" ≠ delivered. Ensure aligned SPF/DKIM; check bounces in the server mailbox.
- A cached stylesheet with a static query string hides deploys. Version assets by file hash or filemtime.
- Probing a non-existent script returns 404 even when security blocks work. Probe with a real harmless file.
- Bot-protection challenge pages answer curl on login/admin URLs. Verify forms with an automated browser.
- DNS, certificates, server configuration, and deploys need explicit owner approval of the exact change.

## Static export and frontend build observations
- **Retiring an artifact: grep the WHOLE repo for its readers before writing the spec.** Removing an artifact without checking downstream scripts breaks nightly pipelines.
- **`rsync --exclude` also blocks new files.** A rule meant to protect old assets can stop new fingerprinted assets from reaching docroot. Use explicit filter rules and verify referenced assets exist on disk.
- **A live-baseline check runs the NEW specs against the OLD production tree.** Any deploy that changes an asserted header fails by design; give it an explicit, loud skip flag.
- **Builders idle after CHANGES_REQUIRED** unless the protocol says "start the fixes in the same turn; never end your turn while a step is open". With that line: zero idle stalls.
- **Builder summaries omit failures.** Always read the raw test log, not the model's summary.
- **Measure with the right wait.** A latency or element test that stops at "first matching element" can stop before the real work finishes. Wait for state change plus network idle.
- **Attribute visual diffs before re-baselining.** Re-run the export with the old config; an identical diff means data drift, not code change.
- **Design flaws are the reviewer's too.** Fix them in the verdict as an amendment for later steps rather than forcing rework of correct code.
- Small fixes found while reviewing can be folded into the NEXT step's commit instead of a separate round.
- **"Accept this file edit?" stalls unattended runs.** Command allowlists do not cover file edits. Start the builder with appropriate acceptance modes, and guard reviewer files outside the repo.
- **Detect removed tests by comparing test names, not def lines.** A signature change looks like a deletion if comparing def lines. Use word boundaries in skip patterns.
- **An approval preview must show the exact bytes that get published.** Rich text or terminal formatting can hide control characters or raw strings. Print untrusted text with formatting off.
- **A builder can approve itself.** Never allow the builder to write verdicts or run review tooling, and retro-review any step not signed by the reviewer.
- **Audit the builder's session log, not just its commits.** Check the builder's command history for credential reads, unexpected network calls, sudo, and push attempts.

## Multi-tenant isolation and security runs
- **Regex filters for model-written SQL keep failing.** Complex SQL bypasses regex-based parsers easily. A green unit suite proves little. Review such steps adversarially and enforce database-level isolation (Row-Level Security or read-only roles).
- **The builder patches the cases, not the rule.** When asked for input validation, models often add checks for the exact test inputs. Name the general rule in the fix list, and add unseen edge cases to probes.
- **Mutation-test every scoping line.** Verify that removing scoping filters causes tests to turn red.
- **Statuses lag commits.** `ag_status.json` often names the previous commit when a new one lands. Gate the commit itself, not the status file.
- **An amend is sometimes the only fix.** A token-shaped test fixture in git history fails secret scans over the whole commit range. Require dummy placeholders in test fixtures.
- **An allowlist needs reason-to-path binding.** Route guards must bind reasons to specific path patterns.
- **Escalation rules must fit the project.** Escalate on protected paths, schema, money, secrets, and owner decisions; review in-spec logic adversarially.
- **Keep reviewer state out of /tmp.** Reboots erase temporary state mid-package. Use persistent user state directories.

## Session recovery and live state runs
- **Reviewers and builders run against isolated targets.** For tools that act on live state, specs and reviewer prompts must ensure all path overrides target temporary directories, and supervisors check for leftover processes or state files.
