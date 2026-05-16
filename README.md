# pattern-surgeon

Reactive TS/JS design-pattern advisor skill. Point it at a scope; it recommends
a pattern (Strategy / Factory / Adapter / Repository / Observer / Dependency
Injection), applies the refactor, and keeps it only if `tsc --noEmit` + tests
stay green.

## Docs
- Spec: `docs/superpowers/specs/2026-05-17-pattern-surgeon-design.md`
- Plan: `docs/superpowers/plans/2026-05-17-pattern-surgeon.md`
