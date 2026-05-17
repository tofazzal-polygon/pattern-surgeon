---
name: pattern-surgeon
description: Use when the user names a TS/JS file or function and asks what design pattern fits, says the code is messy/has a big switch or conditional, or asks to refactor to a pattern. Recommends one of Strategy/Factory/Adapter/Repository/Observer/Dependency-Injection, applies it, and reverts unless typecheck and tests stay green.
---

# pattern-surgeon

## When to use
User points at a TS/JS scope (file/function/class) and asks what pattern fits,
says it is messy/has a big switch, or asks to refactor to a pattern. Reactive
only — never scan the whole repo unprompted.

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
