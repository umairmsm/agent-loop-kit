# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-25

### Added
- **Separation of Powers Architecture**: Dual-agent setup with Builder (`supervised-build`) and Reviewer (`agent-supervisor`).
- **Core Loop Engine**:
  - `bin/agy-loop`: Unattended CLI multi-step build runner with automated gate and reviewer dispatch.
  - `bin/agent-loop` & `bin/loop`: Ergonomic aliases for the main loop runner.
  - `bin/agy-safe`: Sandbox command intercepter blocking destructive shell actions (push, sudo, rm, remote sync).
  - `bin/agy-resume`: Process-level OAuth token recovery and session resumption.
  - `bin/agy-sessions`: Interactive session manager and transcript archive utility.
  - `bin/install-links.sh`: One-shot symlinker for CLI commands and Claude Code skills.
- **Claude Code Reviewer Subagents**:
  - `agents/gate-runner.md`: Mechanical first-tier execution of tests, lints, probes, and secret scans.
  - `agents/step-reviewer.md`: Sonnet-powered spec compliance and test assertion verification.
  - `agents/security-reviewer.md`: Adversarial Opus-powered mutation testing for `[security]` tasks.
- **Verification & Probing Framework**:
  - `gate.sh`: Throwaway detached git worktree verification runner.
  - Test deletion and skip detection (`removed_tests`).
  - Integrated `gitleaks` secret scanning and tamper detection.
- **Examples**:
  - `examples/demo-project`: Fully functioning minimal project demonstrating the automated gate, failing probe, and passing verdict.
- **Documentation**:
  - Comprehensive ELI10 architecture walkthrough.
  - 25 pre-scoped contributor tasks in `docs/CONTRIBUTING_TASKS.md`.
