# pattern-surgeon — Usage Guide

> Reactive, polyglot design-pattern skill for Claude Code. Points at a file,
> applies one of six patterns, verifies with your test suite, and auto-reverts
> on failure. Never touches code you didn't ask about.

---

## Install

### Option 1 — Claude Code plugin

In a Claude Code session, run these two commands:

```
/plugin marketplace add nuhin13/pattern-surgeon
/plugin install pattern-surgeon
```

The skill activates automatically. No slash command needed — just talk to Claude.

**To update:**
```
/plugin update pattern-surgeon
```

**To uninstall:**
```
/plugin remove pattern-surgeon
```

---

### Option 2 — npx (no Node project required)

```bash
# Global — available in all your projects
npx @nuhin13/pattern-surgeon

# Project-local — this project only, committable to git
npx @nuhin13/pattern-surgeon --project
```

Restart Claude Code after running (or open a new session).

**Help:**
```bash
npx @nuhin13/pattern-surgeon --help
```

**Uninstall:**
```bash
npx @nuhin13/pattern-surgeon remove
npx @nuhin13/pattern-surgeon remove --project
```

---

### Option 3 — npm global install

```bash
npm install -g @nuhin13/pattern-surgeon
# installs automatically via postinstall to ~/.claude/skills/
```

---

### Option 4 — shell one-liner

```bash
# Global
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash

# Project-local (commit to share with your team)
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash -s -- --project
git add .claude/skills/pattern-surgeon && git commit -m "add pattern-surgeon skill"
```

---

### Option 5 — clone the repo (zero install)

```bash
git clone https://github.com/nuhin13/pattern-surgeon
cd pattern-surgeon
```

`.claude/skills/pattern-surgeon` is already a symlink to `skills/pattern-surgeon/`.
Claude Code picks it up automatically when you open this directory — no install step.

---

### Where skills live

| Scope | Path | Who sees it |
|---|---|---|
| Global | `~/.claude/skills/pattern-surgeon/` | All your projects |
| Project | `.claude/skills/pattern-surgeon/` | This project only |

---

## Supported languages

| Language | Detection marker | Typecheck | Tests |
|---|---|---|---|
| TypeScript / JS | `package.json` + `tsconfig.json` | `tsc --noEmit` | `npm/yarn/pnpm test` |
| Python | `pyproject.toml` / `setup.py` / `requirements.txt` | `mypy .` (if configured) | `pytest` |
| Java (Maven) | `pom.xml` | `mvn -q compile` | `mvn -q test` |
| Java (Gradle) | `build.gradle` / `build.gradle.kts` | `./gradlew compileJava` | `./gradlew test` |
| C# / .NET | `*.csproj` / `*.sln` | `dotnet build` | `dotnet test` |
| PHP / Laravel | `composer.json` | phpstan (if installed) | `php artisan test` / phpunit |
| Kotlin / Android | `app/src/main/AndroidManifest.xml` | `./gradlew compileDebugKotlin` | `./gradlew testDebugUnitTest` |
| Dart / Flutter | `pubspec.yaml` (Flutter if `flutter:` dep present) | `dart analyze` / `flutter analyze` | `dart test` / `flutter test` |
| Swift | `Package.swift` | `swift build` | `swift test` |

---

## Supported patterns

| Pattern | Fires when | Suppressed when |
|---|---|---|
| **Strategy** | Same switch/if-else on type ≥ 2 sites, branches differ by algorithm | < 3 cases; single site; shared heavy state |
| **Factory** | `new X()` of one family in ≥ 3 places with conditional/config | Trivial single construction; DI container owns it |
| **Adapter** | 3rd-party API called directly across modules, signature mismatch | 1 call site; lib already matches domain |
| **Repository** | Raw ORM/SQL/fetch inside service/UI/business logic | Already behind a data layer; one-off script |
| **Observer** | Manual notify chains / callback fan-out to multiple consumers | Single listener; framework is already reactive |
| **Dependency Injection** | `new` collaborators inside a class, hard-coded singletons | Pure functions; value objects; leaf utilities |

---

## Five modes — how to trigger each

### 1. `suggest` — read-only recommendation

Ask what pattern fits a scope. No code is changed.

```
"What pattern fits src/checkout.ts?"
"Is there a pattern for this pricing function?"
"What would you recommend for services/OrderService.kt?"
```

**Example output:**

```
Recommendation: Strategy

Why: `price()` and `discountedTotal()` both switch on `kind` with identical
branch structure — textbook Strategy smell at 2 sites.

Tradeoff: adds one interface + N classes; worthwhile here because a 3rd
variant (e.g. "corporate") only requires a new class, not editing both
functions.

When-NOT ruled out: ≥ 3 cases present (regular/vip/staff); single-site
suppression does not apply; branches differ only by algorithm (no shared
state).

No code changed. Say "apply it" to refactor, or "compare" to see alternatives.
```

---

### 2. `refactor` — apply pattern with safety net

Apply a pattern. Runs typecheck + tests before keeping any change; auto-reverts
on failure.

```
"Refactor src/checkout.ts — it's a mess of if/elses"
"Apply Strategy to the pricing logic in Pricing.kt"
"This switch is getting unmanageable — fix it"
```

**What happens under the hood:**

```
1. Reads named scope only (not the whole repo)
2. Matches against detection rules (inline, no file loads yet)
3. Loads references/patterns/strategy.md for the Transform recipe
4. Asks you to confirm if two patterns are plausible
5. On your OK:
   a. checkpoint.sh  → git snapshot (SHA captured)
   b. Applies edits
   c. verify.sh      → typecheck + test suite
      Exit 0  → "Refactored. Behavior preserved." + diff summary
      Exit 2/3 → rollback.sh, shows rejected diff + first failure,
                 offers EXACTLY ONE retry
      Exit 4  → no test suite found → switches to recommend-only
```

**Example output (success):**

```
Refactored: Strategy applied to src/checkout.ts

Changed files:
  src/checkout.ts — replaced 2 conditional sites with strategies[] dispatch
  src/strategies/PricingStrategy.ts — new interface (3 lines)
  src/strategies/RegularStrategy.ts — new class (5 lines)
  src/strategies/VipStrategy.ts — new class (5 lines)
  src/strategies/StaffStrategy.ts — new class (5 lines)

Verify: tsc ✓  npm test ✓ (12 tests, 0 failed)
Behavior preserved.
```

**Example output (rollback):**

```
Refactor failed — rolled back to checkpoint abc1234.

First failure:
  TypeError: strategies[kind] is not a function
  at checkout.ts:14

Rejected diff shown above.

Retry? (one attempt remaining)
```

---

### 3. `compare` — scoring matrix, pick the best fit

When a scope could fit multiple patterns, or you want to understand the
trade-offs before committing.

```
"Compare Strategy vs Factory for src/UserService.kt"
"Which pattern — Repository or Adapter — for this data layer?"
"Why would I use Strategy over DI here?"
```

**Example output:**

```
Scope: src/UserService.kt

| Pattern    | Why fits                        | Tradeoff              | When-NOT ruled          | smell | local | revers | fw | indir | total | verdict    |
|------------|----------------------------------|----------------------|-------------------------|-------|-------|--------|----|-------|-------|------------|
| Strategy   | switch on kind at 3 sites        | adds N classes        | ≥3 cases; not single-site| 2     | 2     | 2      | 1  | 2     | 9     | strong fit |
| Factory    | new X() at 3 sites               | relocates construction| construction non-trivial | 1     | 1     | 2      | 1  | 1     | 6     | partial    |

Recommendation: Strategy — it eliminates the duplicated algorithm switch at
all 3 sites. Factory would only relocate construction, leaving the algorithm
branching in place.

No code changed. Say "apply it" to refactor.
```

---

### 4. `follow` — match existing conventions

Make a new file or function consistent with patterns already used nearby.

```
"Make src/payments.dart consistent with existing patterns in src/"
"Match the style in services/ for this new handler"
"Make OrderService.swift follow the same pattern as UserService.swift"
```

**Scope:** named file + siblings in the same directory + nearest recognized
layer directory (`services/`, `repositories/`, `adapters/`, etc.). Hard cap:
max 20 files, never crosses a project root.

**Example output:**

```
Convention detected in src/repositories/:
  - Repository pattern (UserRepository.ts, OrderRepository.ts both use
    findById() + save() interface style with camelCase naming)
  - DI style: constructor injection with interface typing

For InvoiceRepository.ts, I recommend: Repository pattern following the
same interface shape — findById(id: string): Promise<Invoice | null>

Deviations from house style vs textbook: none detected.

Apply? (will use the safety net)
```

---

### 5. `greenfield` — TDD-first implementation

Implement brand-new behavior with the right pattern from the start. Writes a
failing test first, then implements to green.

```
"Implement notify(kind, msg) with the right pattern in src/notifications.ts"
"Add a payment processing feature using the best pattern"
"Create a new UserRepository in Kotlin using the right approach"
```

**TDD gate:** verify.sh must exit 3 (test red, no impl) before implementation
begins. If it exits 0, the behavior already exists — rerouted to `refactor`.

**Example output:**

```
Target: src/notifications.ts
Behavior: notify(kind, msg) dispatches to email/sms/push handlers

Pattern selected: Strategy (scoring: smell=2 for branching need; local=2;
reversibility=2; framework=1; indir=2 → total 9, strong fit)

Step 1 — Failing test written:
  test/notifications.test.ts: notify("email", "hello") → expect emailSent

verify.sh → exit 3 (test red ✓ — correct start state)

Step 2 — Implementing Strategy pattern...
[checkpoint created: sha=def5678]

verify.sh → exit 0 ✓

Changed files:
  src/notifications.ts — Strategy dispatch (3 strategies)
  test/notifications.test.ts — 4 tests, all passing
```

---

## Safety contract

Every code-mutating mode follows this exact protocol:

```
checkpoint.sh  →  edit  →  verify.sh  →  keep or rollback.sh
```

| verify.sh exit | Meaning | Action |
|---|---|---|
| `0` | typecheck + tests green | Keep changes |
| `2` | typecheck failed | Rollback, show first error, offer 1 retry |
| `3` | tests failed | Rollback, show first failure, offer 1 retry |
| `4` | no test suite found | Switch to recommend-only — no code change |

Maximum **one** auto-retry. Never loops.

---

## When the skill suppresses (does NOT apply a pattern)

The skill has explicit suppression rules and will decline to apply a pattern
even when the smell is present. This is intentional.

| Situation | What the skill says |
|---|---|
| Strategy smell but only 2 cases | "Fewer than 3 cases — suppressed. Add a third variant before applying." |
| Factory smell but single construction | "Trivial single construction — Factory adds no value here." |
| Observer smell but single listener | "One consumer — direct call is correct. Observer suppressed." |
| Spring Boot project, hand-rolled DI requested | "Hilt/Spring owns DI here — hand-rolling suppressed. Use @Inject constructor." |
| Flutter project, hand-rolled Subject requested | "StreamController exists in pubspec — Observer suppressed. Use it instead." |

---

## Token cost (approximate)

| Mode | Tokens loaded | Notes |
|---|---|---|
| `suggest` | ~2,000 (SKILL.md only) | Inline detection rules — no pattern files loaded |
| `refactor` | ~4,000 (SKILL.md + 1 pattern + safety) | Loads only the matched pattern file |
| `compare` | ~5,000–7,000 (SKILL.md + rubric + 2–3 pattern files) | Loads only candidate pattern files |
| `follow` | ~4,000–6,000 (SKILL.md + 1–3 pattern files + safety) | Loads only detected conventions |
| `greenfield` | ~5,500 (SKILL.md + rubric + tdd + safety + 1 pattern) | Loads only selected pattern file |

Lazy loading means the skill never loads all 6 pattern files at once unless
every pattern scored smell-match > 0 in the detection pass (~once per million
invocations in practice).

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| "no safety net: add a test" | `verify.sh` exits 4 — no test suite found | Add at least one test; or ask for recommend-only mode |
| Skill won't refactor an untracked file | `checkpoint.sh` can't snapshot untracked files | Run `git add -N <file>` first |
| Skill says "baseline red" | Tests were already failing before refactor | Fix existing test failures first |
| Wrong language detected | No project marker in working directory | Run from the project root where `package.json` / `pubspec.yaml` / `Package.swift` lives |
| "ambiguous between Strategy and Factory" | Both patterns plausibly fit | Tell the skill which one you want, or ask for `compare` |
| Android project detected as generic Gradle | `AndroidManifest.xml` not at `app/src/main/` | Place manifest at the standard Android location |

---

## Cross-CLI compatibility

See [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md) for how to use pattern-surgeon
with Codex CLI, Cursor, Aider, Gemini CLI, and other AI coding tools.
