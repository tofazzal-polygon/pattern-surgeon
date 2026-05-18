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

@test "router: dotnet project detected via .slnx" {
  printf '<Project Sdk="Microsoft.NET.Sdk"></Project>\n' > app.csproj
  : > app.slnx
  rm -f app.csproj   # only .slnx present, no .csproj/.sln
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=dotnet'
}

@test "router: Android/Kotlin project detected via AndroidManifest.xml" {
  mkdir -p app/src/main
  printf '<manifest package="com.example"/>\n' > app/src/main/AndroidManifest.xml
  : > build.gradle.kts
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=android-kotlin'
}

@test "router: Flutter project detected via pubspec.yaml with flutter dep" {
  printf 'name: my_app\ndependencies:\n  flutter:\n    sdk: flutter\n' > pubspec.yaml
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=flutter'
}

@test "router: Dart project detected via pubspec.yaml without flutter dep" {
  printf 'name: my_lib\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n' > pubspec.yaml
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=dart'
}

@test "router: Swift package detected via Package.swift" {
  printf '// swift-tools-version:5.9\nimport PackageDescription\nlet package = Package(name: "x", targets: [])\n' > Package.swift
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=swift'
}

@test "router: Android takes priority over generic gradle when AndroidManifest present" {
  mkdir -p app/src/main
  printf '<manifest package="com.example"/>\n' > app/src/main/AndroidManifest.xml
  printf 'plugins { id("com.android.application") }\n' > build.gradle.kts
  run bash "$SCRIPT"
  echo "$output" | grep -q 'detected stack=android-kotlin'
  echo "$output" | grep -qv 'detected stack=gradle'
}
