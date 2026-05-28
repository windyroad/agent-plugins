# Ask Hygiene — 2026-05-28 (JTBD surface-3 / P289 rename / promptfoo harness arc)

Per ADR-044 framework-resolution boundary. Lazy count is the regression metric (target 0).

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | JTBD surface-3 decision home (amend ADR-068 / new ADR / amend ADR-074) | direction | Gap: genuine ≥2-option decision-home, framework can't resolve, about to be BUILT ON — ADR-074 substance-confirm-before-build (architect raised it as Needs-Direction) |
| 2 | Persona P289 (defer / execute→developer / execute→software-developer) | direction | Gap: whether to execute a large (Effort-L, ~275-occurrence) rename this session + the final name — user owns scope + naming |
| 3 | Harness path (spike / full-RFC / promptfoo / defer) | direction | Gap: genuine ≥2-option approach decision for a new test-harness subsystem (amends ADR-052); framework can't resolve |
| 4 | Eval-config location (per-package / root) | direction | Gap: architect-flagged Needs-Direction; ADR-002 per-plugin-independence tension, user owns |
| 5 | Tier B cadence (split / block-PR / scheduled) | direction | Gap: architect-flagged Needs-Direction; CI-gating cadence + token-cost tradeoff, user owns (answered with a sharper custom cadence: A→CI+pre-push, B→release) |

**Lazy count: 0**
**Direction count: 5**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Note: every ask was a genuine ≥2-option decision the framework could not resolve — two were explicitly raised by the architect as Needs-Direction verdicts (calls 1, 4, 5), one was ADR-074 substance-confirm-before-build (call 1), and the user's direct directives this session ("Graduate it", "Push", "Create the node ticket", "Run the retro") were acted on WITHOUT a confirmation ask. No lazy sub-contracting. The session's correction signals ("why aren't you implementing P176/P012", "structural tests are not ok", "I shouldn't have to ask") were handled by acting + capturing (P324, P325, P148-recurrence), not by asking — consistent with the don't-prose-ask + capture-on-correction discipline.
