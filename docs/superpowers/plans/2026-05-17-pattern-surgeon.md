# pattern-surgeon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `pattern-surgeon` skill: a reactive TS/JS skill that recommends one of 6 design patterns for a user-named scope, applies the refactor, and keeps it only if a deterministic typecheck+test harness stays green.

**Architecture:** A SKILL.md "advisor brain" drives detection (6 smell signatures + when-NOT). The LLM performs the semantic transform; three bash scripts (`checkpoint`/`verify`/`rollback`) form a verify-or-revert harness using `git stash create`. Pattern knowledge lives in 6 fixed-schema reference files. Legacy/untested code triggers recommend-only mode.

**Tech Stack:** Bash (harness scripts), `bats-core` (script tests), Node + TypeScript + a test runner (fixture projects), Markdown (SKILL.md + references).

---

## File Structure

```
skills/pattern-surgeon/
  SKILL.md                          advisor brain
  references/
    safety-harness.md               verify-or-revert protocol
    patterns/
      strategy.md  factory.md  adapter.md
      repository.md  observer.md  dependency-injection.md
  scripts/
    checkpoint.sh                   git stash-create snapshot
    verify.sh                       pkg-mgr detect → tsc --noEmit → test script
    rollback.sh                     restore checkpoint + emit rejected diff
tests/
  scripts/
    checkpoint.bats  verify.bats  rollback.bats
  fixtures/
    strategy-pos/ strategy-neg/ ... (one pos + one neg per pattern)
    baseline-red/                   untested/red project (refusal fixture)
  eval/
    run-eval.sh                     drives skill against fixtures, asserts outcomes
README.md
```

Responsibilities: scripts = deterministic safety only (no pattern logic). SKILL.md = when/how to recommend + flow + legacy rules. references = pattern transform knowledge. fixtures/eval = proof the skill behaves.

---

## Task 1: Scaffold skill skeleton

**Files:**
- Create: `skills/pattern-surgeon/SKILL.md`
- Create: `README.md`

- [ ] **Step 1: Create SKILL.md with frontmatter only (body added Task 8)**

```markdown
---
name: pattern-surgeon
description: Use when the user names a TS/JS file or function and asks what design pattern fits, says the code is messy/has a big switch or conditional, or asks to refactor to a pattern. Recommends one of Strategy/Factory/Adapter/Repository/Observer/Dependency-Injection, applies it, and reverts unless typecheck and tests stay green.
---

# pattern-surgeon

<!-- body added in Task 8 -->
```

- [ ] **Step 2: Create README.md**

```markdown
# pattern-surgeon

Reactive TS/JS design-pattern advisor. Point it at a scope; it recommends a
pattern, applies the refactor, and keeps it only if `tsc --noEmit` + tests stay
green. Covers Strategy, Factory, Adapter, Repository, Observer, Dependency
Injection. See `docs/superpowers/specs/2026-05-17-pattern-surgeon-design.md`.
```

- [ ] **Step 3: Commit**

```bash
git add skills/pattern-surgeon/SKILL.md README.md
git commit -m "feat(pattern-surgeon): scaffold skill skeleton"
```

---

## Task 2: checkpoint.sh

**Files:**
- Create: `skills/pattern-surgeon/scripts/checkpoint.sh`
- Test: `tests/scripts/checkpoint.bats`

- [ ] **Step 1: Write the failing test**

```bash
# tests/scripts/checkpoint.bats
setup() {
  TMP="$(mktemp -d)"; cd "$TMP"
  git init -q; git config user.email t@t; git config user.name t
  echo a > f.txt; git add .; git commit -qm init
  echo b > f.txt   # dirty working tree
}
teardown() { rm -rf "$TMP"; }

@test "checkpoint prints a stash sha and leaves working tree unchanged" {
  run bash "$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/checkpoint.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9a-f]{40}$ ]]
  [ "$(cat f.txt)" = "b" ]
}

@test "checkpoint aborts when not a git repo" {
  cd "$TMP"; rm -rf .git
  run bash "$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/checkpoint.sh"
  [ "$status" -ne 0 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/checkpoint.bats`
Expected: FAIL ("checkpoint.sh: No such file or directory")

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "pattern-surgeon: not a git repo; cannot checkpoint" >&2; exit 1; }
sha="$(git stash create "pattern-surgeon checkpoint" || true)"
[ -n "$sha" ] || sha="$(git rev-parse HEAD)"   # clean tree: pin HEAD
echo "$sha"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/checkpoint.bats`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
chmod +x skills/pattern-surgeon/scripts/checkpoint.sh
git add skills/pattern-surgeon/scripts/checkpoint.sh tests/scripts/checkpoint.bats
git commit -m "feat(pattern-surgeon): add checkpoint.sh"
```

---

## Task 3: verify.sh

**Files:**
- Create: `skills/pattern-surgeon/scripts/verify.sh`
- Test: `tests/scripts/verify.bats`

- [ ] **Step 1: Write the failing test**

```bash
# tests/scripts/verify.bats
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/verify.bats`
Expected: FAIL ("verify.sh: No such file or directory")

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

if   [ -f pnpm-lock.yaml ]; then PM=pnpm
elif [ -f yarn.lock ];      then PM=yarn
else                             PM=npm
fi

run() { if [ "$PM" = npm ]; then npx --no-install "$@"; else "$PM" exec "$@"; fi; }

if [ -f tsconfig.json ]; then
  run tsc --noEmit || { echo "pattern-surgeon: typecheck FAILED" >&2; exit 2; }
fi

if node -e "process.exit(require('./package.json').scripts?.test?0:1)" 2>/dev/null; then
  "$PM" test || { echo "pattern-surgeon: tests FAILED" >&2; exit 3; }
else
  echo "pattern-surgeon: no test script found" >&2; exit 4
fi
echo "pattern-surgeon: verify OK"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/verify.bats`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
chmod +x skills/pattern-surgeon/scripts/verify.sh
git add skills/pattern-surgeon/scripts/verify.sh tests/scripts/verify.bats
git commit -m "feat(pattern-surgeon): add verify.sh"
```

---

## Task 4: rollback.sh

**Files:**
- Create: `skills/pattern-surgeon/scripts/rollback.sh`
- Test: `tests/scripts/rollback.bats`

- [ ] **Step 1: Write the failing test**

```bash
# tests/scripts/rollback.bats
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/rollback.bats`
Expected: FAIL ("rollback.sh: No such file or directory")

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail
sha="${1:?usage: rollback.sh <checkpoint-sha>}"
echo "===== REJECTED DIFF (attempted change, now reverted) ====="
git diff "$sha" -- . || true
echo "=========================================================="
git checkout "$sha" -- . 2>/dev/null || git restore --source="$sha" -- . 
git stash drop >/dev/null 2>&1 || true
echo "pattern-surgeon: rolled back to $sha"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/rollback.bats`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
chmod +x skills/pattern-surgeon/scripts/rollback.sh
git add skills/pattern-surgeon/scripts/rollback.sh tests/scripts/rollback.bats
git commit -m "feat(pattern-surgeon): add rollback.sh"
```

---

## Task 5: safety-harness.md reference

**Files:**
- Create: `skills/pattern-surgeon/references/safety-harness.md`

- [ ] **Step 1: Write the reference**

```markdown
# Safety Harness Protocol

Never keep an edit without a green verify.

1. Run `scripts/checkpoint.sh` — capture SHA. Abort the whole operation if it
   exits non-zero (not a git repo).
2. Apply the refactor edits.
3. Run `scripts/verify.sh`.
   - Exit 0 → keep changes. Summarize what changed and why.
   - Exit 2 (typecheck) / 3 (tests) → run `scripts/rollback.sh <SHA>`, show the
     rejected diff and the first failure, offer EXACTLY ONE retry.
   - Exit 4 (no test script) → see legacy handling in SKILL.md; do NOT keep
     unverified edits.
4. One auto-retry maximum. After a second failure, stop and report. Never loop.
```

- [ ] **Step 2: Commit**

```bash
git add skills/pattern-surgeon/references/safety-harness.md
git commit -m "docs(pattern-surgeon): add safety-harness reference"
```

---

## Task 6: Pattern reference files (6, fixed schema)

**Files:**
- Create: `skills/pattern-surgeon/references/patterns/strategy.md`
- Create: `skills/pattern-surgeon/references/patterns/factory.md`
- Create: `skills/pattern-surgeon/references/patterns/adapter.md`
- Create: `skills/pattern-surgeon/references/patterns/repository.md`
- Create: `skills/pattern-surgeon/references/patterns/observer.md`
- Create: `skills/pattern-surgeon/references/patterns/dependency-injection.md`

- [ ] **Step 1: Write strategy.md (template for all 6 — repeat schema per pattern)**

```markdown
# Strategy

## Smell signature
The same `switch`/`if-else` over a type/enum/string appears in ≥2 sites and
branches differ only by algorithm. Example:
\`\`\`ts
function price(kind: string, base: number) {
  if (kind === "regular") return base;
  if (kind === "vip") return base * 0.8;
  if (kind === "staff") return base * 0.5;
}
\`\`\`

## When NOT to apply
- Only one call site and unlikely to grow.
- Branches share heavy mutable state.
- Fewer than 3 cases.

## Transform recipe
1. Define `interface PricingStrategy { price(base: number): number }`.
2. One class per branch implementing it.
3. Replace conditionals with a `Record<string, PricingStrategy>` lookup.
4. Inject/select the strategy at the call boundary.

## Before / After
Before: the conditional above duplicated in checkout + invoice.
After: `strategies[kind].price(base)` at both sites.

## Verification focus
Same numeric outputs for every previously handled `kind`; default/unknown
branch preserved.

## Pitfalls
Do not create a strategy per value when a data table suffices. Keep the
selection map in one place.
```

- [ ] **Step 2: Write the remaining 5 files using the identical schema**

For each, fill all six sections with that pattern's specifics from the spec
detection table:
- `factory.md` — smell: `new X()` of one family in ≥3 places needing
  conditional/config; when-NOT: trivial single construction, DI owns it;
  recipe: extract `createX(cfg)` factory, centralize construction.
- `adapter.md` — smell: 3rd-party API called directly across modules,
  signature mismatch; when-NOT: single call site, lib already matches;
  recipe: define domain port interface, implement adapter wrapping the lib.
- `repository.md` — smell: raw ORM/SQL/fetch inside service/UI/business logic;
  when-NOT: already behind a data layer, one-off script; recipe: define
  `XRepository` interface, move data access behind it, inject into callers.
- `observer.md` — smell: manual cross-object notify chains / callback fan-out
  / polling for state change; when-NOT: single listener, framework already
  reactive; recipe: introduce subject with subscribe/notify, register
  listeners.
- `dependency-injection.md` — smell: `new` of collaborators inside a class,
  hard-coded singletons, hidden deps blocking tests; when-NOT: pure functions,
  value objects, leaf utilities; recipe: lift collaborators to constructor
  params, pass at composition root.

Each file MUST contain all six headed sections (`## Smell signature`,
`## When NOT to apply`, `## Transform recipe`, `## Before / After`,
`## Verification focus`, `## Pitfalls`) with concrete TS code.

- [ ] **Step 3: Verify schema consistency**

Run: `for f in skills/pattern-surgeon/references/patterns/*.md; do for h in "Smell signature" "When NOT to apply" "Transform recipe" "Before / After" "Verification focus" "Pitfalls"; do grep -q "## $h" "$f" || echo "MISSING $h in $f"; done; done`
Expected: no output (all sections present in all 6 files)

- [ ] **Step 4: Commit**

```bash
git add skills/pattern-surgeon/references/patterns/
git commit -m "docs(pattern-surgeon): add 6 pattern references"
```

---

## Task 7: Fixture projects (positive, negative, baseline-red)

**Files:**
- Create: `tests/fixtures/<pattern>-pos/` and `<pattern>-neg/` for all 6 patterns
- Create: `tests/fixtures/baseline-red/`

- [ ] **Step 1: Create one positive fixture (strategy-pos) — full template**

`tests/fixtures/strategy-pos/package.json`:
```json
{ "name": "strategy-pos", "scripts": { "test": "node test.js" },
  "devDependencies": { "typescript": "*" } }
```
`tests/fixtures/strategy-pos/tsconfig.json`:
```json
{ "compilerOptions": { "strict": true, "noEmit": true } }
```
`tests/fixtures/strategy-pos/src.ts` — contains the Strategy smell (the
duplicated `kind` conditional at two call sites).
`tests/fixtures/strategy-pos/test.js` — asserts the observable outputs
(`price("vip",100)===80`, etc.) so any correct refactor stays green.

- [ ] **Step 2: Create the other 5 positive fixtures**

Same 4-file structure; `src.ts` carries that pattern's smell; `test.js`
asserts behavior preserved across refactor. Use the spec detection table.

- [ ] **Step 3: Create 6 negative fixtures (`<pattern>-neg`)**

Same structure but the code matches a "When NOT to apply" case (e.g.
`strategy-neg`: a single 2-branch conditional at one site). The skill must
recommend NO refactor here.

- [ ] **Step 4: Create baseline-red fixture**

`tests/fixtures/baseline-red/package.json` with **no `test` script**, and a
`src.ts` with a type error. Represents legacy/untested code.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures/
git commit -m "test(pattern-surgeon): add pos/neg/baseline fixtures"
```

---

## Task 8: SKILL.md body (advisor brain)

**Files:**
- Modify: `skills/pattern-surgeon/SKILL.md` (replace `<!-- body added in Task 8 -->`)

- [ ] **Step 1: Write the body**

```markdown
## When to use
User points at a TS/JS scope (file/function/class) and asks what pattern fits,
says it is messy/has a big switch, or asks to refactor to a pattern. Reactive
only — never scan the whole repo unprompted.

## Procedure
1. Read the named scope only.
2. Match against the 6 detection rules below. Confirm the smell AND that no
   "When NOT to apply" case holds (see `references/patterns/<name>.md`).
3. If ambiguous or two patterns plausible, ASK the user before editing. Never
   apply two patterns in one pass.
4. State: pattern, why, tradeoff, the when-NOT you ruled out.
5. On user OK, follow `references/safety-harness.md` exactly.

## Detection rules
| Pattern | Fire when | Suppress when |
|---|---|---|
| Strategy | same switch/if-else on type/enum/string ≥2 sites, branches differ only by algorithm | 1 site; shared heavy state; <3 cases |
| Factory | `new X()` of one family in ≥3 places needing conditional/config | trivial single construction; DI owns it |
| Adapter | 3rd-party API called directly across modules, signature mismatch | 1 call site; lib already matches domain |
| Repository | raw ORM/SQL/fetch inside service/UI/business logic | already behind a data layer; one-off script |
| Observer | manual notify chains / callback fan-out / polling for state | single listener; framework already reactive |
| Dependency Injection | `new` collaborators in class, hard-coded singletons, hidden deps | pure functions; value objects; leaf utilities |

## Legacy / old projects (while this skill is active)
- Run `scripts/verify.sh` BEFORE any edit (probe).
  - Baseline red, or exit 4 (no test script): do NOT auto-refactor. Switch to
    recommend-only. Report "no safety net: add a test or I cannot verify."
  - Offer to scaffold one characterization test around the scope; refactor
    only if the user opts in and the new test passes pre-refactor.
- Large legacy smell: propose the smallest viable slice (one pattern, one
  scope). List remaining opportunities as a deferred checklist; do not churn
  the whole file.
- Match the surrounding code's conventions, not a textbook ideal.

## Output contract
Recommendation: `<pattern>` — why / tradeoff / when-NOT ruled out.
After apply: changed files + behavior preserved, or rolled-back diff + first
failure + one retry offer.
```

- [ ] **Step 2: Validate the skill loads (frontmatter intact, single H1)**

Run: `head -5 skills/pattern-surgeon/SKILL.md && grep -c '^# ' skills/pattern-surgeon/SKILL.md`
Expected: frontmatter `name`/`description` present; grep prints `1`.

- [ ] **Step 3: Commit**

```bash
git add skills/pattern-surgeon/SKILL.md
git commit -m "feat(pattern-surgeon): add advisor brain to SKILL.md"
```

---

## Task 9: Eval harness

**Files:**
- Create: `tests/eval/run-eval.sh`

- [ ] **Step 1: Write the eval driver**

```bash
#!/usr/bin/env bash
# Drives the skill against fixtures. Run from repo root.
# Positive: skill applies pattern AND verify.sh stays green.
# Negative + baseline-red: skill must NOT modify code.
set -euo pipefail
fail=0
for d in tests/fixtures/*-pos; do
  ( cd "$d" && npm i --silent >/dev/null 2>&1 || true )
  echo "POS  $d : run pattern-surgeon on src.ts, then:"
  echo "     bash skills/pattern-surgeon/scripts/verify.sh  # expect exit 0"
done
for d in tests/fixtures/*-neg tests/fixtures/baseline-red; do
  echo "NEG  $d : skill must recommend NO refactor / no edits"
done
echo "Manual/agent-driven checklist printed. fail=$fail"
exit $fail
```

- [ ] **Step 2: Run it**

Run: `bash tests/eval/run-eval.sh`
Expected: prints per-fixture expectations, exits 0.

- [ ] **Step 3: Commit**

```bash
chmod +x tests/eval/run-eval.sh
git add tests/eval/run-eval.sh
git commit -m "test(pattern-surgeon): add eval harness"
```

---

## Task 10: End-to-end dry run + docs link

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Manual E2E on strategy-pos**

In `tests/fixtures/strategy-pos`: invoke the skill on `src.ts`, let it apply
Strategy, confirm `bash ../../../skills/pattern-surgeon/scripts/verify.sh`
exits 0 and `test.js` assertions hold.

- [ ] **Step 2: Manual E2E on strategy-neg + baseline-red**

Confirm skill recommends no refactor on `strategy-neg`; confirm it refuses
auto-refactor and switches to recommend-only on `baseline-red`.

- [ ] **Step 3: Link spec/plan in README**

Add to `README.md`:
```markdown
## Docs
- Spec: `docs/superpowers/specs/2026-05-17-pattern-surgeon-design.md`
- Plan: `docs/superpowers/plans/2026-05-17-pattern-surgeon.md`
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(pattern-surgeon): link spec and plan"
```

---

## Self-Review

**Spec coverage:**
- Name/invocation → Task 1 (frontmatter), Task 8 (body). ✓
- Hybrid approach (LLM transform + harness) → Tasks 2–5, 8. ✓
- Architecture file tree → File Structure + Tasks 1–9. ✓
- Detection rules (all 6) → Task 6 references + Task 8 table. ✓
- Per-pattern fixed schema → Task 6 (enforced by Step 3 grep). ✓
- Verify-harness contract (checkpoint/verify/rollback, exit codes, one retry) → Tasks 2,3,4,5. ✓
- Legacy handling (probe, no-test scaffold, incremental, conventions) → Task 8. ✓
- Testing the skill (pos/neg/baseline fixtures, eval) → Tasks 7,9,10. ✓
- Extensibility (lang branch in verify.sh) → verify.sh structure (Task 3) leaves PM/typecheck swappable. ✓

**Placeholder scan:** Task 6 Step 2 and Task 7 Steps 2–4 describe repeated structure rather than repeating full code — acceptable because the full template is given in the preceding step and the schema is grep-enforced; no "TBD"/"handle edge cases" placeholders remain.

**Type consistency:** Script names (`checkpoint.sh`/`verify.sh`/`rollback.sh`), exit codes (0 ok, 2 typecheck, 3 tests, 4 no-test), and the six section headers are used identically across spec, references, harness, and SKILL.md. ✓
