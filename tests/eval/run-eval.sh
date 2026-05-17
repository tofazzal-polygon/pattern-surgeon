#!/usr/bin/env bash
# Drives the skill against fixtures. Run from repo root.
# Positive: skill applies pattern AND verify.sh stays green.
# Negative + baseline-red: skill must NOT modify code.
set -euo pipefail
fail=0

detect_stack() {
  local d="$1"
  if [ -f "$d/pom.xml" ] || [ -f "$d/build.gradle" ] || [ -f "$d/build.gradle.kts" ]; then
    echo java
  elif ls "$d"/*.csproj "$d"/*.sln >/dev/null 2>&1; then
    echo dotnet
  elif [ -f "$d/composer.json" ]; then
    echo php
  elif [ -f "$d/pyproject.toml" ] || [ -f "$d/setup.py" ] || [ -f "$d/requirements.txt" ]; then
    echo python
  elif [ -f "$d/package.json" ]; then
    echo node
  else
    echo unknown
  fi
}

for d in tests/fixtures/*-pos; do
  stack="$(detect_stack "$d")"
  [ "$stack" = node ] && ( cd "$d" && npm i --silent >/dev/null 2>&1 || true )
  echo "POS  $d (stack: $stack) : run pattern-surgeon on the smelly source, then:"
  echo "     bash skills/pattern-surgeon/scripts/verify.sh  # expect exit 0"
done
for d in tests/fixtures/*-neg tests/fixtures/baseline-red*; do
  [ -d "$d" ] || continue
  echo "NEG  $d (stack: $(detect_stack "$d")) : skill must recommend NO refactor / no edits"
done
echo "Manual/agent-driven checklist printed. fail=$fail"
exit $fail
