SKILL="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/SKILL.md"

@test "SKILL.md has an Intent routing section with all five modes" {
  [ -f "$SKILL" ]
  grep -qF "## Intent routing" "$SKILL"
  for m in suggest refactor compare follow greenfield; do
    grep -qF "\`$m\`" "$SKILL" || { echo "MISSING mode: $m"; false; }
  done
  grep -qiF "ambiguous" "$SKILL"
  grep -qF "ASK" "$SKILL"
}

@test "SKILL.md description front matter covers new modes and languages" {
  [ -f "$SKILL" ]
  hdr="$(sed -n '1,5p' "$SKILL")"
  echo "$hdr" | grep -qiF "compare"
  echo "$hdr" | grep -qiF "match existing"
  echo "$hdr" | grep -qiF "implement"
  echo "$hdr" | grep -qiF "Python"
  echo "$hdr" | grep -qiF "Java"
  echo "$hdr" | grep -qiF "C#"
  echo "$hdr" | grep -qiF "PHP"
}

@test "SKILL.md has a Modes block with the three new procedures" {
  [ -f "$SKILL" ]
  grep -qF "## Modes" "$SKILL"
  grep -qF "### compare" "$SKILL"
  grep -qF "### follow" "$SKILL"
  grep -qF "### greenfield" "$SKILL"
  grep -qF "comparison-rubric.md" "$SKILL"
  grep -qF "greenfield-tdd.md" "$SKILL"
  grep -qF "sibling files" "$SKILL"
}

@test "SKILL.md Output contract covers compare and greenfield" {
  [ -f "$SKILL" ]
  grep -qF "matrix" "$SKILL"
  grep -qiF "failing test first" "$SKILL"
}

@test "compare-ambiguous fixture exists with the dual-smell scope" {
  d="$BATS_TEST_DIRNAME/../fixtures/compare-ambiguous-ts"
  [ -f "$d/src.ts" ]
  [ -f "$d/README.md" ]
  grep -qF "switch" "$d/src.ts"
  grep -qF "new " "$d/src.ts"
  grep -qF "export" "$d/src.ts"
  grep -qiF "Strategy" "$d/README.md"
  grep -qiF "Factory" "$d/README.md"
}

@test "follow-repo fixture has sibling convention plus a non-conforming file" {
  d="$BATS_TEST_DIRNAME/../fixtures/follow-repo-ts"
  [ -f "$d/repo/UserRepository.ts" ]
  [ -f "$d/repo/OrderRepository.ts" ]
  [ -f "$d/services/InvoiceService.ts" ]
  grep -qF "fetch(" "$d/services/InvoiceService.ts"
  grep -qF "fetch(" "$d/repo/UserRepository.ts"
  grep -qiF "Repository" "$d/README.md"
}

@test "greenfield fixture starts red (verify.sh exits 3, no impl yet)" {
  d="$BATS_TEST_DIRNAME/../fixtures/greenfield-ts"
  [ -f "$d/SPEC.md" ]
  [ -f "$d/test.js" ]
  command -v node >/dev/null 2>&1 || skip "node not installed"
  vs="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
  run bash -c "cd \"$d\" && bash \"$vs\""
  [ "$status" -eq 3 ]
}
