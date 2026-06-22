# Ask Hygiene — 2026-06-23 P363 rework + ratify cycle

**Scope**: Continuation of yesterday's `/wr-itil:work-problems` tier-1 invocation. User redirected mid-session to work P363 + pinned 4 substantive directives across multiple AskUserQuestion cycles + ratified the implementation substance per P357. Orchestrator-main-turn AskUserQuestion calls only — per-iter retros (P363 first iter, P363 rework iter) carry their own ask-hygiene trails (the rework iter's retro was partial — stream-timeout'd before commit; salvage commit captured the substance).

## In-session table

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | P363 fix shape | **direction** | Gap: genuine ≥2-option decision (a/b/c) on the cross-direction dispatch mechanism, framework cannot resolve, about to be built on (ADR-074 substance-confirm-before-build) |
| 2 | Ratify P363 build | **direction** | Gap: P357 brief-and-ratify-after-changes — the iter implemented the mechanism (option b) but the implementation substance (template wording / own-repo close semantics / disclosure tokens) needed user review before ADR-024 oversight stamp |
| 3 | Which template? | **direction** | Gap: user picked "Confirmed mechanism, but the comment wording needs an edit"; multi-select on which of 3 templates needed amending (the answer pivoted scope significantly) |
| 4 | Ratify P363 rework | **direction** | Gap: P357 brief-and-ratify-after-changes — second pass post-salvage; user needed ADR-024 (cross-project problem reporting contract) briefed before re-stamping oversight |
| 5 | Ratify ADR-024 | **direction** | Gap: P357 brief-and-ratify — user requested fuller ADR brief; substance-confirm of the 2026-06-23 amendment before re-stamping `oversight-date: 2026-05-25 → 2026-06-23` |

**Lazy count: 0**
**Direction count: 5**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Trend signal

Lazy count = 0 (clean). R6 numeric gate condition (≥2 lazy across 3 consecutive retros) does not fire. All 5 asks were genuinely direction-setting per the ADR-074 substance-confirm-before-build + P357 brief-and-ratify-after-changes contracts. Of note: 4 of 5 were the P363 substance-pivot cycle (mechanism → wording → template→prompt pivot → workaround inclusion → reporter credit → public-repo linking) where each user response materially changed the next iter's prompt — the ADR-074 contract working exactly as designed.
