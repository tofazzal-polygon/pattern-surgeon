SCRIPT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
setup() { TMP="$(mktemp -d)"; cd "$TMP"; }
teardown() { rm -rf "$TMP"; }

@test "router: python project with passing pytest exits 0" {
  command -v python3 >/dev/null || skip "python3 absent"
  python3 -m pytest --version >/dev/null 2>&1 || skip "pytest absent"
  printf '[project]\nname="x"\nversion="0"\n' > pyproject.toml
  printf 'def add(a,b):\n    return a+b\n' > impl.py
  printf 'from impl import add\ndef test_add():\n    assert add(1,2)==3\n' > test_impl.py
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "router: python failing test exits 3" {
  command -v python3 >/dev/null || skip "python3 absent"
  python3 -m pytest --version >/dev/null 2>&1 || skip "pytest absent"
  printf '[project]\nname="x"\nversion="0"\n' > pyproject.toml
  printf 'def test_bad():\n    assert 1==2\n' > test_bad.py
  run bash "$SCRIPT"
  [ "$status" -eq 3 ]
}

@test "router: no recognizable project and no test exits 4" {
  echo "hi" > readme.txt
  run bash "$SCRIPT"
  [ "$status" -eq 4 ]
}

@test "router: TS path still works (regression)" {
  command -v node >/dev/null || skip "node absent"
  cat > package.json <<'EOF'
{ "name":"fx","scripts":{"test":"node -e \"process.exit(0)\""} }
EOF
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "router: python project + pytest installed but no tests exits 4" {
  command -v python3 >/dev/null || skip "python3 absent"
  python3 -m pytest --version >/dev/null 2>&1 || skip "pytest absent"
  printf '[project]\nname="x"\nversion="0"\n' > pyproject.toml
  printf 'def add(a,b):\n    return a+b\n' > impl.py
  run bash "$SCRIPT"
  [ "$status" -eq 4 ]
}
