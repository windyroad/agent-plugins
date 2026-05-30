---
"@windyroad/retrospective": patch
---

`/wr-retrospective:run-retro` Step 4a gains sub-step 9 "Prior-session evidence drain (P282)" that consumes durable on-disk evidence — `docs/problems/README.md` Verification Queue rows whose `Likely verified?` cell already records `yes — observed: <citations>` from a prior session — that is structurally invisible to current-session tool-call scans (sub-steps 1-8).

The drain reads the README's Verification Queue, filters to rows whose `Likely verified?` cell begins with `yes — observed:` (canonical P186 cell shape), preserves sub-step 8 same-session exclusion via `git log --since=<session-start>` rename detection, and dispatches `/wr-itil:transition-problem <NNN> close` per the existing sub-step 5-7 cross-plugin contract. Source distinction `(prior-session README cell)` rides the Decision column of the Step 5 Verification Candidates table so drained-from-cell closures are auditable separately from current-session evidence dispatches.

Architect verdict: PASS — no new ADR (thin extension of ADR-022 + ADR-014; ADR-074 substance-confirm trip-wire does not fire). JTBD verdict: PASS rank (c) > (d) > (a) > (b).

New behavioural fixture `packages/retrospective/skills/run-retro/test/run-retro-step-4a-prior-session-evidence-drain.bats` — 12 assertions. Full run-retro suite 150/150 green.
