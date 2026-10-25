# Contributing to agent-loop-kit

Thank you for contributing to `agent-loop-kit`! We welcome contributions from developers of all skill levels.

---

## 1. Ground Rules & Code of Conduct
- Be respectful, constructive, and collaborative. All interactions follow our [Code of Conduct](CODE_OF_CONDUCT.md).
- **No AI-generated spam PRs**: Every PR must solve a real problem, include tests or documentation proof, and be human-verified. Automated batch cosmetic PRs (e.g. changing 1 word across 20 files) will be closed.

---

## 2. Getting Started
1. Check [Good First Issues](docs/CONTRIBUTING_TASKS.md) for 25 pre-scoped contributor tasks across gates, notifiers, adapters, and documentation.
2. Fork the repository and create your branch from `main`:
   ```bash
   git checkout -b feature/my-new-gate
   ```
3. Test your changes locally before submitting:
   ```bash
   # Run shellcheck on modified bash scripts
   shellcheck bin/* skills/agent-supervisor/scripts/*
   # Verify the demo gate runs cleanly
   cd examples/demo-project && ./run-demo.sh
   ```

---

## 3. Pull Request Guidelines
- **Atomic Changes**: Keep PRs focused (<150 lines of diff where possible). One feature or bug fix per PR.
- **Commit Messages**: Follow Conventional Commits:
  - `feat: add discord webhook notifier`
  - `fix: handle edge case in worktree path cleanup`
  - `docs: add wsl2 installation guide`
- **Developer Certificate of Origin (DCO)**: Sign your commits using `git commit -s` to certify you have the right to submit the code under the MIT license.
- **Review Turnaround**: Maintainers review open PRs within 24–48 hours.

All contributors are credited in release notes and on our README via `@all-contributors`.
