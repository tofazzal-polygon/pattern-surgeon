#!/usr/bin/env bash
# Drives the skill against fixtures. Run from repo root.
# Positive: skill applies pattern AND verify.sh stays green.
# Negative + baseline-red: skill must NOT modify code.
set -euo pipefail
fail=0
for d in tests/fixtures/*-pos; do
  ( cd "$d" && npm i --silent >/dev/null 2>&1 || true )
  echo "POS  $d : run pattern-surgeon on src.ts, then:"
  echo "     bash skills/pattern-surgeon/scripts/verify.sh  # expect exit 0"
done
for d in tests/fixtures/*-neg tests/fixtures/baseline-red; do
  echo "NEG  $d : skill must recommend NO refactor / no edits"
done
echo "Manual/agent-driven checklist printed. fail=$fail"
exit $fail
