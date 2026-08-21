# Problem 463: Relevance-close evaluator over-fires — a bare ADR/skill citation is read as "fix shipped", so live tickets return CLOSE-CANDIDATE

**Status**: Known Error
**Reported**: 2026-07-26
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — **re-rated 2026-08-21 review from observed evidence.** Impact 4 (up from 3): the 2026-08-21 pass produced 7 *clean* `CLOSE-CANDIDATE` verdicts with no caveat, and the shipped AFK branch closes those **silently**. The prior Impact-3 rating rested on the claim that a caveat blocks every close; that claim is now false, so the harm class moves from wasted dispatch decisions to silent loss of live backlog items in any adopter tree running the shipped skill. Likelihood 5 (up from 4): fires on every pass, and the rate is rising (76% on 2026-07-26 → 81% on 2026-08-21).
**Origin**: inbound-reported (#414) — stamped 2026-08-21 review; upstream issue *"wr-itil evaluate-relevance matches ADR numbers across repos and treats Composes-with as fix evidence"* is the external filing of this defect
**Effort**: M — tighten the match-shape predicates in `evaluate-relevance.sh` + author behavioural coverage over the false-positive shapes; cf. P347 (four-shape extension, comparable surface).
**WSJF**: 20 — (20 × 2.0) / 2 (2026-08-21 review: re-rated Priority 12 → 20 on observed evidence; auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0. Severity 20 ≥ 17 = Tier 0 critical-bypass)
**JTBD**: JTBD-006 (primary), JTBD-001 (secondary) — re-anchored 2026-08-21 by the `wr-jtbd:agent` gate; the capture-time header was the AFK auto-capture default.
**Persona**: developer (secondary: plugin-developer) — re-anchored 2026-08-21. The harm lands on whoever runs the loop over their own backlog, which is the `developer` persona JTBD-006 is written for, not the plugin-contributor persona.

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
- [x] Design the tightening: scope shapes 2 and 3 to a fix-evidence region rather than the whole body. **DESIGNED 2026-08-21** — see `## Fix Strategy`. Build is held pending the superseding decision; the option set is queued for the maintainer.
- [ ] Record the decision superseding ADR-079 in part (shape-2 + shape-3 mechanical checks only), then implement the chosen option.
- [ ] Tighten the predicates in `packages/itil/scripts/evaluate-relevance.sh` once that decision is ratified.
- [ ] Behavioural coverage: a ticket citing a confirmed ADR only in `## Related` must NOT return CLOSE-CANDIDATE (extend `packages/itil/scripts/test/evaluate-relevance.bats`).
- [ ] Reconcile the documented ~4.2% expectation with observed behaviour; update the skill doc if the target changed.

## Fix Strategy

**Vehicle**: release row **RFC-070** on **STORY-MAP-011** (Trust the AFK loop's autonomous conduct), activity `close` — *"A close rests on evidence the fix shipped, not on a decision the ticket names"*. Carries one card, **STORY-064**. Drawn 2026-08-21 per ADR-119 (a fix proposal draws a release row, never a document); the row sits beside RFC-056, its nearest sibling on the same activity. Verified: drawing the row and adding the card left STORY-MAP-011's oversight fingerprint intact, so the map stayed ratified and STORY-064 reads as approved.

No RFC document was created and RFC-013 was not amended. ADR-119 retired the RFC document tier — Clause 1 bars a new file under `docs/rfcs/`, and the same decision bars authored edits to legacy files, which is what wiring a P463 trace edge and a Phase 4 block into RFC-013 would have been. The P371 existing-vehicle-untraced path is a document-era mechanic and does not survive ADR-119.

**Design, confirmed but NOT yet authorised to build.** Scope the `ADR-shipped-confirmed` and `named-skill-or-feature-exists` shapes to a *fix-evidence region* of the ticket — the `## Fix Released` and `## Resolution` section bodies plus ticked `- [x]` lines — instead of the whole body. Shapes 1, 4 and 5 are unchanged. Verdict cites should also name **where** the evidence was found, so a verdict is checkable without re-reading the ticket (ADR-026 already obliges the cite; this makes it locating).

**Implementation is held.** ADR-079 records the shape-2 and shape-3 mechanical checks as whole-body greps, inside a ratified Decision Outcome — and it applied exactly this line-anchoring correction to shape 4 while deliberately not applying it to shapes 2 and 3, so the whole-body reading is recorded on purpose. Narrowing it changes recorded substance, and under ADR-116 a ratified decision changes only by supersession. Under ADR-103 implementation is *refused* while a proposal needs an ADR that is not yet ratified. So the fix needs a new decision superseding ADR-079 **in part**, scoped to those two checks, before any code lands.

### The held decision — what should make a mention count as proof a fix shipped?

When a ticket mentions a ratified decision or an existing skill path, what should it take for that mention to count as evidence the ticket's fix has shipped? The measurement establishes the harm; it does not select the remedy.

- **Option A — only count it where the ticket claims a fix landed.** Search just the fix-claim parts (released/resolution sections, ticked-off tasks). A mention in background, dependencies or related work stops counting. Preserves both signals but makes them positional.
- **Option B — stop treating a ratified decision as proof of anything.** Drop that signal and keep only the narrowed skill-path one. Argued by the insight itself: agreeing a decision says nothing about whether anyone built it, and the worst failures are tickets reporting exactly that gap.
- **Option C — keep the searches as they are, but never let these two signals close a ticket silently.** They always emit with a caveat, so a human sees them. Targets the measured harm precisely: the damage came from *clean* verdicts auto-closing unattended.
- **Option D — require corroboration.** Neither signal closes alone; each counts only alongside an independent one (a file genuinely gone, a self-marker, a closed driver).
- **Option E — do nothing**, and handle the 81% rate by suspending the unattended close pass instead.

Architect's advisory lean is a composed **A + C**: A fixes the wrong-region defect at source, and C independently protects the unattended path so a residual false positive surfaces to a human rather than closing silently — that unattended leg is what produced the seven bad closes. Queued for the maintainer 2026-08-21; not guessed at.

### Residual to design against (raised by the JTBD gate)

The evaluator scans **open and known-error** tickets, and `## Fix Released` is machine-written only at the Known Error → Verification Pending transition — so on the population actually being scanned that arm is near-inert, and the case worth catching (a fix that shipped without anyone transitioning the ticket) falls entirely to the ticked-`- [x]` arm. Under the persona constraint *"does not trust the agent to make judgment calls"* the trade is the right way round — a missed close queues for a human, a wrong close is data loss — but the checkbox arm must carry that weight explicitly and be covered behaviourally, and the reconcile-the-~4.2%-expectation task below should land on a measured number rather than on "we turned two shapes off". No new documentation burden: `## Fix Released` is machine-written and the checkboxes come from the ticket template.


## Dependencies

- **Blocks**: (none)
- **Blocked by**: the not-yet-recorded decision superseding ADR-079 in part (shape-2 + shape-3 mechanical checks). ADR-103 refuses implementation while a proposal needs an unratified ADR.
- **Composes with**: P347 (ADR-079 Phase 2 — the four-shape extension that added these predicates), P346 (evaluator/relevance-close master), P385/P386 (work-problems Step 3.6 pre-dispatch relevance gate consumers), P461 (downstream evidence-scan over-firing without version-gating — same over-eager-signal class).

## Related

- Upstream issue **#306** (https://github.com/windyroad/agent-plugins/issues/306) — already describes this evaluator over-firing; currently unmatched to any local ticket. Wire the back-link when confirmed.
- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-26) after the Step 0b review-problems pre-flight surfaced the 76% CLOSE-CANDIDATE rate and flagged it as evaluator over-firing.
- Title-relatives (not duplicates): P347 (extend evaluate-relevance with four evidence shapes), P385/P386 (work-problems pre-dispatch relevance-close), P308 (Rule-4 evidence-floor on evaluator status=resolved).


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-064 | STORY-064: A ticket that only names a decision as background stays open | draft |
