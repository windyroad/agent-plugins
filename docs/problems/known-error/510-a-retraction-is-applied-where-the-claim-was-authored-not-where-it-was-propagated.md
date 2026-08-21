# Problem 510: A retraction is applied where the claim was authored, not where it was propagated

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture. Impact 3: the surviving copy sits on the work item an implementer enters from, so it routes real work off a claim its own source has withdrawn; repo-local, no published surface. Likelihood 4: high path-count with no control — every corrected governance artefact has citers, no back-link exists from a claim to them, and six review rounds across two gates all fired on the corrected artefact and none on its citer.
**Origin**: internal
**Effort**: M — derived at capture. The check is narrow (does a ticket's Direction agree with the ADR it produced), but there is no citation back-edge to walk, so building one is the bulk of the work.
**WSJF**: 12 — (12 × 2.0) / 2 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-001
**Persona**: developer

## Description

When a claim is retracted in one artefact, nothing sweeps the artefacts that cite it. The retracted version keeps teaching from the citing surface — and the citing surface is usually the one an implementer enters from.

**Observed 2026-08-20.** ADR-119 was drafted asserting that the existing `docs/rfcs/` corpus becomes "read-only history". Review established this was false on the facts (only 1 of 60 documents is closed; 59 carry live plans), and the ADR was corrected across three architect rounds to say so explicitly, in its own voice.

But P508 — the problem ticket that **produced** that ADR — still carried the original clause verbatim in its `## Direction — 2026-08-20` section, under a heading announcing itself as settled: *"This resolves the two tasks that blocked the rest of this ticket."* It did not name ADR-119 in its `## Related` list at all.

The asymmetry is what makes it dangerous. **The ticket is what `/wr-itil:work-problems` traverses; the ADR is not.** An implementer entering at the ticket would have read the retracted clause and frozen 59 live documents, silently displacing ADR-085's `## Commits` re-render and ADR-107's derived map list — both driven by shipped scripts that still write to those files.

Three architect rounds and three JTBD rounds all fired on the ADR. None looked at the ticket. Only the risk scorer caught it, at the last gate before commit, and only because its scope is the whole staged diff rather than one artefact.

## Symptoms

- A corrected artefact and its driving ticket disagree, with the ticket carrying the withdrawn version.
- The disagreement survives every review gate, because each gate is scoped to the artefact under review.
- The stale copy reads as settled — it is usually in a section written to record a resolution.
- Nothing links a claim to the places that restated it, so there is nothing to walk even if someone wanted to.

## Workaround

Notice it. The one instance here was caught by the risk scorer's whole-diff scope, which is luck rather than design — a correction landing in a commit that touches only the corrected artefact would not have been caught at all.

## Impact Assessment

- **Who is affected**: anyone implementing from a ticket whose ADR has since been corrected — including the AFK loop, which traverses tickets and never reads the ADR unless a task tells it to.
- **Frequency**: latent on every retraction. One observed instance, caught at the last possible gate.
- **Severity**: routes work off a withdrawn claim. The observed instance would have broken two ratified decisions' shipped renderers.
- **Analytics**: none. Nothing counts retractions, citers, or disagreements between a ticket and the decision it produced.

## Root Cause Analysis

A retraction is applied at the **authoring site**. Propagation is one-way and lossy: a ticket restates an ADR's clause inline, in its own words, at a moment when both agreed. Nothing records that the restatement happened, so nothing can find it later.

Two contributing gaps:

1. **No citation back-edge.** Forward references exist (a ticket's `## Related` can name an ADR); the reverse does not. There is no way to ask "what restates this clause?"
2. **Review scope is per-artefact.** Each gate reviews the file it was invoked on. A disagreement between two files is nobody's finding unless a reviewer happens to hold both.

### Investigation Tasks

- [ ] Decide the mechanism: an amendment-time back-propagation sweep, a driving-ticket-agrees-with-its-ADR check, or a citation back-edge that makes the sweep possible
- [ ] Settle what counts as a citer — an explicit `## Related` link, an inline restatement in prose, or both. The observed instance had the second and not the first, which is the harder case
- [ ] Decide where it fires: at retraction time (the corrector sweeps), at ratification (the marker refuses while a citer disagrees), or at commit (the risk scorer's whole-diff scope generalised)
- [ ] Check whether the ADR→ticket edge is the only one worth covering, or whether JTBD→ADR and story→map carry the same shape
- [ ] Write a behavioural test: a ticket restating a clause its ADR later retracts is detected

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P434, P452, P482, P416

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over five candidates, on the grounds that this root cause is **directional** — the retraction was correctly applied at the authoring site and never propagated back down the citation edge.

- **P434** (`docs/problems/known-error/434-…md`) — closest, and still distinct. Its own root-cause statement scopes it to capture-time truth discipline, and both its bricks fire at intake, testing a **new** claim against the world at write time. This claim *was* tested — three rounds falsified it. What failed is that nothing walked from the corrected ADR to its citer. P434's 2026-08-21 third scope extension is read-side (the reader re-verifies); this is write-side (the retractor sweeps) — opposite ends of the same edge. P434 is also a Known Error whose fix is held with RFC-057 / STORY-053 / STORY-MAP-011 already authored against a two-brick scope.
- **P452** (`docs/problems/open/452-…md`) — same family, narrower surface: one artefact type and one queue schema. No queue is involved here.
- **P482** (`docs/problems/open/482-…md`) — citation *address* drift, not citation *content* retraction. A stable anchor makes citations survive amendment; it does not detect that a citer's inlined copy now contradicts its source.
- **P507** (`docs/problems/open/507-…md`) — shares only the abstract "signal emitted, not acted on" shape. No surfacer emitted anything here, because no back-link existed for one to read.
- **P508** (`docs/problems/open/508-…md`) — the site of the observation, not its parent. The specific instance is already remediated there (the retraction is carried, and ADR-119 is now named first in its Related list).
- **P416** — flagged by the arbiter as a likely cluster sibling the pre-filter missed: P452 describes it as the post-decision reconciliation side of this same family. Unread at capture; no absorption claim made. Worth checking at the next `/wr-itil:review-problems` pass.
