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

@test "SKILL.md description front matter covers modes, web and mobile languages" {
  [ -f "$SKILL" ]
  hdr="$(sed -n '1,5p' "$SKILL")"
  echo "$hdr" | grep -qiF "compare"
  echo "$hdr" | grep -qiF "match existing"
  echo "$hdr" | grep -qiF "implement"
  echo "$hdr" | grep -qiF "Python"
  echo "$hdr" | grep -qiF "Java"
  echo "$hdr" | grep -qiF "C#"
  echo "$hdr" | grep -qiF "PHP"
  echo "$hdr" | grep -qiF "Kotlin"
  echo "$hdr" | grep -qiF "Dart"
  echo "$hdr" | grep -qiF "Swift"
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

@test "compare-ambiguous fixture genuinely meets Strategy and Factory thresholds" {
  d="$BATS_TEST_DIRNAME/../fixtures/compare-ambiguous-ts"
  f="$d/src.ts"
  [ -f "$f" ]
  [ -f "$d/README.md" ]
  # Strategy: same kind-switch at >=2 sites
  sw=$(grep -c 'switch (kind)' "$f")
  [ "$sw" -ge 2 ]
  # Factory: family construction (new *Notifier()) in >=3 places
  ctor=$(grep -cE 'new [A-Za-z]+Notifier\(\)' "$f")
  [ "$ctor" -ge 3 ]
  grep -qF "export" "$f"
  grep -qiF "Strategy" "$d/README.md"
  grep -qiF "Factory" "$d/README.md"
  grep -qiF "call sites" "$d/README.md"
}

@test "follow-repo fixture: convention + non-conforming target both in scope cap" {
  d="$BATS_TEST_DIRNAME/../fixtures/follow-repo-ts"
  [ -f "$d/repo/UserRepository.ts" ]
  [ -f "$d/repo/OrderRepository.ts" ]
  [ -f "$d/repo/InvoiceRepository.ts" ]
  [ ! -d "$d/services" ]
  grep -qF "fetch(" "$d/repo/UserRepository.ts"
  grep -qF "fetch(" "$d/repo/OrderRepository.ts"
  grep -qF "byId" "$d/repo/UserRepository.ts"
  ! grep -qF "byId" "$d/repo/InvoiceRepository.ts"
  grep -qiF "scope cap" "$d/README.md"
  grep -qiF "same directory" "$d/README.md"
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

@test "Intent routing maps each trigger phrase to its mode" {
  [ -f "$SKILL" ]
  grep -qE '\| `suggest` \|.*what pattern fits' "$SKILL"
  grep -qE '\| `refactor` \|.*(refactor|messy code|big switch)' "$SKILL"
  grep -qE '\| `compare` \|.*(compare patterns|which:|why this over that)' "$SKILL"
  grep -qE '\| `follow` \|.*(match existing patterns|make this consistent)' "$SKILL"
  grep -qE '\| `greenfield` \|.*implement .* with the right pattern' "$SKILL"
}

@test "Intent routing mandates ASK on ambiguity with no guess" {
  [ -f "$SKILL" ]
  grep -qiE 'ambiguous.*ASK' "$SKILL"
  grep -qiF "never guess" "$SKILL"
}

@test "SKILL.md has Lazy Loading Protocol with per-mode load table" {
  [ -f "$SKILL" ]
  grep -qF "## Lazy Loading Protocol" "$SKILL"
  grep -qF "Load on activation" "$SKILL"
  grep -qF "Load after detection" "$SKILL"
  # every mode must have a row in the lazy-load table
  for m in suggest refactor compare follow greenfield; do
    grep -qF "| \`$m\`" "$SKILL" || { echo "MISSING lazy-load row for $m"; false; }
  done
  grep -qiF "10 000 tokens" "$SKILL"
}

@test "SKILL.md follow mode has explicit scope algorithm with layer names and caps" {
  [ -f "$SKILL" ]
  grep -qF "Scope algorithm" "$SKILL"
  # key layer directory names
  for layer in services repositories adapters features domain; do
    grep -qF "$layer" "$SKILL" || { echo "MISSING layer name: $layer"; false; }
  done
  grep -qF "max 20 files" "$SKILL"
  grep -qiF "project root" "$SKILL"
}

@test "SKILL.md Procedure references lazy loading before reading pattern file" {
  [ -f "$SKILL" ]
  # Procedure must say to use inline table first (no file reads)
  grep -qiF "no pattern file reads yet" "$SKILL"
  # Then load pattern file after detection
  grep -qF "references/patterns/<matched>.md" "$SKILL"
}

@test "SKILL.md compare mode loads comparison-rubric and candidate patterns only" {
  [ -f "$SKILL" ]
  # compare section must reference lazy loading of candidate patterns
  grep -qF "references/comparison-rubric.md" "$SKILL"
  grep -qF "references/patterns/<candidate>.md" "$SKILL"
  grep -qiF "not all six" "$SKILL"
}

@test "greenfield exit-0 reroute path: impl present -> verify exits 0, reroute rule documented" {
  src="$BATS_TEST_DIRNAME/../fixtures/greenfield-ts"
  [ -f "$src/test.js" ]
  command -v node >/dev/null 2>&1 || skip "node not installed"
  tmp="$(mktemp -d)"
  cp "$src/package.json" "$src/test.js" "$tmp/"
  printf '%s\n' 'function notify(kind, msg){ if(kind==="email") console.log("email", msg); }' 'module.exports = { notify };' > "$tmp/impl.js"
  vs="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
  run bash -c "cd \"$tmp\" && bash \"$vs\""
  rm -rf "$tmp"
  [ "$status" -eq 0 ]
  grep -qF "reroute to" "$SKILL"
  grep -qF "reroute to refactor" "$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references/greenfield-tdd.md"
}
