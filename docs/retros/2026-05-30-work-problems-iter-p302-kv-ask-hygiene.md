# Ask Hygiene — work-problems iter (P302 K→V)

Date: 2026-05-30
Iter: K→V transition (subsequent to iter-10 O→KE)
Session role: AFK iteration-worker subprocess (`claude -p` per P086)
Companion retro: `docs/retros/2026-05-30-work-problems-iter-p302-kv.md`

## AskUserQuestion calls

(None — no `AskUserQuestion` invocations fired this iter.)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

AFK orchestrator constraint forbids mid-loop AskUserQuestion per the dispatch prompt (R5 / P135 / ADR-044). All decisions this iter were framework-resolved by the K→V transition-problem SKILL contract or pre-pinned by the orchestrator's selection prompt:

- Ticket selection: orchestrator picked P302 (highest WSJF actionable per Step 1 scan)
- Release vehicle citation: `wr-itil-derive-release-vehicle P302` per ADR-026 grounding
- README VQ row insertion position: P150 Released-ASC + ID-ASC ordering (between P282 and P316)
- README line-3 fragment rotation: P134 contract
- Commit message convention: per transition-problem SKILL Step 8 (Known Error → Verification Pending standalone shape, no fix riding with it)
- Pipeline-gate satisfaction: `wr-risk-scorer:pipeline` Agent delegation per ADR-014 / ADR-015

Framework-resolved decisions are not lazy per ADR-044 — they are the framework-resolution boundary applied correctly. The lazy-count metric of 0 reflects clean framework discipline, not under-asking on a genuine direction-setting decision (the iter scope is pure paperwork; no direction-setting decisions surfaced).

## Trail integration

This file participates in the cross-session lazy-count trend consumed by `packages/retrospective/scripts/check-ask-hygiene.sh`. Per the R6 numeric gate (ADR-044 Reassessment Trigger / P135), the gate fires when lazy count remains ≥2 across 3 consecutive retros. This iter contributes a lazy count of 0 to the trail.
