<div align="center">

# pattern-surgeon

**Point it at a file. Get a scored decision. Auto-revert if tests fail.**

Native for **Claude Code** · Compatible with Codex CLI · Aider · Gemini CLI · Cursor · Windsurf · Continue

[![npm version](https://img.shields.io/npm/v/@nuhin13/pattern-surgeon?color=crimson)](https://www.npmjs.com/package/@nuhin13/pattern-surgeon)
[![license](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)
[![claude-code](https://img.shields.io/badge/claude--code-plugin-5B21D8)](https://github.com/nuhin13/pattern-surgeon)
[![languages](https://img.shields.io/badge/languages-9-orange)](https://github.com/nuhin13/pattern-surgeon)
[![patterns](https://img.shields.io/badge/patterns-6-blue)](https://github.com/nuhin13/pattern-surgeon)

</div>

---

```
"What pattern fits src/checkout.ts?"
"Refactor this pricing logic — it has a big if-else chain"
"Compare Strategy vs Factory for services/OrderService.kt"
"Implement notify(kind, msg) with the right pattern"
```

**See it on real code →** [Case studies](docs/case-studies/) — production refactors with scoring matrices, before/after diffs, and verification.

---

## Trust & Transparency

> This section exists specifically because Claude Code shows a trust warning
> on every plugin install. You should read it before installing anything.

### What this skill is

A **skill** (a plain Markdown file) that gives Claude Code structured instructions
for recommending and applying design patterns. There is no compiled code, no binary,
no MCP server, and no background process.

### What it can access

The `allowed-tools` in [`skills/pattern-surgeon/SKILL.md`](skills/pattern-surgeon/SKILL.md)
are declared explicitly:

```yaml
allowed-tools: Bash Read
```

| Tool | What it does in this skill |
|---|---|
| `Read` | Reads the file or function you explicitly point it at |
| `Bash` | Runs `verify.sh`, `checkpoint.sh`, `rollback.sh` — the safety scripts in this repo |

### What it never does

- Never reads files you did not name
- Never scans your repo unprompted ("reactive only" — stated in the description frontmatter)
- Never makes network requests
- Never writes to files without first creating a git checkpoint and asking for confirmation
- Never keeps a change if typecheck or tests fail

### What the safety scripts do

You can read every line — they are plain bash:

| Script | Source | What it does |
|---|---|---|
| [`scripts/verify.sh`](skills/pattern-surgeon/scripts/verify.sh) | This repo | Detects language stack, runs typecheck + test suite, exits 0/2/3/4 |
| [`scripts/checkpoint.sh`](skills/pattern-surgeon/scripts/checkpoint.sh) | This repo | Captures current git HEAD SHA before any edit |
| [`scripts/rollback.sh`](skills/pattern-surgeon/scripts/rollback.sh) | This repo | Resets to captured SHA if verify fails |

### Verify yourself

```bash
git clone https://github.com/nuhin13/pattern-surgeon
cat skills/pattern-surgeon/SKILL.md          # the full skill instructions
cat skills/pattern-surgeon/scripts/verify.sh # the verification script
bats tests/scripts/                          # run all 8 test suites
```

---

## Real-world accuracy

Want proof this isn't a toy? Read [`docs/case-studies/`](docs/case-studies/) — real
production refactors driven by the skill, with the full compare-mode scoring
matrix (including which patterns were **rejected** and why), before/after code,
LOC delta, and verification steps.

Current case studies:
- [**01 — Interview microservice (Python / FastAPI / gRPC)**](docs/case-studies/01-interview-module-strategy.md) — Strategy pattern (compare-mode 9/10). Replaced a 3-branch if/elif quality router + baked-in heuristic evaluator with a Protocol + Enum + Strategy registry. Public API unchanged. ~-20 LOC net. LLM-evaluator swap reduced to 1 line at composition root. Skill explicitly rejected Factory (7/10), Repository (6/10), and DI (5/10) with stated reasons.

---

## Install

### Option 1 — Claude Code plugin

In a Claude Code session, run these two commands:

```
/plugin marketplace add nuhin13/pattern-surgeon
/plugin install pattern-surgeon
```

The skill activates automatically from its description — no slash command needed.

**Update:**
```
/plugin update pattern-surgeon
```

**Uninstall:**
```
/plugin remove pattern-surgeon
```

### Option 2 — npx (no Node project required)

```bash
npx @nuhin13/pattern-surgeon           # installs to ~/.claude/skills/
npx @nuhin13/pattern-surgeon --project # installs to .claude/skills/ (current project only)
```

```bash
npx @nuhin13/pattern-surgeon remove           # uninstall global
npx @nuhin13/pattern-surgeon remove --project # uninstall project-local
```

### Option 3 — npm global

```bash
npm install -g @nuhin13/pattern-surgeon
```

### Option 4 — shell one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash
```

Project-local (commit to git so your team gets it):

```bash
curl -fsSL https://raw.githubusercontent.com/nuhin13/pattern-surgeon/main/install.sh | bash -s -- --project
git add .claude/skills/pattern-surgeon && git commit -m "add pattern-surgeon skill"
```

### Option 5 — clone (zero install for contributors)

```bash
git clone https://github.com/nuhin13/pattern-surgeon
```

`.claude/skills/pattern-surgeon` is already a symlink to `skills/pattern-surgeon/`.
Claude Code picks it up automatically — no install step.

---

## Supported languages

| Web / Backend | Mobile |
|---|---|
| TypeScript / JavaScript | Kotlin (Android + Hilt + Room) |
| Python | Dart (Flutter + Riverpod + BLoC) |
| Java (Spring Boot, Maven, Gradle) | Swift (iOS + Combine + SwiftUI) |
| C# (.NET Core) | |
| PHP (Laravel) | |

Language is auto-detected from the nearest project marker (`package.json`,
`pubspec.yaml`, `AndroidManifest.xml`, `Package.swift`, etc.).

---

## Supported patterns

Strategy · Factory · Adapter · Repository · Observer · Dependency Injection

Each pattern has: smell detection rules, when-NOT suppression rules, transform
recipe, code examples in all 9 languages, and framework-specific idioms
(Hilt, Room, StateFlow, Riverpod, BLoC, Combine, SwiftUI, Spring, .NET, Eloquent).

Pattern reference files: [`skills/pattern-surgeon/references/patterns/`](skills/pattern-surgeon/references/patterns/)

---

## Five modes

| Mode | Trigger | Code changed? |
|---|---|---|
| `suggest` | "What pattern fits X?" | No |
| `refactor` | "Refactor X to a pattern" | Yes — verify-or-revert |
| `compare` | "Compare A vs B for X" | No |
| `follow` | "Match existing patterns here" | Optional |
| `greenfield` | "Implement X with the right pattern" | Yes — TDD-first |

---

## Safety contract

```
checkpoint.sh → edit → verify.sh → keep or rollback.sh
```

Every code-mutating mode takes a git snapshot before touching anything.
If typecheck or tests fail after the edit, `rollback.sh` reverts to the snapshot.
Maximum one auto-retry. Never loops.

| verify.sh exit | Meaning | Action |
|---|---|---|
| `0` | All green | Keep changes |
| `2` | Typecheck failed | Rollback + show error + 1 retry |
| `3` | Tests failed | Rollback + show failure + 1 retry |
| `4` | No test suite | Switch to recommend-only, no code change |

---

## Repository layout

```
skills/pattern-surgeon/      ← the skill itself
  SKILL.md                   ← full instructions + allowed-tools declaration
  scripts/                   ← verify.sh, checkpoint.sh, rollback.sh
  references/                ← pattern guides, rubric, TDD loop doc
    patterns/                ← one .md per pattern (6 files)
.claude-plugin/              ← Claude Code plugin manifest
  plugin.json
  marketplace.json
tests/                       ← BATS test suites (8 suites, 40+ tests)
  fixtures/                  ← language fixtures for each test scenario
docs/
  CROSS-CLI.md               ← using the skill from Codex/Aider/Cursor/etc.
  case-studies/              ← real refactors driven by the skill
```

---

## Dev & contributing

```bash
git clone https://github.com/nuhin13/pattern-surgeon
bats tests/scripts/   # run all 8 test suites — must pass before any PR
```

All pattern reference files, skill instructions, and safety scripts are plain
Markdown and bash — readable and auditable by anyone.

Have you used pattern-surgeon on a real refactor? Open a PR to add a case study
under [`docs/case-studies/`](docs/case-studies/). Format guide is in that
folder's README.

---

## Docs

- Full usage guide with worked examples: [`USAGE.md`](USAGE.md)
- Cross-CLI (Codex, Cursor, Aider, Gemini, Windsurf, Continue): [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md)
- Case studies (real production refactors): [`docs/case-studies/`](docs/case-studies/)
