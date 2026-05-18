# Ask Hygiene — Session 8 Orchestrator Wrap (2026-05-19)

Per ADR-044 / P135 Phase 5 — classifies the agent's `AskUserQuestion` calls across session 8 to track the lazy-AskUserQuestion-count regression metric. Cross-session trend consumed by `packages/retrospective/scripts/check-ask-hygiene.sh`.

**Scope**: full session 8 — 6 fix iters (P266 / P269 / P268 / P272 / P273+P274+P275 batched) + 1 review-problems pass + 4 mid-loop captures (P270 / P271 / P276+P277+P278 batched / P279) + 3 npm releases (`@windyroad/itil@0.35.4` + `0.35.5` + `0.35.6` + `0.35.7`, `@windyroad/retrospective@0.20.4`).

## Calls

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Capture deviations? | deviation-approval | Framework: `packages/itil/skills/work-problems/SKILL.md` Step 2.5a — framework-prescribed surfacing of 4 deviation-approval observations from iter-2 outstanding_questions queue (P276 external-comms-gate over-fires / P277 P165 readme-refresh-hook shared-tree concurrency / P278 renderer package-counts convention vs P141 / P279 ADR-017 layout housekeeping). The deviation-approval class is non-lazy per ADR-044 — these were genuine "existing decision found wrong under current evidence" surfacings, not lazy sub-contracting. |
| 2 | Next action? | direction | Framework: `packages/itil/skills/work-problems/SKILL.md` Step 2.5b — framework-prescribed loop-end direction-setting selection (work next / wrap with retro / wrap without retro). The direction class is non-lazy per ADR-044 — selecting between work-continuation paths is genuine direction-setting, not framework-resolvable. |

**Lazy count: 0**
**Direction count: 1**
**Deviation-approval count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Iter subprocesses

All 6 iter subprocesses (P266 / P269 / P268 / P272 / P273+P274+P275) returned 0 mid-loop AskUserQuestion per the iter-subprocess contract — questions queued via `outstanding_questions` for orchestrator main-turn surfacing. The 4 deviation-approval observations surfaced in Call #1 came from this queue (iter-2 P277 + iter-2 P276 + iter-2 P278 + iter-6 P279 — captured during iter-1's mid-loop captures of P270/P271 and iter-3's batched capture of P272+P273+P274+P275 sibling-sweep findings).

## R6 numeric gate check

Cross-session trend (last 8 retros): lazy=0 throughout. R6 condition (lazy ≥2 across 3 consecutive retros) NOT MET. Phase 4 enforcement hook escalation NOT warranted at this retro.

## Notes

- This session's clean 0-lazy result extends the trend that began with the P135 Phase 2 / Phase 3 declarative-first contract changes (silent-classification model for Step 1.5 removals, Step 3 rotations, Step 4a verification closes, Step 4b Stage 1 ticketing, Step 4b Stage 2 fix-strategy picks).
- The 2 fires this session were both framework-prescribed Step 2.5 surfacings — the framework explicitly calls them out as the legitimate AskUserQuestion entry points at loop end. No mid-iter consent gates fired.
