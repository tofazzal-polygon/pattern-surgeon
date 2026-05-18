# observer-suppress-ts

**Suppression fixture** — `Order.complete()` calls exactly one listener
(`emailService.send`). The Observer detection rule requires a **manual notify
chain / callback fan-out** (multiple consumers). A single stable listener is
better served by a direct call; adding a Subject introduces indirection with
no benefit.

> **Suppress when: single listener.**

The correct skill output is a **suppression recommendation**: acknowledge the
direct call, note there is only one consumer, and do NOT apply Observer.

## What the skill must output
`suggest` / `compare`: "Only one notification target (emailService) — Observer
threshold (fan-out to multiple consumers) not met. Direct call is correct here.
Suppressed."

`refactor`: same suppression message; no code change.
