# Ask Hygiene — 2026-05-15 P132 Phase 2a-ii AFK iter

Per Step 2d of `/wr-retrospective:run-retro` — P135 Phase 5 / ADR-044 lazy-AskUserQuestion-count regression metric. Trail file consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session trend analysis.

## Calls

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| (none) | — | — | — |

Zero `AskUserQuestion` calls this iter. AFK orchestrator `/wr-itil:work-problems` constraint #4 (P135 / ADR-044) forbids mid-loop asks; observations queued for the orchestrator's `outstanding_questions` slot in `ITERATION_SUMMARY` rather than fired as in-iter prompts.

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## R6 Numeric Gate

Not fired. Cross-session trend per `check-ask-hygiene.sh`: `lazy_first=0 lazy_last=0 delta=+0` across the last 10 retros (most recent: `2026-05-15-p132-phase-2a-i` lazy=0 → this retro `2026-05-15-p132-phase-2a-ii` lazy=0). R6 condition requires lazy count ≥2 across 3 consecutive retros; the trend is clean.
