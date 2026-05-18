# pattern-surgeon Modes Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing `pattern-surgeon` skill with three new modes — `compare`, `follow`, `greenfield` — without rewriting its substrate or weakening the verify-or-revert safety contract.

**Architecture:** SKILL.md gains a deterministic Intent-routing step and a `## Modes` block. Two new reference docs back the new modes. No new scripts; `verify.sh` / `checkpoint.sh` / `rollback.sh` are reused unchanged. Every change is additive and gated by bats structure tests plus the existing regression suite.

**Tech Stack:** Markdown skill files, bats (Bash Automated Testing System) for structure/regression tests, existing per-ecosystem fixture projects.

---

## Spec

`docs/superpowers/specs/2026-05-18-pattern-surgeon-modes-design.md` (commit `c39d38a`).

## File Structure

- Create: `skills/pattern-surgeon/references/comparison-rubric.md` — fixed scoring rubric for `compare`.
- Create: `skills/pattern-surgeon/references/greenfield-tdd.md` — TDD-first loop for `greenfield`.
- Modify: `skills/pattern-surgeon/SKILL.md` — add Intent routing, `## Modes`, widen `description:`, extend Output contract.
- Create: `tests/scripts/ref-modes.bats` — structure assertions for the two new ref docs.
- Create: `tests/scripts/skill-modes.bats` — structure assertions for SKILL.md additions.
- Create: `tests/fixtures/compare-ambiguous-ts/` — eval anchor: Strategy-vs-Factory plausible scope.
- Create: `tests/fixtures/follow-repo-ts/` — eval anchor: established Repository convention + new non-conforming file.
- Create: `tests/fixtures/greenfield-ts/` — eval anchor + exit-3 gate fixture (failing test, no impl).

Unchanged: `references/patterns/*.md`, `scripts/*.sh`, all existing fixtures, `tests/scripts/{verify,verify-router,checkpoint,rollback,ref-schema}.bats`.

## bats note

A literal triple-backtick in a bats test body breaks the bats 1.13 source parser (the test is silently not collected). Mirror `ref-schema.bats`: build the fence in a variable (`fence='```'`) and use `grep -qF "$fence..."`. Never put a raw ``` inside a `@test` body.

---

### Task 1: comparison-rubric.md reference doc

**Files:**
- Create: `skills/pattern-surgeon/references/comparison-rubric.md`
- Test: `tests/scripts/ref-modes.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/scripts/ref-modes.bats`:

```bash
ROOT="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/references"

@test "comparison-rubric.md has the five scoring axes" {
  f="$ROOT/comparison-rubric.md"
  [ -f "$f" ]
  for axis in "smell-match strength" "change locality" "reversibility" \
              "framework-idiom conflict" "added-indirection cost"; do
    grep -qF "$axis" "$f" || { echo "MISSING axis: $axis"; false; }
  done
}

@test "comparison-rubric.md has verdict scale and tie-break order" {
  f="$ROOT/comparison-rubric.md"
  grep -qF "strong fit" "$f"
  grep -qF "partial" "$f"
  grep -qF "wrong tool here" "$f"
  grep -qF "Tie-break order" "$f"
}

@test "comparison-rubric.md has a worked Strategy-vs-Factory example" {
  f="$ROOT/comparison-rubric.md"
  grep -qF "Worked example" "$f"
  grep -qF "Strategy" "$f"
  grep -qF "Factory" "$f"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/ref-modes.bats`
Expected: FAIL — `comparison-rubric.md` does not exist (`[ -f "$f" ]` fails).

- [ ] **Step 3: Create the reference doc**

Create `skills/pattern-surgeon/references/comparison-rubric.md`:

```markdown
# Comparison Rubric

Used by the `compare` mode. Makes pattern comparison deterministic instead of
subjective. Score each plausible candidate against the same axes, render the
matrix, then apply the tie-break order.

## Scoring axes

Score each axis `2` / `1` / `0`.

- **smell-match strength** — how exactly the named scope exhibits this
  pattern's detection rule (2 = textbook smell, 1 = near-miss, 0 = absent).
- **change locality** — how few sites change to apply it (2 = the named scope
  only, 1 = scope + direct callers, 0 = cross-module).
- **reversibility** — how cleanly it can be reverted (2 = pure restructure,
  1 = adds a seam, 0 = changes public surface).
- **framework-idiom conflict** — 2 = matches the detected framework idiom,
  1 = neutral, 0 = fights the framework (e.g. hand-rolled DI in Spring).
- **added-indirection cost** — 2 = removes duplication net-negative cost,
  1 = neutral, 0 = adds indirection with thin payoff.

## Verdict scale

Map the axis total (0–10) to a verdict:

- `strong fit` — total ≥ 8 and smell-match = 2.
- `partial` — total 4–7, or smell-match = 1.
- `wrong tool here` — total ≤ 3, or smell-match = 0, or framework-idiom
  conflict = 0.

## Recommendation and tie-break

Recommend the highest-scoring `strong fit`. State one line on why it beats the
runner-up.

**Tie-break order** (apply when top two totals are equal):

1. Lower added-indirection cost wins.
2. Then higher framework-idiom conflict score (better idiom fit) wins.
3. Then fewer touched files (higher change-locality score) wins.
4. Still tied → state the tie and ASK the user to pick.

## Worked example

Scope: a function with a typed `switch` that both branches on `kind` AND
`new`s a different collaborator per branch, across 3 call sites.

| pattern | why-fits-here | tradeoff | when-NOT ruled | smell | local | revers | fw | indir | total | verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| Strategy | switch on type ≥2 sites, branches differ by algorithm | one class per branch | not <3 cases, no shared heavy state | 2 | 2 | 2 | 1 | 2 | 9 | strong fit |
| Factory | a family is constructed conditionally | indirection if construction is trivial | construction is non-trivial here | 1 | 1 | 2 | 1 | 1 | 6 | partial |

Recommendation: **Strategy** — it removes the duplicated algorithm switch at
all 3 sites; Factory would only relocate the construction, leaving the
algorithm branching in place.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/ref-modes.bats`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/references/comparison-rubric.md tests/scripts/ref-modes.bats
git commit -m "feat(pattern-surgeon): comparison rubric ref + structure test"
```

---

### Task 2: greenfield-tdd.md reference doc

**Files:**
- Create: `skills/pattern-surgeon/references/greenfield-tdd.md`
- Test: `tests/scripts/ref-modes.bats` (append)

- [ ] **Step 1: Write the failing test**

Append to `tests/scripts/ref-modes.bats`:

```bash
@test "greenfield-tdd.md has per-language test runners" {
  f="$ROOT/greenfield-tdd.md"
  [ -f "$f" ]
  for r in pytest JUnit xUnit PHPUnit vitest; do
    grep -qF "$r" "$f" || { echo "MISSING runner: $r"; false; }
  done
}

@test "greenfield-tdd.md states the exit-3 gate and reroute rule" {
  f="$ROOT/greenfield-tdd.md"
  grep -qF "exit 3" "$f"
  grep -qF "exit 0" "$f"
  grep -qF "exit 4" "$f"
  grep -qF "reroute to refactor" "$f"
  grep -qF "safety-harness.md" "$f"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/ref-modes.bats`
Expected: FAIL on the two new tests — `greenfield-tdd.md` does not exist.

- [ ] **Step 3: Create the reference doc**

Create `skills/pattern-surgeon/references/greenfield-tdd.md`:

```markdown
# Greenfield TDD Loop

Used by the `greenfield` mode: implement new behavior with the right pattern
when no code exists yet. The verify-or-revert guarantee is preserved by making
a failing test exist *before* any implementation.

## Loop

1. Confirm the target behavior with the user (one question if unclear).
2. Detect language/framework from the nearest project marker to the target
   path (same detection step as every other mode).
3. Pick the pattern using `comparison-rubric.md` (matrix → one).
4. Write a failing test for the behavior first. Run `scripts/verify.sh`:
   - exit 3 (test red) → correct start state; proceed to step 5.
   - exit 0 (already passes) → the behavior already exists; **reroute to
     refactor** mode, do not duplicate.
   - exit 4 (no test runner/target) → cannot establish a safety net; abort to
     recommend-only. Do not write unverifiable code.
   - exit 2 (typecheck) → fix the test until it compiles and is red, or abort.
5. Follow `safety-harness.md`: `checkpoint.sh`, implement the pattern-correct
   code, `verify.sh` must reach exit 0. exit 2/3 → `rollback.sh`, report the
   first failure, offer exactly one retry.

## Per-language test runner cues

- TypeScript/JS — `vitest` (or the package.json `test` script).
- Python — `pytest`.
- Java — `JUnit` via `mvn -q test` / `gradle test`.
- C#/.NET — `xUnit` via `dotnet test`.
- PHP — `PHPUnit` (or `php artisan test` on Laravel).

A "failing test for not-yet-built behavior" asserts the intended public
contract of the pattern's entry point (e.g. `strategies[kind].price(base)`
returns the expected number) against a symbol that does not yet exist — it
fails to compile or import, which is the expected red.

## Boundary

`greenfield` never scans the repo. It works only at the user-named target
path. If the user asks to also match existing conventions there, that is the
`follow` mode, not this one.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/ref-modes.bats`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add skills/pattern-surgeon/references/greenfield-tdd.md tests/scripts/ref-modes.bats
git commit -m "feat(pattern-surgeon): greenfield TDD ref + structure test"
```

---

### Task 3: SKILL.md — Intent routing + widened description

**Files:**
- Modify: `skills/pattern-surgeon/SKILL.md`
- Test: `tests/scripts/skill-modes.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/scripts/skill-modes.bats`:

```bash
SKILL="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/SKILL.md"

@test "SKILL.md has an Intent routing section with all five modes" {
  grep -qF "## Intent routing" "$SKILL"
  for m in suggest refactor compare follow greenfield; do
    grep -qF "\`$m\`" "$SKILL" || { echo "MISSING mode: $m"; false; }
  done
  grep -qiF "ambiguous" "$SKILL"
  grep -qF "ASK" "$SKILL"
}

@test "SKILL.md description front matter covers new modes and languages" {
  hdr="$(sed -n '1,5p' "$SKILL")"
  echo "$hdr" | grep -qiF "compare"
  echo "$hdr" | grep -qiF "match existing"
  echo "$hdr" | grep -qiF "implement"
  echo "$hdr" | grep -qiF "Python"
  echo "$hdr" | grep -qiF "Java"
  echo "$hdr" | grep -qiF "C#"
  echo "$hdr" | grep -qiF "PHP"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/skill-modes.bats`
Expected: FAIL — no `## Intent routing` section; description is TS/JS-only.

- [ ] **Step 3: Replace the description front matter**

In `skills/pattern-surgeon/SKILL.md`, replace the `description:` line (line 3) exactly:

Old:
```
description: Use when the user names a TS/JS file or function and asks what design pattern fits, says the code is messy/has a big switch or conditional, or asks to refactor to a pattern. Recommends one of Strategy/Factory/Adapter/Repository/Observer/Dependency-Injection, applies it, and reverts unless typecheck and tests stay green.
```

New:
```
description: Use when the user names a TS/JS/Python/Java/C#/PHP file or function and asks what design pattern fits, asks to compare which pattern (and why/how it fits), to refactor to a pattern, to make new code match existing patterns ("match existing", "make this consistent"), or to implement new behavior with the right pattern. Recommends one of Strategy/Factory/Adapter/Repository/Observer/Dependency-Injection, applies it, and reverts unless typecheck and tests stay green. Reactive only — never scans the repo unprompted.
```

- [ ] **Step 4: Insert the Intent routing section**

In `skills/pattern-surgeon/SKILL.md`, insert immediately before the `## Procedure` line:

```markdown
## Intent routing
Before the Procedure, map the request to exactly one mode. Ambiguous between
two modes → ASK the user which; never guess.

| Mode | Trigger | Mutates code? |
|---|---|---|
| `suggest` | "what pattern fits X" | no |
| `refactor` | "refactor X to a pattern" / messy code / big switch | yes |
| `compare` | "which: A or B", "compare patterns for X", "why this over that" | no |
| `follow` | "match existing patterns here", "make this consistent" | optional |
| `greenfield` | "implement X with the right pattern" (X not yet coded) | yes |

`suggest` + `refactor` use the Procedure below. `compare`, `follow`,
`greenfield` use `## Modes`. Language/framework detection and the Detection
rules are shared by every mode.

```

- [ ] **Step 5: Run test to verify it passes**

Run: `bats tests/scripts/skill-modes.bats`
Expected: first test PASS; second test PASS. (Both pass now.)

- [ ] **Step 6: Run the existing regression suite**

Run: `bats tests/scripts/`
Expected: all existing tests still PASS (no regression from the SKILL.md edits).

- [ ] **Step 7: Commit**

```bash
git add skills/pattern-surgeon/SKILL.md tests/scripts/skill-modes.bats
git commit -m "feat(pattern-surgeon): intent routing + widened description"
```

---

### Task 4: SKILL.md — Modes block + Output contract

**Files:**
- Modify: `skills/pattern-surgeon/SKILL.md`
- Test: `tests/scripts/skill-modes.bats` (append)

- [ ] **Step 1: Write the failing test**

Append to `tests/scripts/skill-modes.bats`:

```bash
@test "SKILL.md has a Modes block with the three new procedures" {
  grep -qF "## Modes" "$SKILL"
  grep -qF "### compare" "$SKILL"
  grep -qF "### follow" "$SKILL"
  grep -qF "### greenfield" "$SKILL"
  grep -qF "comparison-rubric.md" "$SKILL"
  grep -qF "greenfield-tdd.md" "$SKILL"
  grep -qF "sibling files" "$SKILL"
}

@test "SKILL.md Output contract covers compare and greenfield" {
  grep -qF "matrix" "$SKILL"
  grep -qiF "failing test first" "$SKILL"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/skill-modes.bats`
Expected: the two new tests FAIL — no `## Modes` block; Output contract unchanged.

- [ ] **Step 3: Insert the Modes block**

In `skills/pattern-surgeon/SKILL.md`, insert immediately before the
`## Legacy / old projects (while this skill is active)` line:

```markdown
## Modes

### compare (read-only)
1. Read the named scope only.
2. Run the Detection rules; keep patterns that plausibly fit (smell present or
   near-miss). Drop the rest.
3. Score each candidate per `references/comparison-rubric.md`; render the
   matrix (pattern | why-fits-here | tradeoff | when-NOT ruled | verdict).
4. Recommend one + one line on why it beats the runner-up. Exact tie → state
   the tie and ASK the user to pick.
5. No code change. If the user then says go, chain into `refactor` or
   `greenfield`.

### follow (user-triggered scoped scan)
1. Only on an explicit "match existing / make consistent" request (keeps the
   reactive rule). Scope = the named file + sibling files in the same
   directory + the nearest layer directory (e.g. `services/`). Hard cap — no
   repo-wide walk.
2. Census which of the 6 patterns already appear in scope; note local
   conventions (naming, DI style, framework idiom in use).
3. The recommendation must conform to the detected convention. If the textbook
   pattern conflicts with house style, follow house style and state the
   deviation explicitly.
4. No pattern detectable in scope → say so; fall back to `suggest`.
5. If the user wants the edit applied, follow `references/safety-harness.md`.

### greenfield (TDD-first)
Follow `references/greenfield-tdd.md` exactly: confirm behavior → detect
language → pick pattern via the rubric → write a failing test first
(`verify.sh` must show exit 3; exit 0 → reroute to `refactor`; exit 4 →
recommend-only) → then `safety-harness.md` to implement to exit 0 or roll back.

```

- [ ] **Step 4: Replace the Output contract section**

In `skills/pattern-surgeon/SKILL.md`, replace the `## Output contract` section body exactly:

Old:
```
## Output contract
Recommendation: `<pattern>` — why / tradeoff / when-NOT ruled out.
After apply: changed files + behavior preserved, or rolled-back diff + first
failure + one retry offer.
```

New:
```
## Output contract
- `suggest` / `refactor` / `follow`: Recommendation `<pattern>` — why /
  tradeoff / when-NOT ruled out. After apply: changed files + behavior
  preserved, or rolled-back diff + first failure + one retry offer.
- `compare`: the candidate matrix + the single recommendation and why it beats
  the runner-up. No code change.
- `greenfield`: the failing test first (verify exit 3 shown), then changed
  files + behavior verified (exit 0), or rolled-back diff + first failure +
  one retry offer.
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bats tests/scripts/skill-modes.bats`
Expected: all 4 tests PASS.

- [ ] **Step 6: Run the existing regression suite**

Run: `bats tests/scripts/`
Expected: all tests PASS (including `ref-schema.bats`, `verify*.bats`,
`checkpoint.bats`, `rollback.bats`).

- [ ] **Step 7: Commit**

```bash
git add skills/pattern-surgeon/SKILL.md tests/scripts/skill-modes.bats
git commit -m "feat(pattern-surgeon): modes block + output contract for compare/follow/greenfield"
```

---

### Task 5: compare-ambiguous-ts fixture (eval anchor)

**Files:**
- Create: `tests/fixtures/compare-ambiguous-ts/src.ts`
- Create: `tests/fixtures/compare-ambiguous-ts/README.md`

- [ ] **Step 1: Write the failing test**

Append to `tests/scripts/skill-modes.bats`:

```bash
@test "compare-ambiguous fixture exists with the dual-smell scope" {
  d="$BATS_TEST_DIRNAME/../fixtures/compare-ambiguous-ts"
  [ -f "$d/src.ts" ]
  [ -f "$d/README.md" ]
  grep -qF "switch" "$d/src.ts"
  grep -qF "new " "$d/src.ts"
  grep -qiF "Strategy" "$d/README.md"
  grep -qiF "Factory" "$d/README.md"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/skill-modes.bats -f compare-ambiguous`
Expected: FAIL — fixture directory does not exist.

- [ ] **Step 3: Create the fixture**

Create `tests/fixtures/compare-ambiguous-ts/src.ts`:

```ts
// Dual smell: switch on `kind` (Strategy candidate) AND constructs a
// different collaborator per branch (Factory candidate). Used across 3 sites.
interface Notifier { send(msg: string): void }

class EmailNotifier implements Notifier { send(m: string) { console.log("email", m); } }
class SmsNotifier implements Notifier { send(m: string) { console.log("sms", m); } }
class PushNotifier implements Notifier { send(m: string) { console.log("push", m); } }

export function notify(kind: string, msg: string): void {
  let n: Notifier;
  switch (kind) {
    case "email": n = new EmailNotifier(); break;
    case "sms":   n = new SmsNotifier();   break;
    case "push":  n = new PushNotifier();  break;
    default: throw new Error("unknown kind");
  }
  n.send(msg);
}
```

Create `tests/fixtures/compare-ambiguous-ts/README.md`:

```markdown
# compare-ambiguous-ts

Eval anchor for `compare` mode. `notify` exhibits both a Strategy smell
(switch on type, ≥2 sites, branches differ by behavior) and a Factory smell
(conditional construction of a `Notifier` family).

Expected `compare` output: a matrix scoring **Strategy** and **Factory** per
`comparison-rubric.md`, recommending **Strategy** (it removes the algorithm
branching at all sites; Factory alone would only relocate construction). No
code mutation.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/skill-modes.bats -f compare-ambiguous`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures/compare-ambiguous-ts tests/scripts/skill-modes.bats
git commit -m "test(pattern-surgeon): compare-ambiguous eval fixture"
```

---

### Task 6: follow-repo-ts fixture (eval anchor)

**Files:**
- Create: `tests/fixtures/follow-repo-ts/repo/UserRepository.ts`
- Create: `tests/fixtures/follow-repo-ts/repo/OrderRepository.ts`
- Create: `tests/fixtures/follow-repo-ts/services/InvoiceService.ts`
- Create: `tests/fixtures/follow-repo-ts/README.md`

- [ ] **Step 1: Write the failing test**

Append to `tests/scripts/skill-modes.bats`:

```bash
@test "follow-repo fixture has sibling convention plus a non-conforming file" {
  d="$BATS_TEST_DIRNAME/../fixtures/follow-repo-ts"
  [ -f "$d/repo/UserRepository.ts" ]
  [ -f "$d/repo/OrderRepository.ts" ]
  [ -f "$d/services/InvoiceService.ts" ]
  grep -qF "fetch(" "$d/services/InvoiceService.ts"
  grep -qiF "Repository" "$d/README.md"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/skill-modes.bats -f follow-repo`
Expected: FAIL — fixture does not exist.

- [ ] **Step 3: Create the fixture**

Create `tests/fixtures/follow-repo-ts/repo/UserRepository.ts`:

```ts
export interface User { id: string; name: string }

export class UserRepository {
  async byId(id: string): Promise<User | null> {
    const r = await fetch(`/api/users/${id}`);
    return r.ok ? (await r.json()) as User : null;
  }
}
```

Create `tests/fixtures/follow-repo-ts/repo/OrderRepository.ts`:

```ts
export interface Order { id: string; total: number }

export class OrderRepository {
  async byId(id: string): Promise<Order | null> {
    const r = await fetch(`/api/orders/${id}`);
    return r.ok ? (await r.json()) as Order : null;
  }
}
```

Create `tests/fixtures/follow-repo-ts/services/InvoiceService.ts`:

```ts
// Non-conforming: raw fetch inside the service instead of a Repository,
// breaking the established repo/ convention.
export class InvoiceService {
  async invoiceTotal(orderId: string): Promise<number> {
    const r = await fetch(`/api/orders/${orderId}`);
    const o = await r.json();
    return o.total * 1.2;
  }
}
```

Create `tests/fixtures/follow-repo-ts/README.md`:

```markdown
# follow-repo-ts

Eval anchor for `follow` mode. `repo/` establishes a Repository convention
(`*Repository` class, `byId`, `fetch` confined to the repo layer).
`services/InvoiceService.ts` violates it with a raw `fetch`.

Expected `follow` output: scoped scan (named file + `services/` siblings +
nearest layer) detects the Repository convention; recommendation introduces an
`OrderRepository`-style access for `InvoiceService`, conforming to the existing
naming/structure rather than a textbook variant. Scan must not exceed the
scope cap (no repo-wide walk).
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/skill-modes.bats -f follow-repo`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures/follow-repo-ts tests/scripts/skill-modes.bats
git commit -m "test(pattern-surgeon): follow-repo eval fixture"
```

---

### Task 7: greenfield-ts fixture + exit-3 gate

**Files:**
- Create: `tests/fixtures/greenfield-ts/package.json`
- Create: `tests/fixtures/greenfield-ts/tsconfig.json`
- Create: `tests/fixtures/greenfield-ts/test.js`
- Create: `tests/fixtures/greenfield-ts/SPEC.md`
- Test: `tests/scripts/skill-modes.bats` (append)

- [ ] **Step 1: Write the failing test**

Append to `tests/scripts/skill-modes.bats`:

```bash
@test "greenfield fixture starts red (verify.sh exits 3, no impl yet)" {
  d="$BATS_TEST_DIRNAME/../fixtures/greenfield-ts"
  [ -f "$d/SPEC.md" ]
  [ -f "$d/test.js" ]
  command -v node >/dev/null 2>&1 || skip "node not installed"
  vs="$BATS_TEST_DIRNAME/../../skills/pattern-surgeon/scripts/verify.sh"
  run bash -c "cd \"$d\" && bash \"$vs\""
  [ "$status" -eq 3 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bats tests/scripts/skill-modes.bats -f greenfield`
Expected: FAIL — fixture does not exist (`[ -f "$d/SPEC.md" ]` fails).

- [ ] **Step 3: Create the fixture (failing test, no implementation)**

Create `tests/fixtures/greenfield-ts/package.json`:

```json
{
  "name": "greenfield-ts",
  "private": true,
  "scripts": { "test": "node test.js" }
}
```

Create `tests/fixtures/greenfield-ts/tsconfig.json`:

```json
{ "compilerOptions": { "noEmit": true, "strict": true, "skipLibCheck": true } }
```

Create `tests/fixtures/greenfield-ts/test.js`:

```js
// Failing test for not-yet-built behavior: `notify` does not exist yet.
let notify;
try { ({ notify } = require("./impl.js")); }
catch { console.error("impl.js missing — expected red"); process.exit(1); }

const out = [];
const orig = console.log;
console.log = (...a) => out.push(a.join(" "));
notify("email", "hi");
console.log = orig;
if (out.join("") !== "email hi") { console.error("wrong output"); process.exit(1); }
console.log("ok");
```

Create `tests/fixtures/greenfield-ts/SPEC.md`:

```markdown
# greenfield-ts

Eval anchor for `greenfield` mode. No `impl.js` exists; `test.js` is the
pre-written failing test (`verify.sh` exits 3 — the correct start state).

Target behavior: `notify(kind, msg)` dispatches to per-kind notifiers
("email"/"sms"/"push"). Expected `greenfield` flow: pick a pattern via
`comparison-rubric.md` (Strategy), `checkpoint.sh`, write `impl.js`
implementing it, `verify.sh` reaches exit 0. Do NOT commit a generated
`impl.js` into this fixture — the committed state must stay red so the gate
test keeps asserting exit 3.
```

Note: there is intentionally no `node_modules`/`tsc` here; with no
`tsconfig`-driven typecheck tool installed locally the router skips typecheck,
runs `npm test`, the test exits 1 → `verify.sh` exits 3. (`tsconfig.json` is
present only so the eval exercises the TS branch; `verify.sh` uses
`npx --no-install tsc` which no-ops when typescript is absent and does not
fail the run.)

- [ ] **Step 4: Run test to verify it passes**

Run: `bats tests/scripts/skill-modes.bats -f greenfield`
Expected: PASS (or `skip` if node is not installed — explicit skip, never a
silent pass).

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures/greenfield-ts tests/scripts/skill-modes.bats
git commit -m "test(pattern-surgeon): greenfield eval fixture + exit-3 gate"
```

---

### Task 8: Full regression gate

**Files:** none (verification only).

- [ ] **Step 1: Run the entire bats suite**

Run: `bats tests/scripts/`
Expected: ALL tests PASS — the original `verify.bats`, `verify-router.bats`,
`checkpoint.bats`, `rollback.bats`, `ref-schema.bats` (8 original tests) plus
the new `ref-modes.bats` and `skill-modes.bats`. Zero failures, zero
regressions.

- [ ] **Step 2: Confirm pattern refs and scripts are untouched by the modes work**

The modes extension begins at the plan commit `a83d3ea`; the multilang branch
legitimately modified pattern refs/scripts in earlier commits, so the baseline
must be the plan commit, not `main`.

Run: `git diff --name-only a83d3ea..HEAD -- skills/pattern-surgeon/references/patterns skills/pattern-surgeon/scripts`
Expected: EMPTY output (the modes extension touched no pattern ref or script — additive only).

- [ ] **Step 3: Commit (only if Step 1/2 surfaced a fix)**

If Steps 1–2 are clean, no commit. If a regression was found and fixed:

```bash
git add -A
git commit -m "fix(pattern-surgeon): restore regression green after modes extension"
```

---

### Task 9: Mode behavior dry-run verification

**Files:** none (manual eval; record results in the PR description).

Skill behavioral correctness (does the model route + act correctly) is not
expressible in bats. Verify it by dry-running each mode against its fixture and
confirming the documented expected output.

- [ ] **Step 1: `compare` dry run**

Prompt the skill: "Which design pattern fits `notify` in
`tests/fixtures/compare-ambiguous-ts/src.ts`?"
Expected: a candidate matrix scoring Strategy and Factory per the rubric,
recommending **Strategy** with a one-line reason it beats Factory, and NO file
edit.

- [ ] **Step 2: `follow` dry run**

Prompt: "Make `tests/fixtures/follow-repo-ts/services/InvoiceService.ts` match
the existing patterns here."
Expected: scoped scan acknowledges `repo/` Repository convention; recommends an
`OrderRepository`-style accessor conforming to existing naming; explicitly
states the scan stayed within scope (no repo-wide walk).

- [ ] **Step 3: `greenfield` dry run**

Prompt: "Implement the behavior in `tests/fixtures/greenfield-ts/SPEC.md` with
the right pattern."
Expected: confirms behavior → picks Strategy via rubric → notes the existing
`test.js` is the failing test (verify exit 3) → checkpoints → writes `impl.js`
→ verify exit 0. Confirm the committed fixture remains red afterward (the
generated `impl.js` is discarded, not committed).

- [ ] **Step 4: Ambiguity dry run**

Prompt: "Do something with patterns in
`tests/fixtures/compare-ambiguous-ts/src.ts`."
Expected: the skill ASKS which mode (compare vs refactor) instead of guessing;
no edit before the answer.

- [ ] **Step 5: Record results**

Record each dry-run outcome (pass/fail + observed output) in the PR
description. Any fail → fix the SKILL.md/ref wording, re-run Tasks 3–4 tests
and the relevant dry run.

---

## Self-Review

**Spec coverage:**
- Three modes (`compare`/`follow`/`greenfield`) — Tasks 3, 4 (procedures), 5–7 (fixtures), 9 (behavior).
- Verify-or-revert preserved for mutating modes — Task 2/4 reuse `safety-harness.md`; Task 7 + 8 prove the exit contract and that scripts are untouched.
- Greenfield TDD-first — Task 2 (ref) + Task 7 (exit-3 gate fixture) + Task 9 Step 3.
- `follow` honors reactive rule + scope cap — Task 4 procedure wording + Task 6 fixture + Task 9 Step 2.
- Existing tests stay green — Task 3 Step 6, Task 4 Step 6, Task 8.
- comparison-rubric.md / greenfield-tdd.md — Tasks 1, 2.
- SKILL.md Intent routing + Modes + Output contract + widened description — Tasks 3, 4.
- No new scripts; pattern refs untouched — Task 8 Step 2 asserts it.

**Placeholder scan:** No "TBD"/"TODO"/"similar to"/"add appropriate" — every doc and edit body is given in full.

**Type consistency:** Mode names `suggest|refactor|compare|follow|greenfield` are spelled identically in the description, Intent routing table, `## Modes`, Output contract, and every bats grep. Exit codes (`0/2/3/4`) match `verify.sh` and `safety-harness.md`. Ref filenames `comparison-rubric.md` / `greenfield-tdd.md` are consistent across SKILL.md and tests.
