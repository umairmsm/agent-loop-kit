#!/usr/bin/env bash
# Independent evidence for one builder-agent commit. Never touches the shared working tree:
# every check runs in a throwaway detached worktree that is deleted afterwards.
set -uo pipefail

# Usage: removed_tests <repo> <base> <sha> <paths...>
removed_tests() {
  local repo="$1" base="$2" sha="$3"; shift 3
  local names_base names_new
  local -x LC_ALL=C
  names_base=$(git -C "$repo" grep -h -o -E '^\s*(async\s+)?def (test_[A-Za-z0-9_]+)' "$base" -- "$@" 2>/dev/null | sed -E 's/.*def //' | sort -u)
  names_new=$(git -C "$repo" grep -h -o -E '^\s*(async\s+)?def (test_[A-Za-z0-9_]+)' "$sha" -- "$@" 2>/dev/null | sed -E 's/.*def //' | sort -u)
  comm -23 <(echo "$names_base") <(echo "$names_new") | sed 's/^/deleted: /'
}

REPO="$(git rev-parse --show-toplevel)"
CONF="${GATE_CONF:-$REPO/.supervision/gate.conf}"
if [ ! -f "$CONF" ] && [ -f "$PWD/.supervision/gate.conf" ]; then
  CONF="$PWD/.supervision/gate.conf"
fi
[ -f "$CONF" ] || { echo "missing $CONF" >&2; exit 2; }
# shellcheck source=/dev/null
source "$CONF"
SHA="$(git -C "$REPO" rev-parse --short "${1:-HEAD}")"
WT="$(mktemp -d "${SUPERVISE_WORKDIR:-/tmp}/agent-gate-$(basename "$REPO")-$SHA-XXXX")"; rmdir "$WT"
OUT="$REPO/.supervision/evidence/$SHA.txt"
mkdir -p "$(dirname "$OUT")"
rm -rf "$WT"; git -C "$REPO" worktree add --detach -q "$WT" "$SHA" || exit 2
run() { local label="$1"; shift; [ -z "$*" ] && return; echo "--- $label ---"; (cd "$WT" && timeout "${GATE_TIMEOUT:-900}" bash -c "$*" 2>&1 | tail -"${TAIL_LINES:-4}"); echo "exit=${PIPESTATUS[0]}"; }
{
  echo "commit: $(git -C "$REPO" log -1 --format='%h %s' "$SHA")"
  echo "commits since $BASE_BRANCH: $(git -C "$REPO" rev-list --count "$BASE_BRANCH..$SHA" 2>/dev/null || echo "0")"
  run "environment" "${ENV_CMD:-}"
  run "tests" "$TEST_CMD"
  run "lint" "${LINT_CMD:-}"
  run "format" "${FORMAT_CMD:-}"
  echo "--- tests removed or skipped vs $BASE_BRANCH ---"
  r=$(removed_tests "$REPO" "$BASE_BRANCH" "$SHA" "${TEST_PATHS:-tests}")
  echo "${r:-none}"
  echo "--- secret scan ---"
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks dir --no-banner --redact "$WT" 2>&1 | tail -3 || echo "leak found"
  else
    echo "gitleaks not installed; skipping secret scan"
  fi
  echo "--- protected paths touched ---"
  git -C "$REPO" diff --name-only "$BASE_BRANCH" "$SHA" 2>/dev/null | grep -E "${PROTECTED_PATHS:-^$}" || echo "none"
  echo "--- files changed ---"
  git -C "$REPO" diff --stat "$BASE_BRANCH" "$SHA" 2>/dev/null | tail -10
} > "$OUT" 2>&1
git -C "$REPO" worktree remove --force "$WT"
echo "$OUT"
