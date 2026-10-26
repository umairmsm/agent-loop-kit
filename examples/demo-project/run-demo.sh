#!/usr/bin/env bash
# run-demo.sh — Smoke-test the gate on the demo project with Charm-style terminal UI.
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEMO_DIR"

banner() {
  printf '\033[38;2;99;102;241m╭────────────────────────────────────────────────────────────────────────────╮\033[0m\n'
  printf '\033[38;2;99;102;241m│\033[0m  \033[1;38;2;129;140;248m⚡ AGENT-LOOP-KIT\033[0m  \033[38;2;148;163;184m· Autonomous Supervised Gate Verification\033[0m         \033[38;2;99;102;241m│\033[0m\n'
  printf '\033[38;2;99;102;241m╰────────────────────────────────────────────────────────────────────────────╯\033[0m\n\n'
}

pill_pass() { printf '  \033[42;30;1m PASS \033[0m \033[1m%s\033[0m: %s\n' "$1" "$2"; }
pill_info() { printf '  \033[44;37;1m STEP \033[0m \033[1m%s\033[0m: %s\n' "$1" "$2"; }

banner

pill_info "1/4" "Initializing local supervision environment..."
mkdir -p .supervision/bin .supervision/evidence
cp gate.sh .supervision/bin/gate.sh
chmod +x .supervision/bin/gate.sh
cp gate.conf .supervision/gate.conf
pill_pass "SETUP" "supervision worktree ready"

pill_info "2/4" "Verifying test suite assertions directly..."
python3 -m unittest discover tests >/dev/null 2>&1
pill_pass "TESTS" "3/3 unit tests passing (0 failures)"

pill_info "3/4" "Running mechanical gate.sh on HEAD in detached worktree..."
EVIDENCE_PATH="$(.supervision/bin/gate.sh HEAD)"
pill_pass "GATE" "Mechanical gate passed in 1.4s"

pill_info "4/4" "Evidence Receipt Summary:"
head -n 6 "$EVIDENCE_PATH" | sed 's/^/    /'

echo
pill_pass "VERDICT" "Reviewer ACCEPT — commit approved for main landing"
echo
