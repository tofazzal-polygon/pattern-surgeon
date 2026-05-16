SCRIPT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/rollback.sh"
CP="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/checkpoint.sh"
setup() {
  TMP="$(mktemp -d)"; cd "$TMP"
  git init -q; git config user.email t@t; git config user.name t
  echo good > f.txt; git add .; git commit -qm init
  echo bad > f.txt
  SHA="$(bash "$CP")"
}
teardown() { rm -rf "$TMP"; }

@test "rollback restores checkpoint contents and prints rejected diff" {
  echo worse > f.txt
  run bash "$SCRIPT" "$SHA"
  [ "$status" -eq 0 ]
  [ "$(cat f.txt)" = "bad" ]
  [[ "$output" == *"REJECTED DIFF"* ]]
}

@test "rollback preserves unrelated pre-existing user stashes" {
  git stash push -q -m "user-work" f.txt 2>/dev/null || { echo nochange > g.txt; git add g.txt; git stash push -q -m "user-work"; }
  before="$(git stash list | grep -c user-work)"
  [ "$before" -eq 1 ]
  echo worse > f.txt
  run bash "$SCRIPT" "$SHA"
  [ "$status" -eq 0 ]
  after="$(git stash list | grep -c user-work || true)"
  [ "$after" -eq 1 ]
}
