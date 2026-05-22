# Case Study 01 — Interview Microservice: Strategy Refactor

> **Codebase:** AI Coach (mock-interview SaaS)
> **Scope:** `backend/interview-module/app/`
> **Pattern selected:** Strategy (compare-mode score 9/10, strong fit)
> **Result:** -20 net LOC, 3-branch if/elif eliminated, type-safe enum replaces magic strings, LLM-evaluator swap reduced to 1 line at composition root.
> **Verification:** Full lifecycle smoke test (start → submit × N → end) — behavior preserved end-to-end.

---

## The feature

AI Coach lets a learner run a **mock job interview** end-to-end against an AI
interviewer. The interview-module is a separate microservice (FastAPI on
`:8001`, gRPC on `:50051`, SQLite) that owns the interview state machine.

### One interview, step by step

1. **Start** — learner picks role/level/interview_type. Module builds a
   multi-round question plan (junior = 1 round × 3, senior = 2 rounds × 5).
2. **Submit answer** — learner sends transcribed text. Module:
   - Runs the **answer evaluator** — scores technical depth, grammar, clarity, tone.
   - Classifies the answer's **quality** — incomplete / incorrect / normal / strong.
   - Routes the **next question** based on quality:
     - `incomplete` → clarification follow-up on same question
     - `incorrect` → corrective follow-up on same question
     - `strong` → harder difficulty follow-up
     - `normal` → advance with a progress prompt
3. **End** — aggregates scores, picks a verdict (Hire / Borderline / No Hire),
   returns a 6-8 line report.

### Why the follow-up routing is the heart of the feature

A static question list = a quiz. The follow-up routing on answer quality is what
turns it into an **adaptive conversation** — the AI pushes back when the answer
is weak, digs deeper when it's strong. Everything else (CRUD, state machine,
scoring aggregation) supports this loop.

---

## The problem — smells pattern-surgeon detected

| Smell | Where | Cost |
|---|---|---|
| Same `if quality == X` switch dispatching 4 sibling algos | `submit_answer` L633-648 | Adding a 5th quality bucket = edit service + add free function + wire import |
| Heuristic eval baked into service, no seam | `_evaluate_answer` L400-443 | Future LLM-eval swap would have to monkeypatch or fork `submit_answer` |
| Free-function follow-up builders coupled by string keys | `prompts/templates.py` | No type safety, no override per test |
| Quality classifier returned magic strings | `_classify_answer_quality` | `"incomplete"` typo silently routes to `"normal"` branch |
| Service untestable without DB | `InterviewService()` builds everything inline | Repository pattern blocked |

---

## How pattern-surgeon decided — compare mode

**Step 1: `suggest` mode** — ran the 6-rule inline detection census against the
named scope. Strategy fired strong (≥2 swap sites + multiple sibling algos).
Repository fired medium (raw `db.query(...)` in 8 methods). Factory + DI fired
weak. Adapter + Observer absent.

**Step 2: `compare` mode** — loaded `comparison-rubric.md` only (lazy load — not
all 6 pattern files). Scored 4 plausible candidates against 5 axes (smell-match
/ change-locality / reversibility / framework-idiom / added-indirection cost),
each 2/1/0.

### The scoring matrix pattern-surgeon produced

| Pattern | smell | local | revers | fw | indir | total | verdict |
|---|---|---|---|---|---|---|---|
| **Strategy** | 2 | 2 | 2 | 1 | 2 | **9** | strong fit |
| Factory | 1 | 2 | 2 | 1 | 1 | **7** | partial |
| Repository | 2 | 1 | 1 | 1 | 1 | **6** | partial |
| Dependency Injection | 1 | 1 | 1 | 1 | 1 | **5** | partial |

**Verdict logic the skill applied:** `strong fit` tier exists → recommend only
from that tier → Strategy wins (sole strong-fit candidate).

### Why Strategy beat the runner-up (Factory, 7/10)

Strategy removes a duplicated *algorithm* branch firing every `submit_answer`
call (high traffic, high cost). Factory only relocates *construction* — single
site, no current branching — YAGNI until question sources go plural.

### What the skill rejected and why

| Pattern | Score | Rejection reason |
|---|---|---|
| Repository | 6 partial | Real smell, but lower leverage than Strategy. Recorded as Phase 5 second pass — refused to bundle two patterns in one PR |
| Factory | 7 partial | Only one concrete question source exists today (YAGNI). Re-evaluate when LLM-generated questions become a second source |
| Dependency Injection | 5 partial | "Small object graph" suppress condition fired. Constructor-pass via lazy defaults is the Python idiom. No framework adopted |
| Adapter, Observer | not scored | No smell present — skipped |

This is the discipline that matters: **pattern-surgeon did not let me bundle
"good ideas" into one PR**. It forced a single, defensible pattern with the
highest leverage, parked the rest as later phases.

---

## The refactor — what changed

### New files

```
backend/interview-module/app/strategies/
├── __init__.py        # public exports
├── quality.py         # AnswerQuality enum + classify_answer_quality()
├── evaluator.py       # AnswerEvaluator Protocol + HeuristicEvaluator
└── follow_up.py       # FollowUpStrategy Protocol + 4 impls + DEFAULT_FOLLOW_UPS registry
```

### Edits

| File | Change |
|---|---|
| `interview_service.py` | Added `__init__(evaluator, follow_ups, progress_strategy)` with lazy defaults. Deleted `_evaluate_answer` (44 lines). Deleted `_classify_answer_quality` (14 lines). Replaced 4-branch `if quality == X` block with `self._follow_ups.get(answer_quality).build(...)`. Dropped 4 imports from `prompts.templates`, added 1 from `app.strategies` |
| `prompts/templates.py` | Deleted 5 follow-up builder free functions (~50 lines). Kept question-source utilities |

### LOC delta

- `interview_service.py`: ~-60 (heuristic + classifier removed) + ~+12 (constructor + injection)
- `templates.py`: ~-50 (follow-up builders out)
- `strategies/`: ~+190 (4 new files with typed Protocol + Enum + classes)

**Total: ~-20 LOC net.** The new lines are pure typed declarations, not branching logic.

---

## Before / after

### Quality routing

**Before** (`submit_answer`):

```python
answer_quality = self._classify_answer_quality(evaluation)  # returns "incomplete"|"incorrect"|"normal"|"strong"
...
elif not already_followed_up and answer_quality in {"incomplete", "incorrect", "strong"}:
    if answer_quality == "incomplete":
        next_question = build_clarification_follow_up(questions[current_index].question_text, interviewer_role)
    elif answer_quality == "incorrect":
        next_question = build_corrective_follow_up(questions[current_index].question_text, interviewer_role)
    else:
        next_question = build_difficulty_follow_up(questions[current_index].question_text, interviewer_role)
```

**After**:

```python
answer_quality = classify_answer_quality(evaluation)  # AnswerQuality enum
follow_up_strategy = self._follow_ups.get(answer_quality) if not timed_out else None
...
elif not already_followed_up and follow_up_strategy is not None:
    next_question = follow_up_strategy.build(questions[current_index].question_text, interviewer_role)
```

Branches gone. One lookup, one polymorphic call.

### Evaluator injection

**Before**:

```python
class InterviewService:
    # heuristic baked in
    def _evaluate_answer(self, answer_text: str) -> Dict[str, Any]:
        # 44 lines of keyword/regex/tone scoring
```

**After**:

```python
class InterviewService:
    def __init__(
        self,
        evaluator: Optional[AnswerEvaluator] = None,
        follow_ups: Optional[Mapping[AnswerQuality, FollowUpStrategy]] = None,
        progress_strategy: Optional[FollowUpStrategy] = None,
    ) -> None:
        self._evaluator = evaluator or HeuristicEvaluator()
        self._follow_ups = follow_ups if follow_ups is not None else DEFAULT_FOLLOW_UPS
        self._progress_strategy = progress_strategy or ProgressFollowUp()

    # submit_answer body:
    evaluation = self._evaluator.evaluate(questions[current_index].question_text, transcription)
```

**LLM swap is now 1 line at composition root**: `InterviewService(evaluator=LLMEvaluator(...))`.
No `submit_answer` surgery required.

---

## Public surface — unchanged

| Caller | Old call | New call |
|---|---|---|
| `grpc/server.py` | `InterviewService()` | `InterviewService()` (zero-arg still works — lazy defaults) |
| `api.py` × 7 handlers | `InterviewService()` × 7 | `InterviewService()` × 7 (unchanged) |
| External: gRPC + REST | request/response shapes identical | identical |

Zero changes to proto, DB schema, environment, or HTTP/gRPC contracts. Drop-in.

---

## Verification performed

1. **Import smoke**: `InterviewService()` constructs with defaults. All 3 strategies wired with expected concrete types.
2. **Heuristic eval parity**: same input → same `{technical, grammar, clarity, tone, keyword_hits, word_count}` dict shape as before.
3. **Follow-up parity**: each routed strategy produces the same prefix as old free-function builders (`[senior engineer] ...Clarify:...` / `...Correction:...` / `...Advanced follow-up:...`).
4. **Lifecycle parity**: `start → submit (incomplete) → submit (strong) → submit × N → end` returns the same dict keys; `interview_completed` transitions `false → true` correctly; final report intact.
5. **No stale imports**: grep across `backend/` confirmed zero references to deleted builders.

---

## What was deferred (and why)

| Concern | Deferred to | Why |
|---|---|---|
| Proto extras tunneled through `role::type=...` string | Phase 2 | Cross-module proto regen + main-module client edit |
| Heuristic eval replaced by LLM | Phase 3 | Needs main-module internal HTTP route + auth token |
| `notes` JSON blob → real columns | Phase 4 | Needs Postgres migration + Alembic baseline |
| Service does raw `db.query(...)` | Phase 5 | Repository pattern — blocked on Phase 4 |
| gRPC handler boilerplate dedup | Phase 5 | Decorator pattern — after Repository lands |

The skill refused to mix any of these into Phase 1. **One pattern, one pass.**

---

## Rollback plan

```bash
git checkout HEAD -- backend/interview-module/app/services/interview_service.py \
                     backend/interview-module/app/prompts/templates.py
rm -rf backend/interview-module/app/strategies/
```

No DB state to revert. No proto regen to undo. Reversible in <30s.

---

## What this demonstrates about pattern-surgeon

| Capability | Evidence in this case |
|---|---|
| Detects real smells, not stylistic preferences | Identified the 3-branch switch + magic-string classifier + baked-in heuristic |
| Refuses to over-engineer | Rejected Factory (YAGNI), DI (small graph), Repository (separate phase) |
| Enforces single-pattern PRs | Forced Phase 1 = Strategy only; Repository parked to Phase 5 |
| Picks the highest-leverage pattern | Strategy unblocks the future LLM-evaluator swap (the user-facing quality jump) — Repository would not have |
| Respects language idioms | Constructor-pass with lazy defaults instead of a Python DI framework |
| Stays reactive | Only read the file the user named — never scanned the broader repo |
| Lazy-loads references | Only loaded `comparison-rubric.md`, not all 6 pattern files |

---

## Installation used

```
/plugin marketplace add nuhin13/pattern-surgeon
/plugin install pattern-surgeon
```

Skill cache: `~/.claude/plugins/cache/nuhin13/pattern-surgeon/1.0.0/skills/pattern-surgeon/`.
