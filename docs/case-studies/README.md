# Case Studies

Real refactors driven by pattern-surgeon. Each entry shows:
- **The problem** — what code smell triggered the request
- **The decision** — which pattern was picked and why, including which alternatives were rejected
- **The change** — before/after code, LOC delta, verification steps
- **The outcome** — what was unblocked, what was deferred, rollback plan

The goal of this folder is to show pattern-surgeon's **accuracy and discipline on
production code**, not toy examples. Every case study is from a real codebase where
the recommendation was applied and verified.

---

## Index

| # | Case | Pattern | Scope | LOC delta |
|---|---|---|---|---|
| 01 | [Interview microservice — adaptive routing](./01-interview-module-strategy.md) | Strategy (9/10) | Python / FastAPI / gRPC | -20 net |
| 02 | [A Next.js editor route — suppression verdict & depth discipline](./02-editor-route-suppression.md) | None (all 6 suppressed) | TypeScript / Next.js 16 / React 19 / Zustand | 0 (no change) |
---

## What makes a good case study here

To be included, a refactor must:

1. **Come from a real codebase**, not a tutorial repo.
2. **Show the compare-mode scoring matrix** — not just "we picked X" but the scores
   for every candidate the skill considered, with the suppression cases explicitly
   ruled out.
3. **Include before/after code snippets** from the actual files.
4. **State what was deferred and why** — the skill's discipline is "never two
   patterns in one pass," and case studies should reflect that.
5. **Show verification steps** — type checks, tests, smoke tests, behavioral parity.

If you've used pattern-surgeon on a non-trivial refactor and want to contribute a
case study, open a PR with a new numbered file in this folder following the same
structure as the existing entries.
