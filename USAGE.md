# pattern-surgeon — Usage Guide

> Reactive, polyglot design-pattern skill for Claude Code. Points at a file,
> applies one of six patterns, verifies with your test suite, and auto-reverts
> on failure. Never touches code you didn't ask about.

---

## Install

### Option 1 — Claude Code plugin (recommended, one command)

In a Claude Code session type:

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

### Option 2 — npx (no install required)

```bash
# Global — use in any project
npx @nuhin13/pattern-surgeon

# Project-local — current project only, committable to git
npx @nuhin13/pattern-surgeon --project
```

After running, restart Claude Code (or open a new session).

**Help:**
```bash
npx @nuhin13/pattern-surgeon --help
```

**Uninstall:**
```bash
npx @nuhin13/pattern-surgeon remove
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
| Plugin | Managed by `/plugin` command | Where plugin is enabled |

---

## Supported languages

| Language | Detection marker | Typecheck | Tests |
|---|---|---|---|
| TypeScript / JS | `package.json` + `tsconfig.json` | `tsc --noEmit` | `npm/yarn/pnpm test` |
| Python | `pyproject.toml` / `setup.py` / `requirements.txt` | `mypy .` | `pytest` |
| Java (Maven) | `pom.xml` | `mvn -q compile` | `mvn -q test` |
| Java (Gradle) | `build.gradle` / `build.gradle.kts` | `./gradlew compileJava` | `./gradlew test` |
| C# / .NET | `*.csproj` / `*.sln` | `dotnet build` | `dotnet test` |
| PHP / Laravel | `composer.json` | phpstan (if installed) | `php artisan test` / phpunit |
| Kotlin / Android | `app/src/main/AndroidManifest.xml` | `./gradlew compileDebugKotlin` | `./gradlew testDebugUnitTest` |
| Dart / Flutter | `pubspec.yaml` | `dart analyze` / `flutter analyze` | `dart test` / `flutter test` |
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

```
"What pattern fits src/checkout.ts?"
"Is there a pattern for this pricing function?"
"What would you recommend for services/OrderService.kt?"
```

**Example output:**

```
Recommendation: Strategy

Why: price() and discountedTotal() both switch on `kind` with identical
branch structure — textbook Strategy smell at 2 sites.

Tradeoff: adds one interface + N classes; worthwhile because a 3rd variant
("corporate") only requires a new class, not editing both functions.

When-NOT ruled out: ≥ 3 cases present; branches differ only by algorithm.

No code changed. Say "apply it" to refactor, or "compare" to see alternatives.
```

---

### 2. `refactor` — apply pattern with safety net

```
"Refactor src/checkout.ts — it's a mess of if/elses"
"Apply Strategy to the pricing logic in Pricing.kt"
"This switch is getting unmanageable — fix it"
```

**What happens:**

```
1. Reads named scope only (not the whole repo)
2. Matches against detection rules
3. Loads the matched pattern's Transform recipe
4. Asks you to confirm if two patterns are plausible
5. On your OK:
   a. checkpoint.sh → git snapshot
   b. Applies edits
   c. verify.sh → typecheck + tests
      Exit 0  → "Refactored. Behavior preserved."
      Exit 2/3 → rollback.sh, shows rejected diff + first failure,
                 offers EXACTLY ONE retry
      Exit 4  → no test suite → switches to recommend-only
```

**Success output:**
```
Refactored: Strategy applied to src/checkout.ts

Changed files:
  src/checkout.ts — replaced 2 conditional sites with strategies[] dispatch
  src/strategies/PricingStrategy.ts — new interface

Verify: tsc ✓  npm test ✓ (12 tests, 0 failed)
Behavior preserved.
```

---

### 3. `compare` — scoring matrix

```
"Compare Strategy vs Factory for src/UserService.kt"
"Which pattern — Repository or Adapter — for this data layer?"
"Why would I use Strategy over DI here?"
```

**Example output:**

```
| Pattern  | Why fits             | smell | local | revers | fw | indir | total | verdict    |
|----------|----------------------|-------|-------|--------|----|-------|-------|------------|
| Strategy | switch at 3 sites    | 2     | 2     | 2      | 1  | 2     | 9     | strong fit |
| Factory  | new X() at 3 sites   | 1     | 1     | 2      | 1  | 1     | 6     | partial    |

Recommendation: Strategy — eliminates the duplicated algorithm switch at all
3 sites. Factory would only relocate construction.
```

---

### 4. `follow` — match existing conventions

```
"Make src/payments.dart consistent with existing patterns in src/"
"Match the style in services/ for this new handler"
```

Scope: named file + siblings + nearest recognized layer directory
(`services/`, `repositories/`, `blocs/`, `viewmodels/`, etc.). Max 20 files.

---

### 5. `greenfield` — TDD-first implementation

```
"Implement notify(kind, msg) with the right pattern in src/notifications.ts"
"Add a payment processing feature using the best pattern"
```

Writes a failing test first (verify exit 3), then implements to green.
If the behavior already exists (exit 0), reroutes to `refactor`.

---

## Safety contract

| verify.sh exit | Meaning | Action |
|---|---|---|
| `0` | typecheck + tests green | Keep changes |
| `2` | typecheck failed | Rollback + show error + 1 retry |
| `3` | tests failed | Rollback + show failure + 1 retry |
| `4` | no test suite | Switch to recommend-only |

Maximum **one** auto-retry. Never loops.

---

## When the skill suppresses

The skill declines to apply a pattern even when the smell is present:

| Situation | Output |
|---|---|
| Strategy smell, only 2 cases | "Fewer than 3 cases — suppressed." |
| Factory smell, single construction site | "Trivial single construction — suppressed." |
| Observer smell, single listener | "One consumer — direct call is correct. Suppressed." |
| Spring Boot + hand-rolled DI | "Hilt/Spring owns DI — use @Inject constructor instead." |
| Flutter + hand-rolled Subject | "StreamController in pubspec — use it instead." |

---

## Token cost

| Mode | Tokens | Notes |
|---|---|---|
| `suggest` | ~2,000 | Inline detection rules only — no pattern files loaded |
| `refactor` | ~4,000 | Matched pattern file only |
| `compare` | ~5,000–7,000 | Rubric + candidate pattern files only |
| `follow` | ~4,000–6,000 | Detected convention files only |
| `greenfield` | ~5,500 | Rubric + tdd + selected pattern file |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "no safety net: add a test" | Add at least one test, or ask for recommend-only |
| Skill won't refactor untracked file | Run `git add -N <file>` first |
| "baseline red" | Fix existing test failures first |
| Wrong language detected | Run from project root (where `package.json` / `pubspec.yaml` / `Package.swift` lives) |
| "ambiguous between Strategy and Factory" | Tell the skill which one, or ask for `compare` |
| Android detected as generic Gradle | Ensure `AndroidManifest.xml` is at `app/src/main/` |

---

## Cross-CLI compatibility

→ [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md) — adapters for Codex CLI, Cursor, Aider, Gemini CLI.
