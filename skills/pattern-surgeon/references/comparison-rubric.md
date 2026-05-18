# Comparison Rubric

Used by the `compare` mode. Makes pattern comparison deterministic instead of
subjective. Score each plausible candidate against the same axes, render the
matrix, then apply the tie-break order.

## Scoring axes

Score each axis `2` / `1` / `0`.

- **smell-match strength** — how exactly the named scope exhibits this
  pattern's detection rule (2 = textbook smell, 1 = near-miss, 0 = absent).
- **change locality** — how few sites change to apply it (2 = the named scope
  only, 1 = scope + direct callers, 0 = cross-module).
- **reversibility** — how cleanly it can be reverted (2 = pure restructure,
  1 = adds a seam, 0 = changes public surface).
- **framework-idiom conflict** — 2 = matches the detected framework idiom,
  1 = neutral, 0 = fights the framework (e.g. hand-rolled DI in Spring).
- **added-indirection cost** — 2 = removes duplication net-negative cost,
  1 = neutral, 0 = adds indirection with thin payoff.

## Verdict scale

Map the axis total (0–10) to a verdict. **Apply the tiers in this order; the
first match wins:**

1. `wrong tool here` — total ≤ 3, OR smell-match = 0, OR framework-idiom
   conflict = 0.
2. `strong fit` — total ≥ 8 AND smell-match = 2.
3. `partial` — anything else (total 4–7, or smell-match = 1 without a
   `wrong tool here` trigger).

## Recommendation and tie-break

Recommend the highest-scoring `strong fit`. State one line on why it beats the
runner-up.

**Tie-break order** (apply when top two totals are equal):

1. Lower added-indirection cost wins (higher indir score wins).
2. Then higher framework-idiom conflict score (better idiom fit) wins.
3. Then fewer touched files (higher change-locality score) wins.
4. Still tied → state the tie and ASK the user to pick.

## Worked example

Scope: a function with a typed `switch` that both branches on `kind` AND
`new`s a different collaborator per branch, across 3 call sites.

| pattern | why-fits-here | tradeoff | when-NOT ruled | smell | local | revers | fw | indir | total | verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| Strategy | switch on type ≥2 sites, branches differ by algorithm | one class per branch | not <3 cases, no shared heavy state | 2 | 2 | 2 | 1 | 2 | 9 | strong fit |
| Factory | a family is constructed conditionally | indirection if construction is trivial | construction is non-trivial here | 1 | 1 | 2 | 1 | 1 | 6 | partial |

Recommendation: **Strategy** — it removes the duplicated algorithm switch at
all 3 sites; Factory would only relocate the construction, leaving the
algorithm branching in place.
