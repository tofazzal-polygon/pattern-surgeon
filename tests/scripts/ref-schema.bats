ROOT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references/patterns"
# NOTE: a literal triple-backtick in a bats test body breaks the bats 1.13
# source parser (test silently not collected). Build the fence in a variable;
# the grep assertions below are equivalent to: grep -qF '```'"$tag".
@test "every pattern ref has ts/python/java/csharp/php/kotlin/dart/swift fences and Framework idiom" {
  fence='```'
  for f in "$ROOT"/*.md; do
    for tag in ts python java csharp php kotlin dart swift; do
      grep -qF "$fence$tag" "$f" || { echo "MISSING ${fence}${tag} in $f"; false; }
    done
    grep -qF '## Framework idiom' "$f" || { echo "MISSING Framework idiom in $f"; false; }
  done
}

@test "no language stub remains in any pattern ref" {
  ! grep -rq 'TODO(phase-' "$ROOT"
}
