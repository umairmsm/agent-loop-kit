#!/usr/bin/env bash
# Emit one line per change to the builder's status file. Run as a Claude Code Monitor command.
cd "$(git rev-parse --show-toplevel)" || exit 1
f=.supervision/ag_status.json
last=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
while true; do
  if [ -f "$f" ]; then
    cur=$(md5sum "$f" | cut -d' ' -f1)
    if [ "$cur" != "$last" ]; then last=$cur; echo "BUILDER_STATUS $(tr -d '\n' < "$f" | cut -c1-400)"; fi
  fi
  sleep 2
done
