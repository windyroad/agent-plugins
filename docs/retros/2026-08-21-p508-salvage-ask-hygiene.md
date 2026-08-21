# Ask Hygiene — 2026-08-21 (P508 stalled-iteration salvage)

Salvage session for the `/wr-itil:work-problems` iteration that was SIGTERMed at the 60-minute idle threshold while working P508 (exit 143, 0-byte JSON, no `ITERATION_SUMMARY`, no retro). `AskUserQuestion` is unavailable in this surface by explicit orchestrator constraint ("Never call AskUserQuestion").

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | n/a | No `AskUserQuestion` calls were made. |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## One direction item written as `unconfirmed` rather than asked

The JTBD gate required the ADR-068 lockstep on JTBD-006 and JTBD-002 — both conditioned unattended acceptance on a "where the project has opted in" clause ADR-103 dropped knowingly on 2026-08-07, and P508 slice A is what made the staleness bind. The amendment was applied and both files were downgraded to `human-oversight: unconfirmed`, with re-ratification queued for the next interactive `/wr-jtbd:confirm-jobs-and-personas` drain.

Had this session been interactive, that would have fired one `AskUserQuestion` classified **direction** (ADR-074 exclusion — a genuine decision about to be built on), never lazy. It was not asked, and no `confirmed` marker was written: asserting a ratification nobody gave is the P348 hollow-marker bug, while withdrawing a stale ratification claim needs no confirm event. That asymmetry is the reason this is a clean `unconfirmed`, not a queued question the session dodged.

## Three surfaces where a gate verdict was applied rather than relayed

Recorded because each is a place a lazy ask would have been easy and would have been wrong. The risk-scorer returned `commit=8` then `commit=6` against a Low(5) appetite with named remediations; per ADR-042 those were auto-applied, not surfaced as options — offering an above-appetite commit is the P132 inverse-trap and the answer is always no. The architect returned ISSUES FOUND once (ADR-073's option-bearing guard had lost its only carrier when the I13 gate stopped calling `capture-rfc`); the fix was applied and re-reviewed. The JTBD gate returned ISSUES FOUND twice; both rounds were applied in one batch each, per the marker-invalidation discipline.
