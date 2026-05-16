# pattern-surgeon — Design Spec

**Date:** 2026-05-17
**Status:** Approved (design); pending implementation plan
**Skill name:** `pattern-surgeon` (invocable as `/pattern-surgeon`)

## Problem

The open-source AI-skill ecosystem broadly covers frontend, backend, language
specialists, Figma, refactoring, and code-duplication. The clearest unfilled
gap: a skill that **recommends a design pattern from real code context and then
implements the refactor with verification**. Existing skills only detect SOLID
violations or describe patterns as prose — none safely apply a pattern and
prove the code still works.

## Goals

- Reactive, user-pointed: user names a file/function/scope.
- TypeScript/JavaScript first. Architecture must extend to other languages by
  swapping the typecheck/test command only.
- Recommend → auto-refactor → verify-or-revert.
- Cover a curated, high-ROI set of 6 patterns.
- Safe on legacy/untested code: never silently break an unverifiable codebase.

## Non-Goals

- No full Gang-of-Four 23-pattern catalog (dilutes quality).
- No proactive whole-repo scanning in v1.
- No per-pattern AST transform scripts (brittle; rejected approach B).
- No multi-pattern application in a single pass.

## Approach

**Hybrid: LLM transform + deterministic safety harness.** The LLM performs the
semantic refactor (its strength). The skill mandates a harness that proves
correctness (`git` checkpoint → apply → typecheck + tests → auto-revert on
red). Engineering effort goes into the verification gate, not fragile
per-pattern AST code. This borrows the `drywall` lesson: verify cheaply with
deterministic tooling instead of trusting the prompt.

## Architecture

```
SKILL.md                       advisor brain: when/how to recommend
references/
  patterns/
    strategy.md
    factory.md
    adapter.md
    repository.md
    observer.md
    dependency-injection.md     each: smell, when-NOT, recipe, before/after, pitfalls
  safety-harness.md             verify-or-revert protocol
scripts/
  checkpoint.sh                 git stash-create snapshot (no commit pollution)
  verify.sh                     detect pkg mgr → tsc --noEmit → test cmd → exit code
  rollback.sh                   restore checkpoint, emit rejected diff
```

### Flow

1. User names a scope.
2. Advisor reads scope, matches against the 6 smell signatures.
3. Confirm smell **and** check when-NOT. If ambiguous, ask user before editing.
4. State pattern + why + tradeoff + when-NOT.
5. On user OK: `checkpoint` → apply edits → `verify`.
6. Green → keep + summary. Red → `rollback` + show what broke + offer one
   retry (max one; never loop).

## Detection Rules (full set)

| Pattern | Fire when | Suppress when |
|---|---|---|
| Strategy | Same switch/if-else on a type/enum/string repeated ≥2 sites; branches differ only by algorithm | Single use site; branches share heavy state; <3 cases |
| Factory | `new X()` of one family scattered ≥3 places; construction needs conditional/config | Trivial single construction; DI container already owns it |
| Adapter | 3rd-party API called directly across many modules; signature mismatch with domain | Used in 1 place; lib already matches domain shape |
| Repository | Raw ORM/SQL/fetch data access inline in service/UI/business logic | Already behind a data layer; one-off script |
| Observer | Manual cross-object notify chains, callback fan-out, polling for state change | Single listener; framework already reactive (RxJS/signals) |
| Dependency Injection | `new` of collaborators inside class, hard-coded singletons, hidden deps blocking tests | Pure functions; value objects; leaf utilities |

Rule order: detect → confirm smell AND when-NOT → ambiguous? ask → never apply
two patterns in one pass.

## Per-Pattern Reference Format

Every `references/patterns/*.md` uses a fixed schema:

```
# <Pattern>
## Smell signature      exact triggers, code examples
## When NOT to apply    suppression cases — first-class section
## Transform recipe     ordered steps the LLM follows
## Before / After       minimal TS example
## Verification focus    what could break — guides the harness
## Pitfalls             over-abstraction warnings
```

`When NOT to apply` is mandatory and prominent: over-application is the primary
failure mode of existing pattern tooling.

## Verify-Harness Contract

- `checkpoint.sh` — `git stash create` snapshot; no commits, no branch
  pollution; abort if working tree state is ambiguous.
- `verify.sh` — autodetect pkg mgr (pnpm/yarn/npm) → `tsc --noEmit` → run the
  `test` script from package.json. Typecheck red OR tests red = fail. Print
  first failure only.
- `rollback.sh` — restore checkpoint; output the rejected diff so the user sees
  the attempted change.
- Hard rule in SKILL.md: no edit kept without a green verify. One auto-retry
  max, then stop and report. Never loop.

## Legacy / Old-Project Handling (while skill active)

1. **Probe first** — run `verify.sh` before touching. If the baseline is
   already red (no tests, tsc errors), do NOT auto-refactor; switch to
   recommend-only and report "no safety net."
2. **No test script** — offer to scaffold a characterization test around the
   scope first, then refactor. User opts in.
3. **Incremental** — large legacy smell → smallest viable slice, one pattern,
   one scope; remaining opportunities listed as a deferred checklist.
4. **Respect conventions** — refactor toward the codebase's idiom, not a
   textbook ideal.

## Testing the Skill

Per `superpowers:writing-skills`: fixture TS projects, one per pattern, with
the smell present and passing tests. Eval asserts the skill:

- detects the correct pattern,
- applies the refactor,
- keeps tests green,
- correctly refuses on when-NOT fixtures and on a baseline-red fixture.

## Extensibility

Other languages: add a language branch in `verify.sh` (typecheck + test
command) and language-specific code examples in the pattern references. The
advisor brain, detection rules, and harness contract stay unchanged.
