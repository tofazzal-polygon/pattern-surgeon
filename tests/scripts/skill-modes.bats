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
