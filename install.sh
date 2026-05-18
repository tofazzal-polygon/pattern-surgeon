#!/usr/bin/env bash
# pattern-surgeon installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash
#   curl -fsSL ... | bash -s -- --project   (project-local install)
#   curl -fsSL ... | bash -s -- --uninstall

set -euo pipefail

REPO="https://github.com/nuhin13/pattern-surgeon"
ARCHIVE="https://github.com/nuhin13/pattern-surgeon/archive/refs/heads/main.tar.gz"
SKILL_NAME="pattern-surgeon"

# ── colors ────────────────────────────────────────────────────────────────
bold()  { printf '\033[1m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
cyan()  { printf '\033[36m%s\033[0m' "$1"; }
dim()   { printf '\033[2m%s\033[0m' "$1"; }
err()   { printf '\033[31mError:\033[0m %s\n' "$1" >&2; exit 1; }

# ── argument parsing ──────────────────────────────────────────────────────
PROJECT=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --project|-p)   PROJECT=1 ;;
    --uninstall)    UNINSTALL=1 ;;
    --help|-h)
      printf '%s\n' \
        "$(bold 'pattern-surgeon') installer" \
        "" \
        "$(bold Usage)" \
        "  # Global install (use in any project)" \
        "  curl -fsSL $ARCHIVE | bash" \
        "" \
        "  # Project-local install (current directory only)" \
        "  curl -fsSL $ARCHIVE | bash -s -- --project" \
        "" \
        "  # Uninstall" \
        "  curl -fsSL $ARCHIVE | bash -s -- --uninstall" \
        "" \
        "$(bold 'Plugin install (Claude Code native)'):" \
        "  /plugin marketplace add nuhin13/pattern-surgeon" \
        "  /plugin install pattern-surgeon"
      exit 0
      ;;
  esac
done

# ── target directory ──────────────────────────────────────────────────────
if [ "$PROJECT" -eq 1 ]; then
  TARGET="${PWD}/.claude/skills/${SKILL_NAME}"
else
  TARGET="${HOME}/.claude/skills/${SKILL_NAME}"
fi

# ── uninstall ─────────────────────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
  if [ -d "$TARGET" ]; then
    rm -rf "$TARGET"
    printf '%s pattern-surgeon removed from %s\n' "$(green '✓')" "$(dim "$TARGET")"
  else
    printf 'pattern-surgeon not found at %s\n' "$TARGET"
  fi
  exit 0
fi

# ── check dependencies ────────────────────────────────────────────────────
command -v curl >/dev/null || command -v wget >/dev/null \
  || err "curl or wget is required"

# ── download & extract ────────────────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

printf 'Downloading pattern-surgeon...\n'
if command -v curl >/dev/null; then
  curl -fsSL "$ARCHIVE" -o "$TMP/archive.tar.gz"
else
  wget -qO "$TMP/archive.tar.gz" "$ARCHIVE"
fi

tar -xzf "$TMP/archive.tar.gz" -C "$TMP" --strip-components=1

# ── install ───────────────────────────────────────────────────────────────
SRC="$TMP/skills/${SKILL_NAME}"
[ -d "$SRC" ] || err "Skill source not found in archive. Check $REPO for the correct structure."

mkdir -p "$(dirname "$TARGET")"
rm -rf "$TARGET"
cp -r "$SRC" "$TARGET"

SCOPE="global"
[ "$PROJECT" -eq 1 ] && SCOPE="project"

printf '\n%s %s installed (%s)\n' "$(green '✓')" "$(bold 'pattern-surgeon')" "$SCOPE"
printf '  %s %s\n\n' "$(dim '→')" "$TARGET"
printf '%s open Claude Code and say:\n' "$(bold 'Use it:')"
printf '  %s\n' "$(cyan '"What pattern fits src/checkout.ts?"')"
printf '  %s\n' "$(cyan '"Refactor this pricing logic"')"
printf '  %s\n\n' "$(cyan '"Compare Strategy vs Factory for services/OrderService.kt"')"
if [ "$PROJECT" -eq 1 ]; then
  printf '%s Add .claude/ to git to share with your team:\n' "$(bold 'Tip:')"
  printf '  git add .claude/skills/%s\n\n' "$SKILL_NAME"
fi
