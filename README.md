# pattern-surgeon

Reactive design-pattern skill for Claude Code. Point it at a file; it recommends,
applies, and auto-reverts one of six patterns across nine language stacks.
Typecheck + tests must stay green — or the change is rolled back automatically.

```
"What pattern fits src/checkout.ts?"
"Refactor this pricing logic — it has a big if-else chain"
"Compare Strategy vs Factory for services/OrderService.kt"
"Implement notify(kind, msg) with the right pattern"
```

---

## Install

> **Note on Claude Code plugins:** The `/plugin` system is for MCP server plugins
> (tools), not skill files. Skills install directly into `~/.claude/skills/` — use
> any option below.

### Option 1 — npx (recommended, no install required)

```bash
npx @nuhin13/pattern-surgeon          # installs to ~/.claude/skills/
npx @nuhin13/pattern-surgeon --project # installs to .claude/skills/ (current project only)
```

Restart Claude Code after running. No Node.js project needed — works anywhere.

### Option 2 — npm global

```bash
npm install -g @nuhin13/pattern-surgeon
```

Installs automatically via postinstall hook to `~/.claude/skills/`.

### Option 3 — shell one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash
```

Project-local (commit to git so your team gets it):

```bash
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash -s -- --project
git add .claude/skills/pattern-surgeon && git commit -m "add pattern-surgeon skill"
```

### Option 4 — already in this repo (zero install for contributors)

When you clone this repo, `.claude/skills/pattern-surgeon` is a symlink to
`skills/pattern-surgeon/`. Claude Code picks it up automatically — no install step.

---

## Supported languages

| Web / Backend | Mobile |
|---|---|
| TypeScript / JavaScript | Kotlin (Android + Hilt + Room) |
| Python | Dart (Flutter + Riverpod + BLoC) |
| Java (Spring Boot, Maven, Gradle) | Swift (iOS + Combine + SwiftUI) |
| C# (.NET Core) | |
| PHP (Laravel) | |

Verification auto-detects the stack; the safety contract (checkpoint →
verify → rollback) is identical across all 9 stacks.

---

## Supported patterns

Strategy · Factory · Adapter · Repository · Observer · Dependency Injection

Each has: smell signature, when-NOT suppression rules, transform recipe,
code examples in all 9 languages, framework-specific idioms (Hilt, Room,
StateFlow, Riverpod, BLoC, Combine, SwiftUI, Spring, .NET, Eloquent).

---

## Five modes

| Mode | Say | Code changed? |
|---|---|---|
| `suggest` | "What pattern fits X?" | No |
| `refactor` | "Refactor X to a pattern" | Yes (verify-or-revert) |
| `compare` | "Compare A vs B for X" | No |
| `follow` | "Match existing patterns here" | Optional |
| `greenfield` | "Implement X with the right pattern" | Yes (TDD-first) |

---

## Safety contract

```
checkpoint.sh → edit → verify.sh → keep or rollback.sh
```

Every code-mutating mode: git snapshot → apply → typecheck + tests → keep or revert.
Maximum one auto-retry. Never loops.

---

## Uninstall

```bash
npx @nuhin13/pattern-surgeon remove           # global
npx @nuhin13/pattern-surgeon remove --project # project-local
```

---

## Cross-CLI compatibility

Designed for **Claude Code** (native skill format). The shell safety scripts
(`verify.sh`, `checkpoint.sh`, `rollback.sh`) and all pattern guides are
fully portable to Codex CLI, Cursor, Aider, Gemini CLI, and OpenCode.

**→ Adapter guide: [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md)**

---

## Dev

```bash
bats tests/scripts/   # run all 8 test suites
```

## Docs

- Usage & examples: [`USAGE.md`](USAGE.md)
- Cross-CLI: [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md)
