# Ask Hygiene Pass — work-problems iter 4 (P316)

**Date**: 2026-05-30
**Surface**: `/wr-itil:work-problems` iter 4 closing P316
**Scope**: ADR-066 marker-vocabulary extension (rejected-pending-supersede)

## AskUserQuestion calls this iter

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | Orchestrator constraint: "NEVER call AskUserQuestion mid-loop (P135 / ADR-044): queue observations to ITERATION_SUMMARY.outstanding_questions." |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

The orchestrator AFK contract suppresses mid-loop AskUserQuestion entirely. Any decisions that would have warranted a category-1 direction-setting prompt (e.g. genuine ≥2-option ADR-074 substance-confirm) are queued to `outstanding_questions` in the ITERATION_SUMMARY instead. This iter found no such decision — the marker-vocabulary extension was an in-scope refinement of ADR-066's existing Reassessment carve-out per the substance-confirm guard, confirmed GREEN by the architect agent.
