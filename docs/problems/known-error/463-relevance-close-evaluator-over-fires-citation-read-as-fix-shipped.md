# Problem 463: Relevance-close evaluator over-fires — a bare ADR/skill citation is read as "fix shipped", so live tickets return CLOSE-CANDIDATE

**Status**: Known Error
**Reported**: 2026-07-26
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — **re-rated 2026-08-21 review from observed evidence.** Impact 4 (up from 3): the 2026-08-21 pass produced 7 *clean* `CLOSE-CANDIDATE` verdicts with no caveat, and the shipped AFK branch closes those **silently**. The prior Impact-3 rating rested on the claim that a caveat blocks every close; that claim is now false, so the harm class moves from wasted dispatch decisions to silent loss of live backlog items in any adopter tree running the shipped skill. Likelihood 5 (up from 4): fires on every pass, and the rate is rising (76% on 2026-07-26 → 81% on 2026-08-21).
**Origin**: inbound-reported (#414) — stamped 2026-08-21 review; upstream issue *"wr-itil evaluate-relevance matches ADR numbers across repos and treats Composes-with as fix evidence"* is the external filing of this defect
**Effort**: M — tighten the match-shape predicates in `evaluate-relevance.sh` + author behavioural coverage over the false-positive shapes; cf. P347 (four-shape extension, comparable surface).
**WSJF**: 20 — (20 × 2.0) / 2 (2026-08-21 review: re-rated Priority 12 → 20 on observed evidence; auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0. Severity 20 ≥ 17 = Tier 0 critical-bypass)
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
- **2026-08-21 review pass (135 open + known-error tickets)**: 102 `CLOSE-CANDIDATE-WITH-CAVEAT` + 7 clean `CLOSE-CANDIDATE` + 6 `KEEP-WITH-NOTE` + 1 `KEEP` + 19 `SKIP` — an 81% close rate against a documented ~4.2% expectation.
- **The clean-verdict path is the new severity driver.** All 7 clean verdicts were checked by hand and every one is a live ticket: P465 (the story `accepted` gate still does not enforce ADR-090 ratification), P498, P431, P430, P450, P438, P425. P465 is the sharpest case — the evaluator closed it on `ADR-shipped-confirmed` citing ADR-089 / ADR-090 / ADR-095 / ADR-096, which are precisely the confirmed decisions the ticket exists because **nothing enforces**. The shape reads "this ADR is ratified" as "this ADR is implemented".
- The prior Workaround claim — *"the AFK branch closes nothing on a caveat, so no wrong closures occur"* — does not cover the clean-verdict path. In an AFK pass those 7 would have been `git mv`-ed to `closed/` with no prompt.

## Workaround

Do not execute the Step 4.6 relevance-close pass — treat every verdict, clean or caveated, as advisory until the predicates are tightened. This is what the 2026-08-21 review did: the evaluator was run for measurement, the close actions were not applied, and the pass was reported as halted.

Superseded: the earlier note read *"the AFK branch closes nothing on a caveat, so no wrong closures occur; the cost is wasted dispatch decisions, not data loss."* That is false on the clean-verdict path — a clean `CLOSE-CANDIDATE` is closed silently in AFK, and all 7 produced on 2026-08-21 were live tickets.

## Impact Assessment

- **Who is affected**: maintainer / plugin-developer running review-problems + work-problems; the AFK orchestrator's Step 3.6 dispatch selection.
- **Frequency**: every review-problems pass and every work-problems Step 3.6 evaluation.
- **Severity**: High (12) — misroutes governance close/dispatch decisions; dev-tooling degraded; no shipped-package harm.
- **Analytics**: 2026-07-26 review pass — 61/80 (76%) CLOSE-CANDIDATE vs ~4.2% documented; work-problems session same date, 7+ dispatchable tickets caveated.

## Root Cause Analysis

**Confirmed 2026-08-21 review.** The `ADR-shipped-confirmed` shape asserts *citation*, not *resolution*. Its predicate — grep the body for `ADR-NNN`, then check that `docs/decisions/<NNN>-*.md` exists with `human-oversight: confirmed` — is true of any ticket that names a ratified decision for **any** reason: as context, as the decision it is built on, as the governing rule it is reporting a breach of, or as the decision whose enforcement is missing. In this corpus almost every ticket cites several ratified ADRs as framing, which is why the rate is ~81% rather than the documented ~4.2%. `named-skill-or-feature-exists` has the same inversion on a different axis: a ticket naming the skill whose behaviour is defective matches on the skill file existing.

The failure is worst exactly where the ticket is most valuable — a ticket reporting that a ratified decision is unenforced cites that decision by construction, so the shape fires hardest on live enforcement gaps (worked example: P465 above).

### Investigation Tasks

- [x] Confirm the `ADR-shipped-confirmed` + `named-skill-or-feature-exists` match shapes fire on a `## Related`/`## Dependencies` citation with no fix-evidence context. **CONFIRMED 2026-08-21** — see the P465 worked example in Symptoms; the ADRs it matched on are cited in the Description as the decisions nothing implements.
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
