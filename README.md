# pattern-surgeon

Reactive, multi-language design-pattern skill. Point it at a code scope; it
runs one of five modes — `suggest`, `refactor`, `compare`, `follow`,
`greenfield` — over Strategy, Factory, Adapter, Repository, Observer,
Dependency Injection. Code-mutating modes keep changes only if the detected
stack's typecheck + tests stay green (verify-or-revert); `greenfield` is
TDD-first. Reactive only — never scans the repo unprompted.

## Quick start

```bash
git clone https://github.com/nuhin13/pattern-surgeon
ln -s "$PWD/pattern-surgeon/skills/pattern-surgeon" \
      ~/.claude/skills/pattern-surgeon
```

Then just talk to Claude: `"What pattern fits src/checkout.ts?"` or
`"Refactor this pricing logic — it's a mess of if-elses."`

**→ Full usage guide with worked examples: [`USAGE.md`](USAGE.md)**

## Languages

| Web / Backend | Mobile |
|---|---|
| TypeScript / JavaScript | Kotlin (Android) |
| Python | Dart (Flutter) |
| Java (Spring Boot, Maven, Gradle) | Swift (iOS / SPM) |
| C# (.NET Core) | |
| PHP (Laravel) | |

Verification auto-detects the stack; the safety contract (checkpoint →
verify → rollback) is identical across all 9 stacks.

## Patterns

Strategy · Factory · Adapter · Repository · Observer · Dependency Injection

Each has: smell signature, when-NOT suppression rules, transform recipe,
code examples in all 8 languages, framework-specific idioms (Hilt, Room,
StateFlow, Riverpod, BLoC, Combine, SwiftUI, Spring, .NET, Eloquent).

## Cross-CLI compatibility

Designed for **Claude Code** (native skill format). The shell safety scripts
(`verify.sh`, `checkpoint.sh`, `rollback.sh`) and all pattern guides are
fully portable to Codex CLI, Cursor, Aider, Gemini CLI, and OpenCode.

**→ Adapter guide: [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md)**

## Dev

```bash
bats tests/scripts/   # run all 8 test suites
```

## Docs

- Usage & examples: [`USAGE.md`](USAGE.md)
- Cross-CLI: [`docs/CROSS-CLI.md`](docs/CROSS-CLI.md)
- Marketing: [`docs/MARKETING.md`](docs/MARKETING.md)
- Specs: `docs/superpowers/specs/`
- Plans: `docs/superpowers/plans/`
