#!/usr/bin/env bash
# run-demo.sh — Smoke-test the gate on the demo project.
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEMO_DIR"

echo "=== [1/4] Initializing local supervision environment ==="
mkdir -p .supervision/bin .supervision/evidence
cp gate.sh .supervision/bin/gate.sh
chmod +x .supervision/bin/gate.sh
cp gate.conf .supervision/gate.conf

echo "=== [2/4] Verifying unit tests directly ==="
python3 -m unittest discover tests

echo "=== [3/4] Running gate.sh on HEAD ==="
EVIDENCE_PATH="$(.supervision/bin/gate.sh HEAD)"

echo "=== [4/4] Output from gate evidence file ==="
cat "$EVIDENCE_PATH"

echo ""
echo "Demo Gate PASS: Evidence file created at $EVIDENCE_PATH"
