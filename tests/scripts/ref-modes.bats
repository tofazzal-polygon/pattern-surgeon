ROOT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references"

@test "comparison-rubric.md has the five scoring axes" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  for axis in "smell-match strength" "change locality" "reversibility" \
              "framework-idiom conflict" "added-indirection cost"; do
    grep -qF "$axis" "$f" || { echo "MISSING axis: $axis"; false; }
  done
}

@test "comparison-rubric.md has verdict scale" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qF "strong fit" "$f"
  grep -qF "partial" "$f"
  grep -qF "wrong tool here" "$f"
}

@test "comparison-rubric.md has tie-break order" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qF "Tie-break order" "$f"
}

@test "comparison-rubric.md has a worked Strategy-vs-Factory example" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qF "Worked example" "$f"
  grep -qF "Strategy" "$f"
  grep -qF "Factory" "$f"
}

@test "greenfield-tdd.md has per-language test runners including mobile" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  for r in pytest JUnit xUnit PHPUnit vitest XCTest "kotlin.test" "dart test"; do
    grep -qF "$r" "$f" || { echo "MISSING runner: $r"; false; }
  done
}

@test "greenfield-tdd.md states the exit-3 gate and reroute rule" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  grep -qF "exit 3" "$f"
  grep -qF "exit 0" "$f"
  grep -qF "exit 4" "$f"
  grep -qF "reroute to refactor" "$f"
  grep -qF "safety-harness.md" "$f"
}

@test "comparison-rubric.md defines the no-strong-fit recommendation" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qF "No \`strong fit\`" "$f"
  grep -qF "highest-scoring \`partial\`" "$f"
  grep -qF "All \`wrong tool here\`" "$f"
}

@test "comparison-rubric.md tie-break applies to the recommended tier" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qF "recommended tier" "$f"
}

@test "greenfield-tdd.md post-impl exit 2/3/4 maps to rollback.sh, never recommend-only" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  # collapse wrapping so the post-impl sentence is one string
  flat="$(tr -s '[:space:]' ' ' < "$f")"
  # post-impl exit 2,3,or 4 must lead to rollback.sh in the same sentence
  echo "$flat" | grep -qE 'Post-implementation exit 2, 3, or 4 [^.]*rollback\.sh' \
    || { echo "post-impl 2/3/4 not tied to rollback.sh"; false; }
  # the intent-guard clarifier must remain (post-impl exit 4 is NOT recommend-only)
  grep -qF "Exit 4 here is never acceptable" "$f"
  # pre-impl exit 4 -> recommend-only must still exist (step 4 unchanged)
  grep -qF "abort to recommend-only" "$f"
}

@test "comparison-rubric.md verdict is resolved by explicit first-match ordering" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  grep -qiF "first match wins" "$f"
  # the three tiers must appear as a numbered list in this exact sequence
  l1=$(grep -nE '^1\. `wrong tool here`' "$f" | head -1 | cut -d: -f1)
  l2=$(grep -nE '^2\. `strong fit`'      "$f" | head -1 | cut -d: -f1)
  l3=$(grep -nE '^3\. `partial`'         "$f" | head -1 | cut -d: -f1)
  [ -n "$l1" ] && [ -n "$l2" ] && [ -n "$l3" ] || { echo "tier numbering missing"; false; }
  [ "$l1" -lt "$l2" ] && [ "$l2" -lt "$l3" ] || { echo "tiers out of first-match order"; false; }
  # ties are broken within the recommended tier (ordering-based, not predicate-exclusive)
  grep -qF "recommended tier" "$f"
}
