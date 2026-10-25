# Good First Issues & Contributor Roadmap

Welcome to the `agent-loop-kit` community! We have structured these 25 tasks specifically for contributors looking for hands-on open-source impact. Every task has a defined interface, minimal scope (<100 lines of code), and zero barrier to entry.

To claim an issue, open a pull request or comment on the corresponding issue on GitHub.

---

## Category 1: Pluggable Gates (`skills/agent-supervisor/templates/gates/`)

Gate scripts run inside the isolated detached worktree created by `gate.sh`. Each script inspects the commit and exits 0 on success, or non-zero on error.

- [ ] **TASK-01: Add Biome (TypeScript/JavaScript) Gate Preset**
  - *Goal*: Create `gates/gate-biome.sh` that detects Biome config and runs `biome check --error-on-warnings`.
  - *Complexity*: Easy (~25 lines bash).
- [ ] **TASK-02: Add Ruff (Python) Gate Preset**
  - *Goal*: Create `gates/gate-ruff.sh` running `ruff check .` and `ruff format --check .`.
  - *Complexity*: Easy (~20 lines bash).
- [ ] **TASK-03: Add Clippy & Cargo Test (Rust) Gate Preset**
  - *Goal*: Create `gates/gate-rust.sh` executing `cargo test --quiet` and `cargo clippy -- -D warnings`.
  - *Complexity*: Easy (~30 lines bash).
- [ ] **TASK-04: Add Golangci-lint & Go Test (Go) Gate Preset**
  - *Goal*: Create `gates/gate-go.sh` running `go test ./...` and `golangci-lint run`.
  - *Complexity*: Easy (~25 lines bash).
- [ ] **TASK-05: Add Hadolint (Dockerfile) Linter Gate**
  - *Goal*: Create `gates/gate-docker.sh` that checks any changed Dockerfile against `hadolint`.
  - *Complexity*: Medium (~35 lines bash).
- [ ] **TASK-06: Add ShellCheck Gate for Shell Scripts**
  - *Goal*: Run `shellcheck` across all changed `.sh` files in the commit.
  - *Complexity*: Easy (~25 lines bash).
- [ ] **TASK-07: Add Markdownlint Gate**
  - *Goal*: Validate documentation changes against markdown standards.
  - *Complexity*: Easy (~20 lines bash).
- [ ] **TASK-08: Add SQLFluff Linter Gate for SQL Migrations**
  - *Goal*: Verify SQL formatting and dialect adherence on modified `.sql` files.
  - *Complexity*: Medium (~30 lines bash).
- [ ] **TASK-09: Add PHPStan / Pest Gate Preset (PHP)**
  - *Goal*: Support modern PHP and Laravel/WordPress projects with PHPStan verification.
  - *Complexity*: Medium (~30 lines bash).
- [ ] **TASK-10: Add Terraform/OpenTofu fmt & validate Gate**
  - *Goal*: Verify infrastructure-as-code changes with `tofu fmt -check` and `tofu validate`.
  - *Complexity*: Easy (~25 lines bash).

---

## Category 2: Notification Hooks (`bin/notifiers/`)

When a loop finishes, halts on an error, or needs a human decision on an escalation, notify scripts deliver an alert to the developer.

- [ ] **TASK-11: Add Discord Webhook Notifier**
  - *Goal*: Create `bin/notifiers/notify-discord.sh` that sends a rich embed with commit sha and verdict.
  - *Complexity*: Easy (~35 lines bash/curl).
- [ ] **TASK-12: Add Slack Webhook Notifier**
  - *Goal*: Create `bin/notifiers/notify-slack.sh` sending structured BlockKit alerts.
  - *Complexity*: Easy (~35 lines bash/curl).
- [ ] **TASK-13: Add Matrix Room Notifier**
  - *Goal*: Send end-to-end encrypted or standard room alerts via Matrix Client-Server API.
  - *Complexity*: Medium (~45 lines bash/curl).
- [ ] **TASK-14: Add ntfy.sh Push Notification Hook**
  - *Goal*: Native script for mobile and desktop push alerts via free ntfy.sh instances.
  - *Complexity*: Easy (~20 lines bash).
- [ ] **TASK-15: Add Pushover Alert Hook**
  - *Goal*: Send emergency priority alerts on ESCALATED or tamper events.
  - *Complexity*: Easy (~25 lines bash).
- [ ] **TASK-16: Add Linux Desktop `notify-send` / macOS `osascript` Local Alert**
  - *Goal*: Native desktop notification popup when running local loops in the background.
  - *Complexity*: Easy (~25 lines bash).

---

## Category 3: Builder CLI Adapters (`bin/adapters/`)

Support additional open-source and commercial coding agents as the Builder half of the loop.

- [ ] **TASK-17: Add Aider CLI Builder Adapter**
  - *Goal*: Wrap Aider (`aider --yes --message ...`) to execute structured task prompts autonomously.
  - *Complexity*: Medium (~50 lines bash).
- [ ] **TASK-18: Add Codex CLI Builder Adapter**
  - *Goal*: Support OpenAI Codex command-line runners.
  - *Complexity*: Medium (~45 lines bash).
- [ ] **TASK-19: Add OpenCode Interpreter Adapter**
  - *Goal*: Provide an adapter for OpenCode headless terminal execution.
  - *Complexity*: Medium (~50 lines bash).
- [ ] **TASK-20: Add Cursor Terminal Headless Adapter**
  - *Goal*: Provide a shim for running Cursor CLI agents headlessly.
  - *Complexity*: Medium (~45 lines bash).

---

## Category 4: Platform & Documentation Enhancements

- [ ] **TASK-21: Add macOS Homebrew Installation Guide & Formula**
  - *Goal*: Document and package brew-based dependency management (gitleaks, shellcheck, coreutils).
- [ ] **TASK-22: Add Windows WSL2 Quickstart Guide**
  - *Goal*: Step-by-step setup walkthrough for Ubuntu on WSL2 with Docker desktop integration.
- [ ] **TASK-23: Add 1-Click VS Code DevContainer Configuration**
  - *Goal*: Add `.devcontainer/devcontainer.json` pre-installing Claude Code, Antigravity, and tools.
- [ ] **TASK-24: Add Multi-Language README Translations**
  - *Goal*: Translate `README.md` into French, Spanish, German, Japanese, and Chinese.
- [ ] **TASK-25: Add GitHub Actions Automated Gate Check Workflow Template**
  - *Goal*: Provide `.github/workflows/agent-gate.yml` to run the gate inside GitHub CI on PRs.
