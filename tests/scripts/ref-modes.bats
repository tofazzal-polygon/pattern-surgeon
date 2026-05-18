ROOT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references"

@test "comparison-rubric.md has the five scoring axes" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  for axis in "smell-match strength" "change locality" "reversibility" \
              "framework-idiom conflict" "added-indirection cost"; do
    grep -qF "$axis" "$f" || { echo "MISSING axis: $axis"; false; }
  done
}

@test "comparison-rubric.md has verdict scale and tie-break order" {
  f="$ROOT/comparison-rubric.md"
  grep -qF "strong fit" "$f"
  grep -qF "partial" "$f"
  grep -qF "wrong tool here" "$f"
  grep -qF "Tie-break order" "$f"
}

@test "comparison-rubric.md has a worked Strategy-vs-Factory example" {
  f="$ROOT/comparison-rubric.md"
  grep -qF "Worked example" "$f"
  grep -qF "Strategy" "$f"
  grep -qF "Factory" "$f"
}
