#!/usr/bin/env bash
# Independent evidence for one builder-agent commit. Never touches the shared working tree:
# every check runs in a throwaway detached worktree that is deleted afterwards.
# Usage: .supervision/bin/gate.sh <commit-sha>     (config: .supervision/gate.conf)
set -uo pipefail

# Usage: removed_tests <repo> <base> <sha> <paths...>  -> prints deleted test names and newly added skip/xfail markers
removed_tests() {
  local repo="$1" base="$2" sha="$3"; shift 3
  local names_base names_new
  local -x LC_ALL=C   # sort and comm must use the same byte order; under en_US comm rejects sort's output
  names_base=$(git -C "$repo" grep -h -o -E '^\s*(async\s+)?def (test_[A-Za-z0-9_]+)' "$base" -- "$@" 2>/dev/null | sed -E 's/.*def //' | sort -u)
  names_new=$(git -C "$repo" grep -h -o -E '^\s*(async\s+)?def (test_[A-Za-z0-9_]+)' "$sha" -- "$@" 2>/dev/null | sed -E 's/.*def //' | sort -u)
  comm -23 <(echo "$names_base") <(echo "$names_new") | sed 's/^/deleted: /'
  git -C "$repo" diff "$base" "$sha" -- "$@" | grep -E '^\+.*(pytest\.mark\.(skip|xfail)|pytest\.skip\(|\b(it|test|describe)\.skip\(|\bx(it|describe)\()' | sed 's/^/new skip: /'
}

REPO="$(git rev-parse --show-toplevel)"
CONF="${GATE_CONF:-$REPO/.supervision/gate.conf}"
if [ ! -f "$CONF" ] && [ -f "$PWD/.supervision/gate.conf" ]; then
  CONF="$PWD/.supervision/gate.conf"
fi
[ -f "$CONF" ] || { echo "missing $CONF" >&2; exit 2; }
# shellcheck source=/dev/null
source "$CONF"   # defines BASE_BRANCH, TEST_CMD, LINT_CMD, FORMAT_CMD, ENV_CMD, PROBES=()
SHA="$(git -C "$REPO" rev-parse --short "$1")"
WT="$(mktemp -d "${SUPERVISE_WORKDIR:-/tmp}/agent-gate-$(basename "$REPO")-$SHA-XXXX")"; rmdir "$WT"
OUT="$REPO/.supervision/evidence/$SHA.txt"
mkdir -p "$(dirname "$OUT")"
rm -rf "$WT"; git -C "$REPO" worktree add --detach -q "$WT" "$SHA" || exit 2
run() { local label="$1"; shift; [ -z "$*" ] && return; echo "--- $label ---"; (cd "$WT" && timeout "${GATE_TIMEOUT:-900}" bash -c "$*" 2>&1 | tail -"${TAIL_LINES:-4}"); echo "exit=${PIPESTATUS[0]}"; }
{
  echo "commit: $(git -C "$REPO" log -1 --format='%h %s' "$SHA")"
  echo "commits since $BASE_BRANCH: $(git -C "$REPO" rev-list --count "$BASE_BRANCH..$SHA")"
  run "environment" "${ENV_CMD:-}"
  run "tests" "$TEST_CMD"
  run "lint" "${LINT_CMD:-}"
  run "format" "${FORMAT_CMD:-}"
  for p in "${PROBES[@]:-}"; do [ -n "$p" ] && run "probe: $p" "$p"; done
  echo "--- tests removed or skipped vs $BASE_BRANCH ---"
  r=$(removed_tests "$REPO" "$BASE_BRANCH" "$SHA" "${TEST_PATHS:-tests test spec}")
  echo "${r:-none}"
  echo "--- secret scan (added lines vs $BASE_BRANCH) ---"
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks dir --no-banner --redact "$WT" 2>&1 | tail -3 || echo "leak found"
  else
    SECRET_REGEX='^\+.*(sk-''(proj-|ant-)?[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|g''hp_[A-Za-z0-9]{36}|xox''[baprs]-[A-Za-z0-9-]{10,}|BEGIN [A-Z ]*PRIVATE KEY)'
    git -C "$REPO" diff "$BASE_BRANCH" "$SHA" | grep -nE "$SECRET_REGEX" | cut -c1-120 || echo "clean"
  fi
  echo "--- protected paths touched ---"
  git -C "$REPO" diff --name-only "$BASE_BRANCH" "$SHA" | grep -E "${PROTECTED_PATHS:-^$}" || echo "none"
  echo "--- files changed ---"
  git -C "$REPO" diff --stat "$BASE_BRANCH" "$SHA" | tail -15
} > "$OUT" 2>&1
git -C "$REPO" worktree remove --force "$WT"
echo "$OUT"
