SCRIPT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
setup() {
  TMP="$(mktemp -d)"; cd "$TMP"
  cat > package.json <<'EOF'
{ "name": "fx", "scripts": { "test": "node -e \"process.exit(0)\"" },
  "devDependencies": { "typescript": "*" } }
EOF
  echo "export const x: number = 1;" > index.ts
  cat > tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true, "noEmit": true } }
EOF
  npm install --silent --no-audit --no-fund typescript@5 >/dev/null 2>&1
}
teardown() { rm -rf "$TMP"; }

@test "verify passes when typecheck and tests are green" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "verify fails when typecheck is red" {
  echo "export const x: number = 'no';" > index.ts
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "verify fails when test script is red" {
  echo "export const x: number = 1;" > index.ts
  node -e "let p=require('./package.json');p.scripts.test='node -e \"process.exit(1)\"';require('fs').writeFileSync('package.json',JSON.stringify(p))"
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}
