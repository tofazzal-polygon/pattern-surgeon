# pattern-surgeon Multi-Language Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `pattern-surgeon` from TS/JS only to polyglot, framework-aware (Python, Java/Spring Boot, C#/.NET Core, PHP/Laravel) while preserving the verify-or-revert exit contract and the green TS path.

**Architecture:** `verify.sh` becomes a project-marker router (exit `0/2/3/4` unchanged). The 6 pattern references gain per-language code fences + a `## Framework idiom` subsection. SKILL.md gains a language+framework detection step. Work is phased: core → Python → Java/Spring → C#/.NET → PHP/Laravel, each independently shippable, with a regression gate that keeps the existing TS bats (8/8) and 12 TS fixtures green.

**Tech Stack:** Bash + bats-core; Node/TS (existing); Python (pytest, optional mypy); Java (Maven/Gradle, JUnit); C# (dotnet, xUnit); PHP (composer, PHPUnit, Laravel artisan). Toolchains optional on host — bats must skip-with-message, never silent-pass.

**Branch:** `feat/pattern-surgeon-multilang` (already created off `feat/pattern-surgeon-impl`, spec committed).

---

## File Structure

```
skills/pattern-surgeon/
  scripts/verify.sh                 MODIFY → marker router (ts|python|maven|gradle|dotnet|composer)
  SKILL.md                          MODIFY → add "Language & framework detection" step + framework when-NOT
  references/patterns/*.md (6)      MODIFY → add ts/python/java/csharp/php fences + "## Framework idiom"
tests/
  scripts/verify-router.bats        CREATE → per-marker exit-contract tests (toolchain-gated skips)
  fixtures/
    py-<pattern>-pos|neg/ (12)      CREATE (Phase 1)
    baseline-red-py/                CREATE (Phase 1)
    java-<pattern>-pos|neg/, spring-di-pos/, baseline-red-java/   CREATE (Phase 2)
    cs-<pattern>-pos|neg/, baseline-red-cs/                       CREATE (Phase 3)
    php-<pattern>-pos|neg/, laravel-repo-pos/, baseline-red-php/  CREATE (Phase 4)
  eval/run-eval.sh                  MODIFY → enumerate language fixtures
docs/MARKETING.md                   CREATE (Marketing task)
```

Helper used by all language fixtures: each fixture is a minimal project with a
behavioral test runnable by that ecosystem; `impl.<ext>` holds runnable code,
`src.<ext>` the typed mirror where the language separates them (TS/Java/C# the
same file compiles; Python/PHP single file).

---

## PHASE 0 — CORE ROUTER & SCHEMA

### Task 1: verify.sh marker router

**Files:**
- Modify: `skills/pattern-surgeon/scripts/verify.sh`
- Test: `tests/scripts/verify-router.bats`

- [ ] **Step 1: Write the failing test**

```bash
# tests/scripts/verify-router.bats
SCRIPT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
setup() { TMP="$(mktemp -d)"; cd "$TMP"; }
teardown() { rm -rf "$TMP"; }

@test "router: python project with passing pytest exits 0" {
  command -v python3 >/dev/null || skip "python3 absent"
  command -v pytest  >/dev/null || python3 -m pip show pytest >/dev/null 2>&1 || skip "pytest absent"
  printf '[project]\nname="x"\n' > pyproject.toml
  printf 'def add(a,b):\n    return a+b\n' > impl.py
  printf 'from impl import add\ndef test_add():\n    assert add(1,2)==3\n' > test_impl.py
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "router: python failing test exits 3" {
  command -v python3 >/dev/null || skip "python3 absent"
  python3 -m pytest --version >/dev/null 2>&1 || skip "pytest absent"
  printf '[project]\nname="x"\n' > pyproject.toml
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/verify-router.bats`
Expected: FAIL (current verify.sh only knows npm; python/exit-4/regression cases fail)

- [ ] **Step 3: Write minimal implementation (full replacement of verify.sh)**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Extensibility: add another language by adding a marker branch below that sets
# TYPECHECK and TEST; the exit-code contract (0 ok / 2 typecheck / 3 tests /
# 4 no test) and SKILL.md detection rules stay unchanged.

TYPECHECK=""   # command string or "" to skip typecheck
TEST=""        # command string; empty => exit 4 (no test)
STACK="unknown"

have() { command -v "$1" >/dev/null 2>&1; }

if [ -f package.json ]; then
  STACK="node"
  if [ -f pnpm-lock.yaml ]; then PM=pnpm; elif [ -f yarn.lock ]; then PM=yarn; else PM=npm; fi
  [ -f tsconfig.json ] && TYPECHECK="$( [ "$PM" = npm ] && echo 'npx --no-install tsc --noEmit' || echo "$PM exec tsc --noEmit")"
  node -e "process.exit(require('./package.json').scripts?.test?0:1)" 2>/dev/null && TEST="$PM test" || TEST=""
elif [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
  STACK="python"
  if [ -f mypy.ini ] || grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; then have mypy && TYPECHECK="mypy ."; fi
  if python3 -m pytest --version >/dev/null 2>&1; then TEST="python3 -m pytest -q"; else TEST=""; fi
elif [ -f pom.xml ]; then
  STACK="maven"; TYPECHECK="mvn -q compile"; TEST="mvn -q test"
elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  STACK="gradle"; TYPECHECK="./gradlew -q compileJava"; TEST="./gradlew -q test"
  [ -x ./gradlew ] || { TYPECHECK="gradle -q compileJava"; TEST="gradle -q test"; }
elif ls ./*.sln ./*.csproj >/dev/null 2>&1; then
  STACK="dotnet"; TYPECHECK="dotnet build -clp:ErrorsOnly"; TEST="dotnet test --nologo"
elif [ -f composer.json ]; then
  STACK="composer"
  { [ -f vendor/bin/phpstan ] && TYPECHECK="vendor/bin/phpstan analyse --no-progress"; } || true
  if [ -f artisan ]; then TEST="php artisan test"
  elif [ -f vendor/bin/phpunit ]; then TEST="vendor/bin/phpunit"
  else TEST=""; fi
fi

echo "pattern-surgeon: detected stack=$STACK"

if [ -n "$TYPECHECK" ]; then
  eval "$TYPECHECK" || { echo "pattern-surgeon: typecheck FAILED" >&2; exit 2; }
fi
if [ -z "$TEST" ]; then
  echo "pattern-surgeon: no test runner/target found" >&2; exit 4
fi
eval "$TEST" || { echo "pattern-surgeon: tests FAILED" >&2; exit 3; }
echo "pattern-surgeon: verify OK"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/verify-router.bats tests/scripts/verify.bats`
Expected: verify-router PASS (toolchain-absent cases skip, not fail); existing `verify.bats` 4/4 still PASS (TS regression).

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/scripts/verify.sh tests/scripts/verify-router.bats
git commit -m "feat(pattern-surgeon): verify.sh marker router (ts/python/maven/gradle/dotnet/composer)"
```

### Task 2: Reference schema multi-language upgrade (stubs)

**Files:**
- Modify: `skills/pattern-surgeon/references/patterns/{strategy,factory,adapter,repository,observer,dependency-injection}.md`

- [ ] **Step 1: Write the failing schema test**

```bash
# tests/scripts/ref-schema.bats
# NOTE: a literal triple-backtick inside a bats 1.13 test body breaks bats's
# source preprocessor and makes it collect 0 tests (1..0 = silent false green).
# Build the fence in a variable instead — semantically identical.
ROOT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references/patterns"
@test "every pattern ref has ts/python/java/csharp/php fences and Framework idiom" {
  fence='```'
  for f in "$ROOT"/*.md; do
    for tag in ts python java csharp php; do
      grep -qF "$fence$tag" "$f" || { echo "MISSING ${fence}$tag in $f"; false; }
    done
    grep -qF '## Framework idiom' "$f" || { echo "MISSING Framework idiom in $f"; false; }
  done
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/ref-schema.bats`
Expected: FAIL (only ```ts present today)

- [ ] **Step 3: Implement — add to EACH of the 6 files**

After the existing `## Transform recipe` section add:

```markdown
## Framework idiom
- Spring Boot: <pattern-specific note or "no framework-specific idiom; use the language recipe">
- .NET Core: <note or none>
- Laravel: <note or none>
```

And inside `## Transform recipe` (or `## Before / After`) add four fenced blocks below the existing ```ts block:

````markdown
```python
# TODO(phase-1): python example
```
```java
// TODO(phase-2): java example
```
```csharp
// TODO(phase-3): csharp example
```
```php
// TODO(phase-4): php example
```
````

(The `## Framework idiom` content is real now where known — DI/Repository/Factory — and "no framework-specific idiom" for the rest. Only the per-language CODE is stubbed; each stub is replaced in its phase. Final phase asserts no `TODO(phase-` remains.)

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/ref-schema.bats`
Expected: PASS (all 5 fences + Framework idiom present in 6 files)

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/references/patterns tests/scripts/ref-schema.bats
git commit -m "feat(pattern-surgeon): multi-language ref schema + Framework idiom (stubs)"
```

### Task 3: SKILL.md language + framework detection step

**Files:**
- Modify: `skills/pattern-surgeon/SKILL.md`

- [ ] **Step 1: Manual check (doc change — assertion is grep-based)**

Define expected: a new `## Language & framework detection` section before `## Procedure`, and a framework when-NOT line.

- [ ] **Step 2: Verify current absence**

Run: `grep -c 'Language & framework detection' skills/pattern-surgeon/SKILL.md`
Expected: `0`

- [ ] **Step 3: Implement — insert before `## Procedure`**

```markdown
## Language & framework detection
Before applying the procedure, detect the project:
- Language by nearest marker to the edited file: `package.json`+`tsconfig`→TS;
  `pyproject.toml`/`setup.py`/`requirements.txt`→Python; `pom.xml`/`build.gradle`→Java;
  `*.csproj`/`*.sln`→C#; `composer.json`→PHP.
- Framework: Spring Boot (`spring-boot` dep in pom/gradle); Laravel (`artisan`
  file + `laravel/framework` in composer.json); .NET (`Microsoft.AspNetCore`
  or `Microsoft.Extensions.DependencyInjection` in csproj).
- Use the matching language code block and the `## Framework idiom` note in the
  pattern reference. When a framework owns the machinery, prefer its idiom.

Framework when-NOT (suppress hand-rolled machinery):
- Spring / .NET app → do NOT hand-roll a DI container or Factory the framework
  provides; recommend the framework idiom, otherwise suppress.
- Laravel → data access belongs in Eloquent/repository per Laravel convention;
  don't introduce a foreign data layer.
```

- [ ] **Step 4: Verify**

Run: `grep -c 'Language & framework detection' skills/pattern-surgeon/SKILL.md && grep -c '^## ' skills/pattern-surgeon/SKILL.md`
Expected: `1` then `6` (was 5; +1 new section)

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/SKILL.md
git commit -m "feat(pattern-surgeon): SKILL.md language+framework detection step"
```

### Task 4: Eval harness language-aware

**Files:**
- Modify: `tests/eval/run-eval.sh`

- [ ] **Step 1: Failing expectation**

Define: run-eval enumerates `tests/fixtures/*-pos` AND `tests/fixtures/*/` language fixtures generically (glob already does); add a header line per detected stack note. Minimal change: print stack hint.

- [ ] **Step 2: Verify current output lacks language note**

Run: `bash tests/eval/run-eval.sh | grep -c 'stack:'`
Expected: `0`

- [ ] **Step 3: Implement — replace the POS loop body**

```bash
for d in tests/fixtures/*-pos; do
  echo "POS  $d (stack: $(ls "$d" | grep -qE 'pom.xml|build.gradle' && echo java || ls "$d" | grep -q '.csproj' && echo dotnet || [ -f "$d/composer.json" ] && echo php || [ -f "$d/pyproject.toml" ] && echo python || echo node)) : run pattern-surgeon on the smelly file, then:"
  echo "     bash skills/pattern-surgeon/scripts/verify.sh  # expect exit 0"
done
```

- [ ] **Step 4: Verify**

Run: `bash tests/eval/run-eval.sh | grep -c 'stack:'`
Expected: ≥ 6 (one per existing pos fixture; non-zero)

- [ ] **Step 5: Commit**

```bash
git add tests/eval/run-eval.sh
git commit -m "feat(pattern-surgeon): language-aware eval harness"
```

---

## PHASE 1 — PYTHON

### Task 5: Python pattern reference blocks

**Files:**
- Modify: the 6 `references/patterns/*.md` (replace `# TODO(phase-1): python example`)

- [ ] **Step 1: Define expectation**

Each file's `python` fence holds a correct, idiomatic Python example mirroring that file's existing TS example semantics.

- [ ] **Step 2: Verify stubs present**

Run: `grep -rl 'TODO(phase-1)' skills/pattern-surgeon/references/patterns | wc -l`
Expected: `6`

- [ ] **Step 3: Implement — replace each python stub with real code**

strategy.md python fence (template; apply the analogous transform per pattern):

```python
from typing import Protocol

class PricingStrategy(Protocol):
    def price(self, base: float) -> float: ...

class Regular: 
    def price(self, base): return base
class Vip:
    def price(self, base): return base * 0.8
class Staff:
    def price(self, base): return base * 0.5

STRATEGIES = {"regular": Regular(), "vip": Vip(), "staff": Staff()}
def price(kind: str, base: float) -> float:
    return STRATEGIES[kind].price(base)
```

For factory: a `create_conn(cfg)` returning a `Protocol` impl chosen by
`cfg["driver"]`. adapter: a domain `PaymentPort` Protocol with a `StripeAdapter`
wrapping a fake `vendor_charge`. repository: `UserRepository` Protocol +
in-memory impl, service depends on the Protocol. observer: a `Subject` with
`subscribe`/`notify`. dependency-injection: constructor-injected collaborator
typed by Protocol vs `self.db = Db()`. Each must be runnable Python 3 and match
the pattern's `## Verification focus`.

- [ ] **Step 4: Verify**

Run: `! grep -rq 'TODO(phase-1)' skills/pattern-surgeon/references/patterns && bats tests/scripts/ref-schema.bats`
Expected: no phase-1 stub remains; schema bats PASS

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/references/patterns
git commit -m "feat(pattern-surgeon): Python pattern reference blocks"
```

### Task 6: Python fixtures (6 pos + 6 neg + baseline-red-py)

**Files:**
- Create: `tests/fixtures/py-{strategy,factory,adapter,repository,observer,dependency-injection}-{pos,neg}/`
- Create: `tests/fixtures/baseline-red-py/`
- Modify: `tests/fixtures/.gitignore` (add `__pycache__/`, `.venv/`, `*.pyc`)

- [ ] **Step 1: Write a positive fixture as the template (py-strategy-pos)**

`pyproject.toml`:
```toml
[project]
name = "py-strategy-pos"
version = "0"
```
`impl.py` — contains the smell (≥3-branch `if kind ==` pricing).
`test_impl.py`:
```python
from impl import price
def test_prices():
    assert price("regular",100)==100
    assert price("vip",100)==80
    assert price("staff",100)==50
```

- [ ] **Step 2: Verify it runs**

Run: `cd tests/fixtures/py-strategy-pos && python3 -m pytest -q; echo exit=$?`
Expected: `exit=0` (skip this task only if python3/pytest absent — note it)

- [ ] **Step 3: Create remaining 5 pos + 6 neg + baseline-red-py**

pos: each `impl.py` exhibits that pattern's smell, `test_impl.py` asserts
observable behavior surviving the refactor. neg: matches the pattern's
"When NOT to apply" (e.g. py-strategy-neg: single 2-branch toggle, one site)
with a passing test. baseline-red-py: `pyproject.toml` with no test deps, a
`impl.py` containing a real error (`x: int = "no"` plus a `mypy.ini` so the
typecheck path is exercised) and NO `test_*.py`.

- [ ] **Step 4: Verify all**

Run: `for d in tests/fixtures/py-*-pos tests/fixtures/py-*-neg; do (cd "$d" && python3 -m pytest -q >/dev/null 2>&1 && echo "$d ok" || echo "$d FAIL"); done`
Expected: all `ok` (12). baseline-red-py: confirm no `test_*.py` and an error present.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures
git commit -m "test(pattern-surgeon): Python pos/neg/baseline fixtures"
```

### Task 7: Python E2E + regression gate

**Files:** none (verification task)

- [ ] **Step 1: E2E dry run (py-strategy-pos)**

Act as the skill: detect python, probe `bash skills/pattern-surgeon/scripts/verify.sh` in the fixture (expect 0), back up impl.py, apply Strategy per the python reference block, re-run verify (expect 0), then REVERT impl.py (fixture stays pristine), confirm pytest still green.

- [ ] **Step 2: Negative + legacy**

py-strategy-neg → skill must refuse (when-NOT). baseline-red-py → verify.sh exits 4 (no test) or 2 (mypy error) → SKILL legacy recommend-only, no edits.

- [ ] **Step 3: TS regression gate**

Run: `bats tests/scripts/checkpoint.bats tests/scripts/verify.bats tests/scripts/rollback.bats tests/scripts/verify-router.bats tests/scripts/ref-schema.bats && for d in tests/fixtures/strategy-pos tests/fixtures/*-neg; do (cd "$d" && node test.js >/dev/null 2>&1 && echo "$d ok" || echo "$d FAIL"); done`
Expected: all bats green; TS fixtures still `ok`.

- [ ] **Step 4: Commit (gate marker)**

```bash
git commit --allow-empty -m "test(pattern-surgeon): Phase 1 Python E2E + TS regression green"
```

---

## PHASE 2 — JAVA + SPRING BOOT

### Task 8: Java reference blocks + Spring Framework idiom

**Files:** Modify the 6 `references/patterns/*.md` (replace `// TODO(phase-2): java example`; fill Spring lines in `## Framework idiom`).

- [ ] **Step 1: Verify stubs**

Run: `grep -rl 'TODO(phase-2)' skills/pattern-surgeon/references/patterns | wc -l`
Expected: `6`

- [ ] **Step 2: Replace each java stub with idiomatic Java**

strategy.md java fence:
```java
interface PricingStrategy { double price(double base); }
class Regular implements PricingStrategy { public double price(double b){return b;} }
class Vip implements PricingStrategy { public double price(double b){return b*0.8;} }
class Staff implements PricingStrategy { public double price(double b){return b*0.5;} }
Map<String,PricingStrategy> S = Map.of("regular",new Regular(),"vip",new Vip(),"staff",new Staff());
double price(String k,double base){ return S.get(k).price(base); }
```
Other patterns analogous. In `## Framework idiom` set the Spring Boot line per
pattern: DI → "constructor injection with `@Component`/`@Service`; let the
container wire — do not `new` collaborators"; Repository → "extend Spring Data
`JpaRepository<T,ID>`; do not hand-roll DAO"; Factory → "`@Bean` methods in a
`@Configuration` class"; Strategy/Adapter/Observer → "no Spring-specific idiom;
beans may hold the strategy map / `ApplicationEventPublisher` for Observer".

- [ ] **Step 3: Verify**

Run: `! grep -rq 'TODO(phase-2)' skills/pattern-surgeon/references/patterns && bats tests/scripts/ref-schema.bats`
Expected: no phase-2 stub; schema PASS

- [ ] **Step 4: Commit**

```bash
git add skills/pattern-surgeon/references/patterns
git commit -m "feat(pattern-surgeon): Java blocks + Spring framework idiom"
```

### Task 9: Java/Spring fixtures + verify branch + E2E

**Files:** Create `tests/fixtures/java-strategy-pos|neg/` (Maven), `tests/fixtures/java-repository-pos/` (Gradle), `tests/fixtures/spring-di-pos/`, `tests/fixtures/baseline-red-java/`; modify `.gitignore` (`target/`, `build/`, `.gradle/`).

- [ ] **Step 1: Maven fixture template (java-strategy-pos)**

`pom.xml` minimal with JUnit 5; `src/main/java/App.java` with the smell;
`src/test/java/AppTest.java` asserting `price` outputs.

- [ ] **Step 2: Verify (toolchain-gated)**

Run: `command -v mvn >/dev/null && (cd tests/fixtures/java-strategy-pos && mvn -q test; echo exit=$?) || echo "SKIP: mvn absent"`
Expected: `exit=0` or explicit SKIP (record which; never silent pass).

- [ ] **Step 3: Create neg, Gradle repo fixture, spring-di-pos (Spring Boot starter, a service that `new`s its dep — the smell; test via `@SpringBootTest` or plain JUnit), baseline-red-java (no test dir + a `javac` type error).**

- [ ] **Step 4: Verify branch + E2E**

Run router bats Java cases (skip if mvn/gradle absent). E2E: detect java+spring on spring-di-pos, recommend constructor injection idiom, apply, verify (0), revert. neg refuses. baseline-red-java → exit 2/4 → recommend-only.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures
git commit -m "test(pattern-surgeon): Java/Spring fixtures + Phase 2 E2E"
```

---

## PHASE 3 — C# / .NET CORE

### Task 10: C# blocks + .NET idiom + fixtures + E2E

**Files:** Modify 6 refs (replace `// TODO(phase-3): csharp example`, fill .NET `## Framework idiom`); Create `tests/fixtures/cs-strategy-pos|neg/`, `cs-di-pos/`, `baseline-red-cs/`; `.gitignore` (`bin/`,`obj/`).

- [ ] **Step 1: Verify stubs**

Run: `grep -rl 'TODO(phase-3)' skills/pattern-surgeon/references/patterns | wc -l` → `6`

- [ ] **Step 2: Replace csharp stubs (idiomatic C#)**

strategy.md csharp fence:
```csharp
interface IPricingStrategy { double Price(double b); }
class Regular: IPricingStrategy { public double Price(double b)=>b; }
class Vip: IPricingStrategy { public double Price(double b)=>b*0.8; }
class Staff: IPricingStrategy { public double Price(double b)=>b*0.5; }
static readonly Dictionary<string,IPricingStrategy> S = new(){["regular"]=new Regular(),["vip"]=new Vip(),["staff"]=new Staff()};
double Price(string k,double b)=>S[k].Price(b);
```
Others analogous. `## Framework idiom` .NET line: DI → "register in
`IServiceCollection` (`AddScoped/AddSingleton`), constructor-inject; do not
`new`"; Repository → "EF Core `DbContext`/`DbSet<T>` or a repository over it";
Factory → "`IServiceProvider`/typed factory delegate"; rest → "no .NET-specific
idiom".

- [ ] **Step 3: Fixtures**

`cs-strategy-pos`: a `.csproj` (net8.0) + xUnit test project (or single
`dotnet test` solution); `Program`/class with the smell; xUnit test asserting
`Price`. neg = when-NOT. `cs-di-pos`: class news its own dep. baseline-red-cs:
no test + a compile error.

- [ ] **Step 4: Verify (gated) + E2E + regression**

`command -v dotnet >/dev/null && (cd tests/fixtures/cs-strategy-pos && dotnet test --nologo; echo exit=$?) || echo "SKIP: dotnet absent"`. E2E on cs-di-pos → .NET DI idiom. Re-run all prior bats + TS + Python fixtures green.

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/references/patterns tests/fixtures
git commit -m "feat(pattern-surgeon): C#/.NET blocks, idiom, fixtures, Phase 3 E2E"
```

---

## PHASE 4 — PHP / LARAVEL

### Task 11: PHP blocks + Laravel idiom + fixtures + E2E

**Files:** Modify 6 refs (replace `// TODO(phase-4): php example`, fill Laravel `## Framework idiom`); Create `tests/fixtures/php-strategy-pos|neg/`, `laravel-repo-pos/`, `baseline-red-php/`; `.gitignore` (`vendor/`).

- [ ] **Step 1: Verify stubs**

Run: `grep -rl 'TODO(phase-4)' skills/pattern-surgeon/references/patterns | wc -l` → `6`

- [ ] **Step 2: Replace php stubs (idiomatic PHP 8)**

strategy.md php fence:
```php
interface PricingStrategy { public function price(float $b): float; }
final class Regular implements PricingStrategy { public function price(float $b): float { return $b; } }
final class Vip implements PricingStrategy { public function price(float $b): float { return $b*0.8; } }
final class Staff implements PricingStrategy { public function price(float $b): float { return $b*0.5; } }
$S = ['regular'=>new Regular(),'vip'=>new Vip(),'staff'=>new Staff()];
function price(array $S, string $k, float $b): float { return $S[$k]->price($b); }
```
Others analogous. `## Framework idiom` Laravel line: DI → "type-hint in
constructor; Laravel service container auto-resolves; bind interfaces in a
ServiceProvider"; Repository → "Eloquent model or a repository class bound in a
ServiceProvider; don't bypass Eloquent"; Factory → "container `make()` /
model factories"; rest → "no Laravel-specific idiom".

- [ ] **Step 3: Fixtures**

`php-strategy-pos`: `composer.json` with phpunit dev dep; `src.php` with the
smell; `tests/StrategyTest.php` asserting prices; run via
`vendor/bin/phpunit`. neg = when-NOT. `laravel-repo-pos`: minimal structure
with an `artisan` stub file + `laravel/framework` in composer.json and inline
DB access (the smell); test asserts behavior. baseline-red-php: composer.json,
no phpunit/artisan, `src.php` with a fatal/`phpstan` error.

- [ ] **Step 4: Verify (gated) + E2E + full regression**

`command -v php >/dev/null && composer --version >/dev/null 2>&1 && (cd tests/fixtures/php-strategy-pos && composer install -q && vendor/bin/phpunit; echo exit=$?) || echo "SKIP: php/composer absent"`. E2E on laravel-repo-pos → Eloquent/repository idiom. Re-run ALL bats + TS + Python + Java + C# fixture checks green. Assert `! grep -rq 'TODO(phase-' skills/pattern-surgeon/references` (no stub anywhere).

- [ ] **Step 5: Tighten schema check + commit**

Edit `tests/scripts/ref-schema.bats`: add `@test "no language stub remains" { ! grep -rq 'TODO(phase-' "$ROOT"; }`.
```bash
git add skills/pattern-surgeon/references/patterns tests/fixtures tests/scripts/ref-schema.bats
git commit -m "feat(pattern-surgeon): PHP/Laravel blocks, idiom, fixtures; forbid stubs"
```

---

## MARKETING

### Task 12: docs/MARKETING.md

**Files:** Create `docs/MARKETING.md`

- [ ] **Step 1: Define required sections**

Positioning, Target users, Differentiation table, Channels, Assets, Launch sequence, Metrics.

- [ ] **Step 2: Verify absence**

Run: `test ! -f docs/MARKETING.md && echo absent`
Expected: `absent`

- [ ] **Step 3: Write docs/MARKETING.md**

```markdown
# pattern-surgeon — Go-To-Market

## Positioning
The only open-source AI skill that *recommends, applies, and verifies* a design
pattern refactor — polyglot (TS, Python, Java/Spring, C#/.NET, PHP/Laravel),
framework-aware, auto-reverting on red. Fills the ecosystem's weakest niche:
existing skills only detect SOLID or describe patterns.

## Target users
Backend/full-stack devs and tech leads doing legacy modernization, code review
prep, and refactoring across mixed-language codebases.

## Differentiation
| | pattern-surgeon | SOLID-checker skills | refactor agents |
|---|---|---|---|
| Recommends a pattern | yes | partial | no |
| Applies + auto-reverts on test/typecheck fail | yes | no | rarely |
| Polyglot + framework-aware | yes | no | no |
| When-NOT suppression | yes | weak | no |

## Channels
obra superpowers-marketplace · VoltAgent awesome-agent-skills · ComposioHQ /
travisvn awesome lists · claudemarketplaces.com · buildwithclaude.com · Show HN
· r/programming, r/ExperiencedDevs · dev.to launch post · X/LinkedIn demo clip.

## Assets
README + asciinema cast · per-language before/after diff GIF · differentiation
table · one-line install · the spec/plan as proof of rigor.

## Launch sequence
1. Tag release. 2. Open marketplace PRs. 3. dev.to post + Show HN + Reddit same
day. 4. 1-week follow-up with adoption metrics + a real refactor case study.

## Metrics
Installs, marketplace stars, demo-GIF views, "applied & kept" vs "reverted"
ratio reported by users, issues filed per language.
```

- [ ] **Step 4: Verify**

Run: `grep -c '^## ' docs/MARKETING.md`
Expected: `7`

- [ ] **Step 5: Commit**

```bash
git add docs/MARKETING.md
git commit -m "docs(pattern-surgeon): go-to-market plan"
```

### Task 13: Final integration review + README + push

**Files:** Modify `README.md`

- [ ] **Step 1: Full regression**

Run: `bats tests/scripts/*.bats` (all green / toolchain-absent skip with message) and every available language fixture pos/neg.

- [ ] **Step 2: Stub guard**

Run: `! grep -rq 'TODO(phase-' skills/pattern-surgeon`
Expected: no output, exit 0.

- [ ] **Step 3: README languages section**

Append:
```markdown
## Languages
TS/JS · Python · Java (Spring Boot) · C# (.NET Core) · PHP (Laravel).
Verification auto-detects the stack; safety contract identical everywhere.
See `docs/MARKETING.md`.
```

- [ ] **Step 4: Commit + push branch**

```bash
git add README.md
git commit -m "docs(pattern-surgeon): document multi-language support"
git push origin feat/pattern-surgeon-multilang
```

---

## Self-Review

**Spec coverage:**
- Architecture delta → Tasks 1–4. ✓
- verify.sh router contract (table, skip-typecheck rule, exit 4, host-absent) → Task 1 (full router code + gated bats). ✓
- Reference + SKILL.md changes (per-lang fences, Framework idiom, detection step, framework when-NOT) → Tasks 2,3,5,8,10,11. ✓
- Phasing (0→Py→Java/Spring→.NET→PHP/Laravel, independently shippable, stub policy) → Phase sections + stub guard Tasks 2/5/8/10/11/13. ✓
- Fixtures (per-language pos/neg/baseline-red, gitignore artifacts) → Tasks 6,9,10,11. ✓
- Testing (gated skips, per-phase schema+behavioral+exit-contract+E2E, TS regression gate) → Tasks 1,7,9,10,11,13. ✓
- Marketing doc → Task 12. ✓
- Extensibility → Task 1 router comment + structure. ✓

**Placeholder scan:** The only `TODO(phase-N)` strings are an intentional, spec-defined stub mechanism with an explicit removal gate (Task 11 Step 5 forbids them; Task 13 Step 2 guards). Reference-block tasks give one concrete per-language template and instruct applying the same documented transform to the other 5 patterns — matching the accepted style of the original plan's Task 6; not a vague placeholder.

**Type/contract consistency:** Exit codes `0/2/3/4` identical across Task 1 router, existing `verify.bats`, SKILL.md, and safety-harness. Fence tags `ts/python/java/csharp/php` and `## Framework idiom` header identical in ref-schema bats (Task 2) and every fill task (5/8/10/11). Stub token `TODO(phase-N)` consistent between insert (Task 2) and guards (Tasks 11,13).
