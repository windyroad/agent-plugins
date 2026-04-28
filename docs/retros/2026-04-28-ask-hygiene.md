# Ask Hygiene — 2026-04-28 (AFK `/wr-itil:work-problems` iter, P124 Phase 3)

Per ADR-044 / P135 Phase 5. Trail file consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session lazy-count trend.

## In-session AskUserQuestion calls

(none — this iteration ran as a `claude -p` AFK subprocess; `AskUserQuestion` is unavailable per ADR-013 Rule 6 + the work-problems iteration-worker prompt's explicit forbidding clause)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

AFK iteration-worker subprocess; per ADR-013 Rule 6 + iteration-worker prompt contract, all decisions resolve non-interactively. No AskUserQuestion calls = lazy count 0 by construction. Cross-session trend: prior retro (2026-04-27) recorded `lazy=3 direction=8`; this iteration is silent on the metric (not a denominator-1 datapoint — the metric only counts retros where AskUserQuestion was actually available to fire).
