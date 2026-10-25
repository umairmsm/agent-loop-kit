#!/usr/bin/env bash
# Builder helper: wait up to 60 min for the reviewer's verdict on one commit, then print it.
# Usage: bash .supervision/bin/wait_verdict.sh <full-sha-or-question-text>
set -u
key="${1:?usage: wait_verdict.sh <sha>}"
f="$(git rev-parse --show-toplevel)/.supervision/review.json"
for _ in $(seq 1 120); do
  grep -qF -- "$key" "$f" 2>/dev/null && { cat "$f"; exit 0; }
  sleep 30
done
echo "NO_VERDICT_WITHIN_60_MIN"; exit 1
