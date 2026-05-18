# strategy-suppress-ts

**Suppression fixture** — Strategy smell is present (same conditional at 2 call
sites, branches differ by algorithm) but the "When NOT to apply" guard fires:

> **Suppress when: fewer than 3 cases.**

Only 2 variants exist (`regular`, `vip`). Adding a Strategy interface + 2
classes + a dispatch map for a 2-branch binary adds more indirection than it
removes. The correct skill output is a **suppression recommendation**: state
the smell, state the when-NOT, and do NOT apply the pattern.

## What the skill must output
`suggest` / `compare`: "Strategy smell detected at 2 sites, but only 2 cases
— below the 3-case threshold. Suppressed. Leave as-is unless a third variant
is added."

`refactor`: same suppression message; no code change.
