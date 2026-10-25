#!/usr/bin/env bash
# Install the supervision channel into the current git repo. Idempotent; never overwrites gate.conf.
set -euo pipefail
SKILL="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(git rev-parse --show-toplevel)"
cd "$REPO"
mkdir -p .supervision/bin .supervision/evidence
cp "$SKILL/templates/gate.sh" .supervision/bin/gate.sh && chmod +x .supervision/bin/gate.sh
if [ ! -f .supervision/gate.conf ]; then
  cp "$SKILL/templates/gate.conf.example" .supervision/gate.conf
  base=$(git symbolic-ref --short HEAD 2>/dev/null || echo main)
  sed -i "s|^BASE_BRANCH=.*|BASE_BRANCH=\"$base\"|" .supervision/gate.conf
  if [ -f package.json ]; then
    sed -i 's#^ENV_CMD=.*#ENV_CMD="node --version"#; s#^TEST_CMD=.*#TEST_CMD="npm test --silent"#; s#^LINT_CMD=.*#LINT_CMD="npm run lint --silent --if-present"#; s#^FORMAT_CMD=.*#FORMAT_CMD=""#' .supervision/gate.conf
  elif [ -f go.mod ]; then
    # shellcheck disable=SC2016
    sed -i 's#^ENV_CMD=.*#ENV_CMD="go version"#; s#^TEST_CMD=.*#TEST_CMD="go test ./..."#; s#^LINT_CMD=.*#LINT_CMD="go vet ./..."#; s#^FORMAT_CMD=.*#FORMAT_CMD="test -z \\"$(gofmt -l .)\\""#' .supervision/gate.conf
  elif [ -f Cargo.toml ]; then
    sed -i 's#^ENV_CMD=.*#ENV_CMD="cargo --version"#; s#^TEST_CMD=.*#TEST_CMD="cargo test -q"#; s#^LINT_CMD=.*#LINT_CMD="cargo clippy -q -- -D warnings"#; s#^FORMAT_CMD=.*#FORMAT_CMD="cargo fmt --check"#' .supervision/gate.conf
  fi
  echo "created .supervision/gate.conf (BASE_BRANCH=$base) — review the commands"
fi
grep -qxF '.supervision/' .gitignore 2>/dev/null || printf '\n# Agent supervision channel (live status; never committed)\n.supervision/\n' >> .gitignore
echo "installed: .supervision/bin/gate.sh  |  task prompt template: $SKILL/templates/task-prompt.md"
