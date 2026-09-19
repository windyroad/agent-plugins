# Ask Hygiene — 2026-09-19 (P543 iteration)

Per ADR-044 / run-retro Step 2d. This was an unattended `/wr-itil:work-problem 543` run under binding iteration constraints that forbid `AskUserQuestion` outright, so the call set is empty by construction.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | `Framework: iter-543 constraint 2 — "NEVER call AskUserQuestion. The user is absent."` |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

One genuine direction-setting question arose and was correctly routed to `outstanding_questions` rather than asked: how long the AFK loop's liveness survives an orchestrator-level interruption (P543 investigation task 1, three options recorded on the ticket). Under the constraint that is the mandated path, and it would classify as `direction` (ADR-074 substance-confirm-before-build) had the session been interactive.

R6 numeric gate: does not fire. `wr-retrospective-check-ask-hygiene` reports `TREND lazy_first=0 lazy_last=0 delta=+0` across the trail.
