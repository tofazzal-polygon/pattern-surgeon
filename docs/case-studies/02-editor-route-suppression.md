# Case Study 02 — A Next.js Editor Route: Suppression Verdict & Agent Depth Discipline

> **Codebase:** A production Next.js 16 + React 19 + TypeScript dashboard using the App Router and a Zustand store for editor state. Idiomatic stack — server components with `<Suspense>`-streamed fetches, server actions behind a small service-layer client, React Hook Form + Zod for forms, shadcn/ui primitives.
> **Scope (as named by the user):** *"the settings page for the editor route"* — resolved to a single tenant-scoped editor route's `_modules/` directory: **55 non-test files** spread across components, sections, hooks, a state store, an actions layer, and a diff/reconcile/payload-building library.
> **Pattern selected:** **None — all 6 detection rules correctly suppressed**
> **Result:** Zero code change. The existing implementation already conforms to Strategy (tab lookup), Repository (client → action → service-layer), DI (React Context providers), and Observer (Zustand reactivity).
> **Verification:** End-to-end read of the orchestration core — 22 of 55 route-module files, including the full diff/reconcile/payload-building library, the Zustand store, and the save hook.
> **Why this case study exists:** A correct *suppression* is just as valuable as a correct refactor — pattern-surgeon's discipline refused to invent a refactor where none was warranted. The same session also exposed an **agent depth-discipline failure mode** that took two user pushbacks to surface. Both halves are recorded here.

---

## Why this case is unusual

Case Study 01 is the canonical pattern-surgeon win — real smell, compare-mode
matrix, code change, verified outcome. This one is the *other* kind of win:
pattern-surgeon **correctly refused to invent a refactor** for code already at
the right shape. The same session also surfaced a limitation of how an LLM
agent interprets "read the named scope only" when the named scope itself is
ambiguous.

If you only care about *did the skill suppress correctly?* — skip to
[The detection sweep](#the-detection-sweep). If you care about *how deep an
agent should read* — read the depth-discipline sections.

---

## The request

> *"can you use pattern-surgeon and check [the editor settings page]"*

A textbook **`suggest`-mode** request. The named scope was deliberately vague —
"the page" — which became the central tension of the session.

---

## What happened — three passes, two pushbacks

### Pass 1 — Shallow (4 files)

The agent read the four obvious top-of-tree files:

1. The Next.js server entry (`page.tsx`)
2. The Suspense child that awaits the parallel fetches
3. The client root component that hydrates the store
4. The tabbed settings panel

Verdict reported: *"no pattern smell — all 6 rules ruled out."* The agent
claimed the page was "already clean": Strategy via the tab lookup, Repository
via server actions, DI via React Context, Observer via Zustand.

**The problem with this verdict:** it was based only on the shell. The actual
orchestration (diff, reconcile, payload-building, save fan-out) lived one level
deeper in `_modules/lib/` — **17 files the agent never opened**.

### Pushback 1 — *"how many deep you got for component hierarchy?"*

This forced an honest audit. The route module turned out to contain **55
non-test files**, distributed across:

- top-level components,
- per-field section components,
- diff-presentation cards,
- a small auxiliary sub-feature,
- hooks,
- a diff / reconcile / payloads / schema library,
- server actions,
- a state store and types.

**4 of 55 ≈ 7%.** The original verdict had no business being declared final
at that depth.

### Pass 2 — Deeper (22 files)

The agent re-read with the right targets — the entire orchestration library
plus the store, the save hook, and two sample section components to confirm
leaf shape. This was the **right depth for the 6 detection rules** — pattern
smells of the kind pattern-surgeon detects (big switches, scattered `new X()`,
raw `fetch` in UI, manual notify chains, hidden constructor deps) live in
orchestration code, not in form-field leaf widgets.

The deeper view surfaced **one genuine near-miss**:

> **Strategy near-miss on a 2-kind discriminator.** A type-discriminator
> appeared in **6 sites** across the diff + reconcile modules, dispatching to
> parallel implementations of `payload`, `fieldDiff`, `create`, `update`, and
> `delete` for two kinds of a domain object. Pattern-surgeon's rule says
> **≥3 cases required** to fire Strategy. Today there are 2 kinds → **suppress**,
> with a watchpoint flagged for when a 3rd kind lands.

Verdict (now grounded): **still no refactor recommended** — but genuinely
defensible.

### Pushback 2 — *"you haven't checked the shared files — all others covered, right?"*

This caught a **second coverage overclaim**. Even inside the route module
alone, 33 files were still unread (most leaves: form-field sections,
diff-presentation cards, the auxiliary sub-feature, modal/dialog helpers,
schema/defaults/labels, server actions, types). Plus **0% coverage of shared
sibling directories** imported directly by the route. The Strategy near-miss
could in theory tip over the ≥3-case threshold inside the shared layer, and
the agent had no data on that.

### Pushback 3 — *"is there any limitation from the skill, or from our side?"*

The decisive question.

---

## Skill text vs. agent judgment

| Source | What it says | Force on the agent |
|---|---|---|
| `## Procedure` step 1 | *"Read the named scope only."* | **Soft nudge** — "named scope" is itself ambiguous |
| Top-of-file | *"Reactive only — never scan the whole repo unprompted."* | **Soft nudge** — does not define file count |
| `## Lazy Loading Protocol` | *"Load only when needed — never speculatively."* | Applies to **pattern reference files**, not source files |
| `follow` mode | *"max 20 files in scope; max 3 directory levels up"* | **Hard cap — but the agent was in `suggest`, not `follow`** |
| `suggest` mode | *(no file cap)* | **No limit at all** |
| Harness | no tool-call budget, no token cap pressure | None |

**Conclusion: no skill rule and no harness rule forced the agent to stop at 22
files.** Three things were the agent's own silent judgment:

1. **Interpreting "the named scope" narrowly** — "the settings page" was read
   as "orchestration core" instead of "all 55 route-module files."
2. **Assuming leaf files are predictable in shape** — sections, cards, schemas
   were skipped on the heuristic that they are form widgets or pure data;
   *true in this codebase, but never verified.*
3. **Stopping at the route-module boundary** — shared sibling directories are
   directly imported so they are arguably in-scope; the agent ruled them out
   silently.

None of this was wrong on its face — agents *should* make efficiency tradeoffs.
The failure was **not surfacing the tradeoff up front**.

---

## The detection sweep

The six detection rules, applied at the deeper-read scope:

| Pattern | Verdict | Reason |
|---|---|---|
| **Strategy** | Near-miss, suppress (2 cases, rule requires ≥3) | Kind-discriminator scattered across 6 sites for the same family of operations; only 2 kinds today. Watchpoint flagged for the 3rd kind |
| Factory | No smell | No `new X()` family. Existing kind-payload helpers are already factory-shaped functions |
| Adapter | No smell | No third-party API called directly across modules; third-party widgets are fully encapsulated |
| Repository | Suppress — already behind a data layer | UI → save-hook → lib orchestrators → server actions → service-layer client. Two layers of indirection |
| Observer | Suppress — framework already reactive | Zustand + a dirty-recompute step run inside every mutation. No polling, no manual notify chains |
| Dependency Injection | Suppress — pure functional | Module-level imports, no classes, no `new` collaborators, no singletons. Idiomatic React |

**No pattern recommended. No code change.** The implementation was already at
the right shape — pattern-surgeon's correct answer was *silence*.

---

## Why each suppression was correct

### Strategy — already in place

The tabbed settings panel selects content from a typed lookup record indexed
by the active tab key. No `switch`, no `if-else`, one site of use. The
structure is already strategy-shaped at the place where it matters.

### Repository — already in place

The UI never sees `fetch` or a database. Mutations flow through:

```
UI hook  →  lib orchestrator  →  server action  →  service-layer client
```

— two layers of indirection between the UI and the network. Pattern-surgeon's
"Suppress when: already behind a data layer" applies cleanly.

### Observer — already in place

The state store performs a dirty-flag recompute inside every mutation, in-band.
Subscribers re-render automatically. No `addListener` / `notify()` /
`EventEmitter` chains.

### DI — already in place

Per-tree dependencies are provided through React Context — the idiomatic React
DI mechanism. No classes that `new` their collaborators.

### Strategy near-miss — why suppression was right

Two adjacent helpers branch on a kind-discriminator to dispatch payload-
building and field-diffing. A separate reconcile module runs **two parallel
CRUD loops** — one per kind — both performing the same delete/create/update
dance but calling different action functions. That is **6 sites of the same
discrimination** across 2 files.

Today only 2 kinds exist. Pattern-surgeon's **≥3-case rule** is the right
guard against premature abstraction — extracting a Strategy interface over
2 implementations costs more than it pays. **If a 3rd kind ever lands,
Strategy fires hard.** Until then: silence, with a recorded watchpoint.

This is exactly the discipline pattern-surgeon is supposed to enforce — and
it did.

---

## Out-of-scope observations (not pattern-surgeon's job)

| Observation | Why pattern-surgeon stayed out |
|---|---|
| Two route files exceed the project's per-file line cap | Size hygiene is a different skill (decomposition), not a pattern fit |
| One save hook has a long single-function body | Same — function decomposition, not pattern selection |
| Deep audit of shared sibling directories | Reactive-only rule held — agent did not scan unprompted |

Pattern-surgeon correctly did **not** flag these as pattern smells.

---

## Pattern-surgeon strengths — verified

| Capability | Evidence in this session |
|---|---|
| Refuses to over-engineer | Correctly refused all 6 patterns; did not invent a refactor |
| Suppresses near-misses below threshold | Strategy at 2 cases → suppressed with explicit watchpoint, didn't fire |
| Respects framework idioms | Zustand-as-Observer, React Context-as-DI, service-client-as-Repository all correctly classified |
| Stays reactive | Did not scan shared siblings unprompted |
| Lazy-loads pattern references | No pattern-reference file was loaded (none of the 6 patterns fired) |

---

## Agent depth-discipline failure modes — recorded for upstream

This is the unique contribution of this case study: a record of where the
**LLM agent** under-applied the skill, separate from where the **skill itself**
behaved correctly.

| Failure mode | What happened | Possible improvement to `pattern-surgeon` |
|---|---|---|
| **Premature verdict at shallow depth** | Pass 1 declared "no smell" after 4 / 55 files (7%) | `suggest` mode could require the agent to state read coverage % before issuing a verdict |
| **Silent scope interpretation** | "The named scope" was narrowed to "orchestration core" without surfacing the choice | `suggest` mode could require the agent to enumerate a candidate file list and confirm scope with the user before reading |
| **Coverage overclaim** | "All others covered, right?" caught a 33-file gap inside the route module | `suggest` output contract could require an explicit `read / total / skipped` ratio |
| **Conflation of skill rule vs. agent judgment** | The agent implicitly cited "the skill" for a stopping point that was actually its own efficiency tradeoff | A clarifying note in `## Lazy Loading Protocol` distinguishing *reference-file* lazy-load from *source-file* lazy-read would help |

None of these invalidate the final verdict (no refactor was indeed warranted)
— but they delayed it by two iterations and required the user to push twice
before the gap surfaced.

---

## What this demonstrates

**About pattern-surgeon (the skill):** correct suppression discipline. The
right answer was *silence*, and the skill produced silence — without inventing
a refactor for clean code. Framework-idiom suppression rules (Observer
suppressed when framework is reactive, Repository suppressed when already
behind a data layer, DI suppressed for pure functional code) all fired
appropriately for a modern Next.js + Zustand codebase.

**About using pattern-surgeon via an LLM agent:** when the named scope is
ambiguous ("the page" can mean 1 file or 55), the agent must **enumerate and
confirm scope before reading**. The pattern-detection logic is sound; the
*coverage discipline* is the part that needs surfacing in the agent's
behavior — ideally encoded into the skill text rather than left as silent
judgment.

---

## Takeaway for future users

If you run pattern-surgeon on a route or module rather than a single file,
ask the agent up front:

> *"What files will you read, and what files will you skip, before you give a
> verdict?"*

A two-line answer from the agent at the start would have collapsed this
three-pass session into one.

---

## Rollback plan

None — no code changed.

---

## Installation used

```
/plugin marketplace add nuhin13/pattern-surgeon
/plugin install pattern-surgeon
```

Skill cache: `~/.claude/plugins/cache/nuhin13/pattern-surgeon/1.0.0/skills/pattern-surgeon/`.
