# Ask Hygiene — /wr-retrospective:run-retro (session-level / orchestrator main-turn)

Trail file per `/wr-retrospective:run-retro` Step 2d (P135 Phase 5 / ADR-044). Consumed by `packages/retrospective/scripts/check-ask-hygiene.sh` for cross-session trend analysis. Scope: orchestrator main-turn AskUserQuestion calls during the 2026-06-10 `/wr-itil:work-problems` session.

## Per-call classification

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Persona/JTBD | direction | Gap: `/wr-itil:capture-problem` Step 1.5b I12 derive-then-ratify dispatch — the user-invoked capture ("the plugins expose internal IDs that the using repo does not have access to") had no `--jtbd=` / `--persona=` flag and no lexical JTBD-NNN citations in the description; description was authorial ambiguity between plugin-user (adopter friction) and plugin-developer (maintainer ergonomics). Per ADR-060 Amendment 2026-06-02 + ADR-044 cat-1 (direction-setting), the dispatch proposes ≤3 candidate persona+JTBD pairs for user ratification. User picked plugin-user + JTBD-302 (Trust That the README Describes the Plugin I Just Installed). Framework deliberately does NOT resolve persona+JTBD anchoring for ambiguous captures — the ask IS the framework-prescribed direction-setting surface. |

**Lazy count: 0**
**Direction count: 1**
**Deviation-approval count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Cross-session trend pointer

`packages/retrospective/scripts/check-ask-hygiene.sh` reads this file plus prior `docs/retros/<YYYY-MM-DD>-ask-hygiene.md` siblings to compute the R6 numeric gate (lazy count ≥ 2 across 3 consecutive retros). This session's lazy=0 contributes a zero to the trend.

## Notes

- Session was unusually short (one user-invoked /capture-problem, two failed `claude -p` subprocess dispatches with API socket-closed, one session-level retro). Few opportunities for AskUserQuestion.
- The Step 1.5b derive-then-ratify ask is ADR-074 (substance-confirm-before-build) — a legitimate cat-1 direction ask, NOT counted as lazy per the ADR-074 lazy-count exclusion clause in Step 2d.
- No mid-loop ask occurred between iter dispatches (per the orchestrator's Mid-loop ask discipline / P130).
