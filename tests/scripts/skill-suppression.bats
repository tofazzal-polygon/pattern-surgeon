FIX="$BATS_TEST_DIRNAME/../fixtures"

# ── Strategy suppression ────────────────────────────────────────────────────

@test "strategy-suppress fixture: only 2 cases present (< 3 threshold)" {
  f="$FIX/strategy-suppress-ts/src/pricing.ts"
  [ -f "$f" ]
  # Count unique branch-value strings (regular, vip) — must be exactly 2
  cases=$(grep -oE '"(regular|vip|staff|gold|bronze|silver|platinum)"' "$f" | sort -u | wc -l)
  [ "$cases" -eq 2 ]
}

@test "strategy-suppress fixture: README documents the when-NOT condition" {
  f="$FIX/strategy-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "fewer than 3 cases" "$f"
  grep -qiF "Suppression fixture" "$f"
  grep -qiF "suppress" "$f"
}

@test "strategy-suppress fixture: README states expected skill output (suppression)" {
  f="$FIX/strategy-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "Suppressed" "$f"
  grep -qiF "no code change" "$f"
}

# ── Factory suppression ─────────────────────────────────────────────────────

@test "factory-suppress fixture: single construction site, no conditional" {
  f="$FIX/factory-suppress-ts/src/conn.ts"
  [ -f "$f" ]
  # new PgConn(...) appears exactly once as actual code (exclude comment lines)
  count=$(grep -v '^\s*//' "$f" | grep -c 'new PgConn')
  [ "$count" -eq 1 ]
  # no if/switch over a driver config
  ! grep -qE '(if|switch).*driver' "$f"
}

@test "factory-suppress fixture: README documents the when-NOT condition" {
  f="$FIX/factory-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "trivial single construction" "$f"
  grep -qiF "Suppression fixture" "$f"
  grep -qiF "suppress" "$f"
}

@test "factory-suppress fixture: README states expected skill output (suppression)" {
  f="$FIX/factory-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "Suppressed" "$f"
  grep -qiF "no code change" "$f"
}

# ── Observer suppression ────────────────────────────────────────────────────

@test "observer-suppress fixture: single notify target" {
  f="$FIX/observer-suppress-ts/src/order.ts"
  [ -f "$f" ]
  # Only one .send( / notify( call in complete()
  notify_calls=$(grep -cE '\.(send|notify|track|release|emit)\(' "$f")
  [ "$notify_calls" -eq 1 ]
}

@test "observer-suppress fixture: README documents the when-NOT condition" {
  f="$FIX/observer-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "single listener" "$f"
  grep -qiF "Suppression fixture" "$f"
  grep -qiF "suppress" "$f"
}

@test "observer-suppress fixture: README states expected skill output (suppression)" {
  f="$FIX/observer-suppress-ts/README.md"
  [ -f "$f" ]
  grep -qiF "Suppressed" "$f"
  grep -qiF "no code change" "$f"
}

# ── Cross-cutting: every suppress fixture has a README with key fields ───────

@test "all suppress fixtures have README.md with Suppression fixture header" {
  for d in strategy-suppress-ts factory-suppress-ts observer-suppress-ts; do
    f="$FIX/$d/README.md"
    [ -f "$f" ] || { echo "MISSING README in $d"; false; }
    grep -qiF "Suppression fixture" "$f" || { echo "Missing 'Suppression fixture' in $d/README.md"; false; }
  done
}

@test "SKILL.md Detection rules document all three tested suppress conditions" {
  skill="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/SKILL.md"
  grep -qF '<3 cases' "$skill"
  grep -qF 'trivial single construction' "$skill"
  grep -qF 'single listener' "$skill"
}
