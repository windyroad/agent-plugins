# Problem 463: Relevance-close evaluator over-fires — a bare ADR/skill citation is read as "fix shipped", producing a 76% false-positive CLOSE-CANDIDATE rate

**Status**: Open
**Reported**: 2026-07-26
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a. Impact 3: misroutes governance close decisions and poisons the work-problems Step 3.6 pre-dispatch relevance gate (dev-tooling degraded; no shipped-package harm). Likelihood 4: observed on every review pass that has run recently (76% hit rate on 2026-07-26).
**Origin**: internal
**Effort**: M — tighten the match-shape predicates in `evaluate-relevance.sh` + author behavioural coverage over the false-positive shapes; cf. P347 (four-shape extension, comparable surface).
**WSJF**: 6 — (12 × 1.0) / 2
**JTBD**: JTBD-001, JTBD-006
**Persona**: plugin-developer

## Description

The relevance-close evaluator (`packages/itil/scripts/evaluate-relevance.sh`, consumed by `/wr-itil:review-problems` Step 4.6 relevance-close pass AND by `/wr-itil:work-problems` Step 3.6 pre-dispatch relevance gate) over-fires: it returned `CLOSE-CANDIDATE` on **61 of 80** open/known-error tickets (**76%**) in the 2026-07-26 review pass, versus the **~4.2%** the skill documents. Every hit carried a `multi-phase-mixed-progress` caveat so the AFK branch closed none of them — but the false-positive storm drowns genuine close-candidates and poisons the work-problems Step 3.6 pre-dispatch relevance gate (this session's loop saw P160 / P426 / P376 / P428 / P437 / P454 / P436 all caveated on the same over-eager signal, routing dispatchable tickets to interactive-review skip).

Root cause: the `ADR-shipped-confirmed` and `named-skill-or-feature-exists` match shapes fire on essentially any governance ticket that merely **CITES** a confirmed ADR or a skill path in its `## Related` / `## Dependencies` section — a citation is read as "the fix shipped". In a governance monorepo where nearly every ticket cross-references confirmed ADRs and skill paths for context, this makes the signal near-constant.

Fix shape: tighten the match shapes so citing a confirmed ADR / skill path does not by itself signal fix-shipped. Require the citation to appear in a **fix-evidence context** (a `## Fix Released` section, or Investigation-Task checkboxes actually ticked) rather than a `## Related` / context reference. Behavioural coverage must assert that a ticket which only cites a confirmed ADR in `## Related` does NOT come back CLOSE-CANDIDATE.

## Symptoms

- `/wr-itil:review-problems` Step 4.6 relevance-close pass reports 61/80 CLOSE-CANDIDATE, all caveated (2026-07-26 pass, commit `5bb88b7f`).
- `/wr-itil:work-problems` Step 3.6 pre-dispatch gate returns CLOSE-CANDIDATE-WITH-CAVEAT on genuinely-open, not-yet-shipped tickets (P426, P376, P428, P437, P454, P436 this session), routing them to interactive-review skip instead of AFK work.
- Genuine close-candidates (e.g. P164, held for a real external-comms reason) are indistinguishable in the noise.

## Workaround

(deferred to investigation) — currently the AFK branch closes nothing on a caveat, so no wrong closures occur; the cost is wasted dispatch decisions + a flooded interactive-review queue, not data loss.

## Impact Assessment

- **Who is affected**: maintainer / plugin-developer running review-problems + work-problems; the AFK orchestrator's Step 3.6 dispatch selection.
- **Frequency**: every review-problems pass and every work-problems Step 3.6 evaluation.
- **Severity**: High (12) — misroutes governance close/dispatch decisions; dev-tooling degraded; no shipped-package harm.
- **Analytics**: 2026-07-26 review pass — 61/80 (76%) CLOSE-CANDIDATE vs ~4.2% documented; work-problems session same date, 7+ dispatchable tickets caveated.

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm the `ADR-shipped-confirmed` + `named-skill-or-feature-exists` match shapes fire on a `## Related`/`## Dependencies` citation with no fix-evidence context.
- [ ] Tighten the predicates: require citation-in-fix-evidence-context (`## Fix Released` present, or Investigation Tasks ticked) rather than any-mention.
- [ ] Behavioural coverage: a ticket citing a confirmed ADR only in `## Related` must NOT return CLOSE-CANDIDATE (extend `packages/itil/scripts/test/evaluate-relevance.bats`).
- [ ] Reconcile the documented ~4.2% expectation with observed behaviour; update the skill doc if the target changed.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P347 (ADR-079 Phase 2 — the four-shape extension that added these predicates), P346 (evaluator/relevance-close master), P385/P386 (work-problems Step 3.6 pre-dispatch relevance gate consumers), P461 (downstream evidence-scan over-firing without version-gating — same over-eager-signal class).

## Related

- Upstream issue **#306** (https://github.com/windyroad/agent-plugins/issues/306) — already describes this evaluator over-firing; currently unmatched to any local ticket. Wire the back-link when confirmed.
- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-26) after the Step 0b review-problems pre-flight surfaced the 76% CLOSE-CANDIDATE rate and flagged it as evaluator over-firing.
- Title-relatives (not duplicates): P347 (extend evaluate-relevance with four evidence shapes), P385/P386 (work-problems pre-dispatch relevance-close), P308 (Rule-4 evidence-floor on evaluator status=resolved).
