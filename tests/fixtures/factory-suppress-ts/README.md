# factory-suppress-ts

**Suppression fixture** — `new PgConn()` appears at exactly one call site with
no conditional branching. The Factory detection rule requires `new X()` of one
family in **≥ 3 places** with conditional/config selection.

> **Suppress when: trivial single construction.**

The correct skill output is a **suppression recommendation**: state why the
smell threshold is not met and do NOT apply Factory.

## What the skill must output
`suggest` / `compare`: "Only one construction site with no branching — Factory
threshold (≥ 3 conditional sites) not met. Suppressed."

`refactor`: same suppression message; no code change.
