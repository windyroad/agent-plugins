# Ask Hygiene — 2026-05-05

Per **ADR-044** + Step 2d Ask Hygiene Pass (P135 Phase 5). Lazy count is the regression metric (target 0).

## Per-call classifications

This session made **0** `AskUserQuestion` calls. All decisions were direction-setting from the user via verbatim natural-language prompts:

1. *"Capture the actually problem as P170. The ADR captures how we decide to solve it (and considered alternatives)..."* — direction-setting authority (ADR-044 category 1).
2. *"are these RCA investigation tasks? Or implementation tasks?..."* — authentic correction (ADR-044 category 6 / P078 capture-on-correction surface).

Both were resolved via direct action without `AskUserQuestion`. The framework's mechanical-stage carve-outs (capture-problem skeleton-fill, manage-problem reconcile-readme dispatch, ADR draft per direction, restructure per correction) all silently proceeded per ADR-044 + P132 inverse-P078.

## Counts

**Lazy count: 0**
**Direction count: 0** (calls; the user's natural-language prompts above were the direction-setting primary input, not AskUserQuestion-mediated)
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Trail

`docs/retros/2026-05-05-ask-hygiene.md` — this file.

Cross-session trend: invoke `packages/retrospective/scripts/check-ask-hygiene.sh` to compute the R6 numeric gate (lazy ≥2 across 3 consecutive retros).
