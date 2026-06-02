---
'@windyroad/retrospective': patch
---

P322 (Open→Verifying, S, WSJF 3.0) — exclude `*-archive*.md` rotation sinks from the Tier-3 briefing-budget pass.

**Bug.** `check-briefing-budgets.sh` globbed every `docs/briefing/*.md` including `*-archive*.md` rotation sinks. Sinks are the destination of split-by-date rotation — loaded on-demand only per `docs/briefing/README.md` ("load alongside when full historical context needed"), NOT session-start-loaded. Holding sinks to the per-topic session-surface budget (ADR-040 Tier 3) forced a churn-vs-defer choice every retro: splitting a sink has no chronologically-correct sibling slot, so the agent either proliferated `-archive-N` siblings (churn) or deferred (the P247 anti-pattern the pass exists to prevent). Observed 2026-05-27 — two archives (`governance-workflow-archive.md` 6551 B and `hooks-and-gates-archive.md` 5429 B) flagged OVER with no correct rotation target.

**Fix.** Basename-pattern exclusion (`case "$base" in *-archive*.md) continue ;;`) added alongside the existing `README.md` exclusion in `packages/retrospective/scripts/check-briefing-budgets.sh`. Header comment block updated to document the rationale (rotation sinks, on-demand-only loading, ADR-040 Tier 3 session-start surface intent) and to record `@problem P322` alongside the existing `@problem P099` / `@problem P145`.

**Coverage.** Three new behavioural bats cases per ADR-052 (`packages/retrospective/scripts/test/check-briefing-budgets.bats`):

- `archive file at or above threshold is excluded (P322 rotation sink)` — was RED pre-fix, GREEN post-fix.
- `archive variant -archive-2026-05.md is also excluded` — confirms date-suffixed siblings produced by split-by-date are excluded too.
- `non-archive over-threshold file is still flagged alongside archive exclusion` — confirms the exclusion does NOT regress the active-surface flag path (mixed-case: session-start file flagged + archive sibling silenced).

23/23 GREEN post-fix.

**Compliance.** Architect verdict 2026-06-03: ALIGN-WITH-CONDITIONS — no new ADR required; restores ADR-040 Tier 3 envelope intent (the script narrows its scope to the surface ADR-040 governs). Condition C1 (amend ADR-040 Confirmation field to also name `*-archive*.md` excluded + regenerate `docs/decisions/README.md` per ADR-077) queued as P349 per AFK iter no-ADR-edits constraint. JTBD verdict 2026-06-03: PASS — JTBD-001 (governance speed — removes the churn-vs-defer false-positive class), JTBD-006 (AFK orchestrator silent-rotation path restored to soundness — `MUST_SPLIT` becomes a meaningful "no defer" signal again), JTBD-101 (pattern parity with the README.md exclusion). ADR-014 single-purpose commit grain (test + fix + ticket transition O→V + changeset + README refresh in one commit; downstream ADR-040 doc sync left out of scope per AFK constraint, captured as P349).
