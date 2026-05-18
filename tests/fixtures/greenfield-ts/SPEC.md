# greenfield-ts

Eval anchor for `greenfield` mode. No `impl.js` exists; `test.js` is the
pre-written failing test (`verify.sh` exits 3 — the correct start state).

Target behavior: `notify(kind, msg)` dispatches to per-kind notifiers
("email"/"sms"/"push"). Expected `greenfield` flow: pick a pattern via
`comparison-rubric.md` (Strategy), `checkpoint.sh`, write `impl.js`
implementing it, `verify.sh` reaches exit 0. Do NOT commit a generated
`impl.js` into this fixture — the committed state must stay red so the gate
test keeps asserting exit 3.
