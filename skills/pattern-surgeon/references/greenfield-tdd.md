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
   - exit 0 (already passes) → the behavior already exists; **reroute to refactor** mode, do not duplicate.
   - exit 4 (no test runner/target) → cannot establish a safety net; abort to recommend-only. Do not write unverifiable code.
   - exit 2 (typecheck) → fix the test until it compiles and is red, or abort.
5. Follow `safety-harness.md`: `checkpoint.sh`, then implement the
   pattern-correct code. Re-run `verify.sh` **after implementation**: exit 0
   = done (behavior verified). Post-implementation exit 2, 3, or 4 = the edit
   failed or destroyed the test net → `rollback.sh`, report the first failure,
   offer exactly one retry. (Exit 4 here is never acceptable: a green safety
   net existed pre-impl; if it is gone post-impl the code is unverifiable.)

## Per-language test runner cues

- TypeScript/JS — `vitest` (or the package.json `test` script).
- Python — `pytest`.
- Java — `JUnit` via `mvn -q test` / `gradle test`.
- C#/.NET — `xUnit` via `dotnet test`.
- PHP — `PHPUnit` (or `php artisan test` on Laravel).
- Kotlin/Android — `kotlin.test` via `./gradlew testDebugUnitTest`.
- Dart/Flutter — `package:test` via `dart test` / `flutter test`.
- Swift — `XCTest` via `swift test`.

A "failing test for not-yet-built behavior" asserts the intended public
contract of the pattern's entry point (e.g. `strategies[kind].price(base)`
returns the expected number) against a symbol that does not yet exist — it
fails to compile or import, which is the expected red.

## Boundary

`greenfield` never scans the repo. It works only at the user-named target
path. If the user asks to also match existing conventions there, that is the
`follow` mode, not this one.
