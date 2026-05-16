#!/usr/bin/env bash
set -euo pipefail
# Extensibility: to add another language, add a branch that sets the typecheck and test commands; the exit-code contract (0 ok / 2 typecheck / 3 tests / 4 no test script) and SKILL.md detection rules stay unchanged.

if   [ -f pnpm-lock.yaml ]; then PM=pnpm
elif [ -f yarn.lock ];      then PM=yarn
else                             PM=npm
fi

run() { if [ "$PM" = npm ]; then npx --no-install "$@"; else "$PM" exec "$@"; fi; }

if [ -f tsconfig.json ]; then
  run tsc --noEmit || { echo "pattern-surgeon: typecheck FAILED" >&2; exit 2; }
fi

if node -e "process.exit(require('./package.json').scripts?.test?0:1)" 2>/dev/null; then
  "$PM" test || { echo "pattern-surgeon: tests FAILED" >&2; exit 3; }
else
  echo "pattern-surgeon: no test script found" >&2; exit 4
fi
echo "pattern-surgeon: verify OK"
