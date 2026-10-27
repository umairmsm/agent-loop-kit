#!/usr/bin/env bash
# install-links.sh — install agent-loop-kit commands and Claude Code skills/agents.
#   bash bin/install-links.sh            # link everything except loop daemon
#   bash bin/install-links.sh --loop     # also link agy-loop and agy-resume
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
BIN_DIR="${INSTALL_BIN_DIR:-$HOME/.local/bin}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BK="$HOME/.local/share/agent-loop-kit-backup-$(date +%F)"

link() {  # link <repo path> <target>
  local src="$KIT_DIR/$1" dst="$2"
  [ "$(readlink -f "$dst" 2>/dev/null)" = "$src" ] && { echo "ok      $dst"; return; }
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BK"
    mv "$dst" "$BK/"
    echo "backup  $dst -> $BK/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked  $dst"
}

mkdir -p "$BIN_DIR" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

for a in gate-runner step-reviewer security-reviewer; do
  if [ -f "$KIT_DIR/agents/$a.md" ]; then
    link "agents/$a.md" "$CLAUDE_DIR/agents/$a.md"
  fi
done

link "skills/agent-supervisor" "$CLAUDE_DIR/skills/agent-supervisor"
if [ -d "$KIT_DIR/skills/brain" ]; then
  link "skills/brain" "$CLAUDE_DIR/skills/brain"
fi
if [ -d "$KIT_DIR/skills/supervised-build" ]; then
  link "skills/supervised-build" "$CLAUDE_DIR/skills/supervised-build"
fi

for s in agy-safe agy-sessions agyr supervisor-router brain model s agy-supervise agy-review agy-claims-audit review-text-to-json loop-status; do
  link "bin/$s" "$BIN_DIR/$s"
done

if [ "${1:-}" = "--loop" ]; then
  if pgrep -x agy-loop >/dev/null; then
    echo "agy-loop is running; not relinking it. Try again when it finishes." >&2
    exit 1
  fi
  link "bin/agy-loop" "$BIN_DIR/agy-loop"
  link "bin/agent-loop" "$BIN_DIR/agent-loop"
  link "bin/loop" "$BIN_DIR/loop"
  link "bin/agy-resume" "$BIN_DIR/agy-resume"
  echo "Setup complete. Linked agy-loop, agent-loop, loop, and agy-resume to $BIN_DIR"
fi
