#!/usr/bin/env bash
set -euo pipefail
# Extensibility: add another language by adding a marker branch below that sets
# TYPECHECK and TEST; the exit-code contract (0 ok / 2 typecheck / 3 tests /
# 4 no test) and SKILL.md detection rules stay unchanged.

TYPECHECK=""   # command string or "" to skip typecheck
TEST=""        # command string; empty => exit 4 (no test)
STACK="unknown"

have() { command -v "$1" >/dev/null 2>&1; }

if [ -f package.json ]; then
  STACK="node"
  if [ -f pnpm-lock.yaml ]; then PM=pnpm; elif [ -f yarn.lock ]; then PM=yarn; else PM=npm; fi
  [ -f tsconfig.json ] && TYPECHECK="$( [ "$PM" = npm ] && echo 'npx --no-install tsc --noEmit' || echo "$PM exec tsc --noEmit")"
  node -e "process.exit(require('./package.json').scripts?.test?0:1)" 2>/dev/null && TEST="$PM test" || TEST=""
elif [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
  STACK="python"
  if [ -f mypy.ini ] || grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; then have mypy && TYPECHECK="mypy ."; fi
  if python3 -m pytest --collect-only -q >/dev/null 2>&1; then TEST="python3 -m pytest -q"; else TEST=""; fi
elif [ -f app/src/main/AndroidManifest.xml ]; then
  STACK="android-kotlin"
  TYPECHECK="./gradlew -q compileDebugKotlin"
  TEST="./gradlew -q testDebugUnitTest"
  [ -x ./gradlew ] || { TYPECHECK="gradle -q compileDebugKotlin"; TEST="gradle -q testDebugUnitTest"; }
elif [ -f pom.xml ]; then
  STACK="maven"; TYPECHECK="mvn -q compile"; TEST="mvn -q test"
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  STACK="gradle"; TYPECHECK="./gradlew -q compileJava"; TEST="./gradlew -q test"
  [ -x ./gradlew ] || { TYPECHECK="gradle -q compileJava"; TEST="gradle -q test"; }
elif compgen -G './*.sln' >/dev/null || compgen -G './*.slnx' >/dev/null || compgen -G './*.csproj' >/dev/null; then
  STACK="dotnet"; TYPECHECK="dotnet build -clp:ErrorsOnly"; TEST="dotnet test --nologo"
elif [ -f composer.json ]; then
  STACK="composer"
  { [ -f vendor/bin/phpstan ] && TYPECHECK="vendor/bin/phpstan analyse --no-progress"; } || true
  if [ -f artisan ]; then TEST="php artisan test"
  elif [ -f vendor/bin/phpunit ]; then TEST="vendor/bin/phpunit"
  else TEST=""; fi
elif [ -f pubspec.yaml ]; then
  if grep -q 'flutter:' pubspec.yaml 2>/dev/null; then
    STACK="flutter"; TYPECHECK="flutter analyze"; TEST="flutter test"
  else
    STACK="dart"; TYPECHECK="dart analyze"; TEST="dart test"
  fi
elif [ -f Package.swift ]; then
  STACK="swift"; TYPECHECK="swift build"; TEST="swift test"
fi

echo "pattern-surgeon: detected stack=$STACK"

if [ -n "$TYPECHECK" ]; then
  eval "$TYPECHECK" || { echo "pattern-surgeon: typecheck FAILED" >&2; exit 2; }
fi
if [ -z "$TEST" ]; then
  echo "pattern-surgeon: no test runner/target found" >&2; exit 4
fi
eval "$TEST" || { echo "pattern-surgeon: tests FAILED" >&2; exit 3; }
echo "pattern-surgeon: verify OK"
