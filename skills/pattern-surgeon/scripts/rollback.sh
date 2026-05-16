#!/usr/bin/env bash
set -euo pipefail
sha="${1:?usage: rollback.sh <checkpoint-sha>}"
echo "===== REJECTED DIFF (attempted change, now reverted) ====="
git diff "$sha" -- . || true
echo "=========================================================="
git checkout "$sha" -- . 2>/dev/null || git restore --source="$sha" -- .
echo "pattern-surgeon: rolled back to $sha"
