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

@test "greenfield-tdd.md has per-language test runners" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  for r in pytest JUnit xUnit PHPUnit vitest; do
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

@test "greenfield-tdd.md handles post-impl exit 4 as rollback" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  grep -qF "post-implementation" "$f"
  grep -qF "exit 2, 3, or 4" "$f"
}
