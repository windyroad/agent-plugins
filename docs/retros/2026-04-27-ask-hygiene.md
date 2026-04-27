# Ask Hygiene — 2026-04-27 (P135 Phase 5 first-ever exercise)

First trail file for the Step 2d "Ask Hygiene Pass" (per ADR-044 + P135 Phase 5). Establishes the baseline lazy-AskUserQuestion-count metric for cross-session trend via `packages/retrospective/scripts/check-ask-hygiene.sh`.

This session was unusually long and contains both **pre-Phase-2** and **post-Phase-2** AskUserQuestion behaviour — Phase 2 was implemented mid-session, so the EARLIER classifications include lazy patterns the new contract removes. Useful baseline regardless: the lazy count anchors the regression metric for next-session-onwards measurement.

## Per-call classifications

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | "P124 regression" | direction | New direction — flip-back vs sibling vs record vs fix-now is genuine choice with trade-offs; not framework-resolvable |
| 2 | "Briefing entry" | **lazy** | Framework: Step 1.5 silent-classification model resolves "which to add"; ADR-044 Phase 2 amended this to silent (no-ask) |
| 3 | "Capture pattern" (inverse-P078) | direction | New ticket creation — user-confirmed novel direction (P132 born) |
| 4 | "Loop next-step" (iter 9 = P081 vs others) | **lazy** | Framework: WSJF + tie-break already decides; per-iter-pick ask is sub-contracting |
| 5 | ".claude/ capture" | direction | New ticket creation — user-confirmed novel direction (P131 born) |
| 6 | "Audit scope" (P136 ticket shape) | direction | New work shape decision — user picks between single-ticket / per-package / on-touch |
| 7 | "Phase 4 remembering" (auto-flag mechanism) | direction | New mechanism design — user picks integration shape |
| 8 | "R6 preview-tag deviation" | **deviation-approval** | Existing plan R2 vs evidence (no preview-tag tooling exists) — first-ever exercise of ADR-044's deviation-approval flow |
| 9 | "Continue P136?" (next direction after Phase 1) | direction | New direction — pause vs continue vs different ticket vs retro |
| 10 | "P081 next-step" (after grep correction) | direction | New work shape — update P081 vs continue vs replan vs stop |
| 11 | "Briefing capture (3 friction signals)" | **lazy** | Framework: Step 3 add silent per Step 1.5; user picked "None — just tickets" partly because the framework already settles add/skip |
| 12 | "Continue/stop session" (post P135 done) | direction | Genuine new direction (continue or wrap) |
| 13 | "Continue P136 vs retro" (this turn's question) | direction | New direction — work continuation vs session wrap |

## Counts

**Lazy count: 3**
**Direction count: 8**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**
**Deviation-approval count: 1**

(Phase 5's `check-ask-hygiene.sh` script reads only the standard 6-class counts: lazy / direction / override / silent-framework / taste / correction-followup. The deviation-approval column is added inline here as evidence that the new ADR-044 surface fired this session — first-ever exercise.)

## Trend (TREND line semantics)

First retro with this trail — no prior entries. `check-ask-hygiene.sh` will not emit a TREND line until ≥2 trail entries exist.

## Notes

- **Lazy count baseline = 3**. Phase 2 amendments shipped today should reduce future lazy calls (briefing-add, briefing-rotation, codification-shape, verification-close all went silent). Expect next session's lazy count to trend lower as the new contract takes effect (cached SKILL.md needs Claude Code restart + `/install-updates` to load `@windyroad/retrospective@0.12.0` + `@windyroad/itil@0.21.3`).
- **Deviation-approval count = 1**. First-ever exercise of ADR-044's deviation-approval flow (R2 preview-tag tooling doesn't exist → user approved "amend plan, ship to latest"). Validates the surface works end-to-end.
- **Direction count = 8**. High but legitimate: this was a heavy direction-setting session (P135 design + P135 implementation review + P136 audit shape + P136 remembering mechanism + multiple continue/stop/redirect decisions). Direction-class asks are not regressions per ADR-044.

This trail entry seeds the cross-session lazy-count trend that Phase 4 enforcement gating (R6 numeric criterion: lazy ≥2 across 3 consecutive retros) will consume.
