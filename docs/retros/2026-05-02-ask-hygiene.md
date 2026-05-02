# 2026-05-02 Ask Hygiene Trail

Per **ADR-044** (Decision-Delegation Contract — framework-resolution boundary) Step 2d: per-session classification of `AskUserQuestion` calls. Persisted for cross-session trend analysis via `packages/retrospective/scripts/check-ask-hygiene.sh`. Lazy count is the regression metric — target 0.

## Session context

Session: 2026-05-02 P148 release + retrospective. Focused work commit-and-release for pending AFK-iter fix work. No new feature design; no contested decisions.

## AskUserQuestion calls

(none — zero `AskUserQuestion` invocations this session)

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| (none) | — | — | — |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

The session followed the framework-mediated path mechanically per ADR-044:

- `/wr-itil:work-problem P148` user-override path skipped the tie-break ladder (framework-mediated by user override per ADR-044's Prioritisation row).
- Step 0 reconcile-readme directive interpreted contextually (uncommitted-rename-rooted drift → inline refresh per ADR-014 single-commit grain). This was a SKILL contract overreach on the agent's part — captured as P149 rather than asked of the user.
- Risk-scorer pipeline returned reducing bypass on the P148 commit (closes ticket); Step 11/12 commit + push:watch + release:watch ran policy-authorised silent per ADR-013 Rule 5.
- Retro Step 4b Stage 1 ticketing was mechanical (no AskUserQuestion); P149 + P150 created via manage-problem.
- Retro Step 4b Stage 2 fix-strategy picks were silent agent-judgement (Skill — improvement stub for both); per ADR-044 framework-mediated.
- Tier 3 topic-file rotation: silent leave-as-is per SKILL contract (no clear sub-topic boundary, no first-written fields, no Step 1.5 noise classifications above threshold). Recurring pattern composes with P145 already on backlog.

## R6 trend

Cross-session lazy count trail (most recent first):

- 2026-04-29 (P143 retro): 0
- 2026-04-28 (P140 retro): 0
- 2026-04-28 retro: 0
- 2026-04-27 retro: 3
- TREND lazy_first=3 lazy_last=0 delta=-3

R6 numeric gate condition (lazy ≥2 across 3 consecutive retros) has NOT fired. The Phase 4 enforcement hook deferral remains correct per the P135 plan / ADR-044 Reassessment Trigger.
