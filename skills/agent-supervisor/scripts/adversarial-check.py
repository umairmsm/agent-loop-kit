#!/usr/bin/env python3
"""
adversarial-check.py — Deterministic verification of commit hygiene and test integrity.

Checks:
1. Were any tests deleted or skipped vs the base branch?
2. Were any protected paths modified?
3. Were files outside the declared task scope modified?
"""

import argparse
import json
import os
import re
import subprocess
import sys


def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.stdout.strip(), res.stderr.strip(), res.returncode


def get_test_names(repo, ref, test_paths):
    names = set()
    for path in test_paths:
        cmd = ["git", "-C", repo, "grep", "-h", "-o", "-E", r"^\s*(async\s+)?(def|it|test|func)\s+([A-Za-z0-9_]+)", ref, "--", path]
        out, _, _ = run_cmd(cmd)
        for line in out.splitlines():
            line = line.strip()
            if line:
                parts = re.split(r"\s+", line)
                if len(parts) >= 2:
                    names.add(parts[-1].strip("('\""))
    return names


def main():
    parser = argparse.ArgumentParser(description="Deterministic adversarial verification")
    parser.add_argument("--repo", default=".", help="Path to repo root")
    parser.add_argument("--base", required=True, help="Base branch/commit")
    parser.add_argument("--sha", required=True, help="Commit sha to check")
    parser.add_argument("--scope", default="", help="Regex of permitted file paths")
    parser.add_argument("--protected", default=r"^(\.github/|migrations/|infra/)", help="Protected path regex")
    parser.add_argument("--test-paths", nargs="+", default=["tests", "test", "spec", "src"], help="Test directories")
    parser.add_argument("--json-out", default="", help="Optional JSON output file")

    args = parser.parse_args()
    repo = os.path.abspath(args.repo)

    diff_files_out, _, _ = run_cmd(["git", "-C", repo, "diff", "--name-only", args.base, args.sha])
    touched_files = [f.strip() for f in diff_files_out.splitlines() if f.strip()]

    protected_re = re.compile(args.protected) if args.protected else None
    protected_hits = [f for f in touched_files if protected_re and protected_re.search(f)]

    scope_re = re.compile(args.scope) if args.scope else None
    out_of_scope = [f for f in touched_files if scope_re and not scope_re.search(f)]

    base_tests = get_test_names(repo, args.base, args.test_paths)
    new_tests = get_test_names(repo, args.sha, args.test_paths)
    deleted_tests = sorted(list(base_tests - new_tests))

    diff_text, _, _ = run_cmd(["git", "-C", repo, "diff", args.base, args.sha])
    skip_re = re.compile(r"^\+.*(pytest\.mark\.(skip|xfail)|pytest\.skip\(|\b(it|test|describe)\.skip\(|\bx(it|describe)\()", re.MULTILINE)
    new_skips = skip_re.findall(diff_text)

    passed = len(protected_hits) == 0 and len(out_of_scope) == 0 and len(deleted_tests) == 0 and len(new_skips) == 0

    report = {
        "passed": passed,
        "commit": args.sha,
        "base": args.base,
        "touched_count": len(touched_files),
        "protected_hits": protected_hits,
        "out_of_scope": out_of_scope,
        "deleted_tests": deleted_tests,
        "new_skips_count": len(new_skips),
    }

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

    print(json.dumps(report, indent=2))
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
