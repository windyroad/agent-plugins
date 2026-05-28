---
status: "proposed"
date: 2026-05-28
human-oversight: confirmed
oversight-date: 2026-05-28
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-08-28
---

# Inbound-reported problems rank ahead of internally-discovered problems via a sort tier

## Context and Problem Statement

Problem tickets are ranked by WSJF = (Severity × Status Multiplier) / Effort, where Severity = Impact × Likelihood drawn from `RISK-POLICY.md`. The ordering for selection is the P138 tie-break ladder: WSJF desc → Known-Error-first → effort asc → reported-date asc → ID asc.

This ranking is blind to **where a problem came from**. A problem an external user reported to us (an inbound report, per ADR-062's discovery pipeline) ranks identically to one we found ourselves, if their Impact/Likelihood/Effort happen to match. That blindness has a customer-relationship cost the risk model cannot see: when reporters watch us work on issues they never raised while their own report sits untouched, they conclude they were ignored. They stop reporting (killing a valuable feedback signal) and are more likely to move to a competing set of plugins. Working reported issues first is, before anything else, good customer service — and it protects the feedback channel that surfaces the problems we most need to know about.

"This was reported to us" is therefore not a *risk* fact (it does not change how severe or how likely a problem is); it is a *Cost-of-Delay / Time-Criticality* fact — the value of fixing it decays as the reporter loses faith. That dimension is orthogonal to Impact × Likelihood and must not be smuggled into the risk axes, which are read by a second consumer (the risk-scorer's release-risk gate) that trusts them to mean what they say.

A decision is needed now because the maintainer is about to run a problem review that will identify which open tickets were reported upstream, and wants the ranking to honour reported-first before that review runs.

## Decision Drivers

- **Customer-service / feedback-signal preservation** — ignored reporters disengage, stop reporting, and churn; the feedback signal they provide is high-value and hard to replace.
- **Reported-ness is a Cost-of-Delay dimension, orthogonal to risk** — it must not be encoded by inflating Impact or Likelihood, because those axes are shared with the risk-scorer release-risk gate and must remain honest (ADR-026 grounding; `RISK-POLICY.md` likelihood semantics).
- **The requirement is a tier, not a nudge** — "for all but the most critical issues, work on reported stuff first" demands a partition with an explicit escape, not a re-weight that merely shifts position within one continuous ranking.
- **Keep the risk model honest** — the WSJF formula and its frozen 1/2/4/8 divisor (ADR-067) must stay untouched so downstream consumers are not polluted.
- **Explicit, auditable policy over magic-number tuning** — tier membership is a readable reason ("this is a reported ticket"); a multiplier is an opaque number whose "except most critical" behaviour is an emergent artifact of tuning.

## Considered Options

1. **Inflate Likelihood for reported tickets** — raise the Likelihood score on reported tickets to push them up the ranking.
2. **Reported Multiplier in the WSJF numerator** — add `× Reported Multiplier` (≈3–4×) to the formula, mirroring the existing Status Multiplier.
3. **Sort tier only** — add a top-level sort partition (critical-bypass → reported → internal) above the WSJF ranking, leaving Likelihood scoring untouched.
4. **Sort tier + honest likelihood re-score** — option 3, plus re-score Likelihood upward on its own merits where an inbound report is genuine "previously observed" evidence, framed as honest risk-keeping rather than a prioritisation lever.

## Decision Outcome

Chosen option: **"Sort tier + honest likelihood re-score"** (option 4), because it expresses the requirement literally as a tier with an explicit critical escape, operates purely at the sort/selection layer where the P138 tie-break ladder already lives (leaving the ADR-067-frozen WSJF formula and divisor untouched), keeps the risk axes honest for the release-risk gate, and still captures the legitimate observation-evidence that a real-world report provides.

**The tier (top sort-partition).** The selection order gains a top-level partition. Each tier is internally ranked by the existing WSJF + full P138 tie-break ladder:

```
Tier 0  Critical bypass  — Severity Very High (≥17) OR security-classified OR incident-linked
Tier 1  Inbound-reported — ticket originated from an external inbound report
Tier 2  Internal         — everything else
```

The tier key sits ABOVE WSJF-desc; within each tier the unchanged ladder applies (WSJF desc → Known-Error-first → effort asc → reported-date asc → ID asc). Verification-Pending and Parked tickets remain excluded from ranking regardless of origin (ADR-022).

**The honest likelihood re-score.** Where an inbound report is genuine evidence that a failure was observed in the field, Likelihood may be re-scored upward on its own merits — up to `RISK-POLICY.md` level 5 ("previously observed failure mode"). This is correct risk-keeping justified by observation evidence; it is explicitly **not** the prioritisation mechanism (the tier is). Re-scoring Likelihood *in order to* lift rank is forbidden — that is option 1, which this ADR rejects.

**The inbound-origin marker.** Ranking must not depend on the regenerable `.upstream-cache.json`. A new on-ticket body field records origin, adjacent to the existing `**Status**` / `**Reported**` / `**Priority**` bullets in the manage-problem ticket template:

```
**Origin**: inbound-reported (#NN)   ← external inbound report, NN = upstream issue number
**Origin**: internal                  ← internally discovered (default)
```

It is a body bullet (not YAML — problem tickets follow the ADR-060 grandfathered body-bullet convention, as ADR-067 did for its estimate fields), and it is distinct from the `## Reported Upstream` section, which records the *outbound* direction (a ticket we reported up to someone else). ADR-062's safe-and-valid branch — which already creates the local ticket and knows `matched_local_ticket: P<NNN>` — is the natural writer and stamps `**Origin**` at ticket creation. The cache's `matched_local_ticket` linkage remains the audit/replay record; the on-ticket field is the authoritative rank input.

## Consequences

### Good

- Reporters see their issues worked first; the feedback signal and customer relationship are protected (advances JTBD-301's "unacknowledged reports" pain point).
- The WSJF formula and frozen divisor are untouched (ADR-067 satisfied); the risk axes stay honest for the release-risk gate.
- "Except the most critical" is an explicit, auditable policy (the critical-bypass tier), not emergent magic-number behaviour.
- Reuses the established categorical-tier idiom already present in the P138 ladder (Known-Error-first), so low architectural novelty.
- Origin becomes a first-class, deterministic, on-ticket fact independent of cache rebuilds.

### Neutral

- Within a tier, ordering is unchanged — a reported low-severity ticket still sits below a reported high-severity one.
- The honest likelihood re-score may, on its own merits, also lift a reported ticket inside its tier; that is correct risk-keeping, not double-counting the origin.

### Bad

- Adds a top-level sort key that every ranking surface must apply identically — a new drift-sync obligation under the P138 contract (mitigated by the enumerated Confirmation checklist below).
- Existing open tickets carry no `**Origin**` field until backfilled; until then they default to `internal` and the upcoming problem review must stamp reported ones.
- A long-lived internal high-WSJF ticket can now be outranked by newer reported tickets — intended, but it can defer internally-found work; the critical-bypass tier limits the blast radius to non-critical internal work.

## Confirmation

This change amends the P138 tie-break ladder, which has a hard drift contract (`manage-problem` SKILL.md, ladder drift note): any change to the ladder MUST update every replicated surface in the same change, or it re-opens P138. Implementation is verified when ALL of the following carry the three-tier partition above the existing ladder, identically (line numbers are source-verified anchors and may shift):

- [ ] `packages/itil/skills/work-problems/SKILL.md` — Step 3 canonical `<!-- TIE-BREAK-LADDER-SOURCE -->` block (ladder at ~:258–262) AND the Step 1 README-order note (~:195)
- [ ] `packages/itil/skills/manage-problem/SKILL.md` — Step 9c ranked-table render block (~:778), the Step 7 P062 README-refresh block, the ladder drift-contract note, and the ticket template (~:450–455)
- [ ] `packages/itil/skills/review-problems/SKILL.md` — Step 3 ordering (~:222) and Step 5 README render template (~:778)
- [ ] `docs/problems/README.md` row ordering reflects the three tiers on next refresh

And for the origin marker + likelihood re-score:

- [ ] `packages/itil/skills/manage-problem/SKILL.md` ticket template (~:450–455) defines the `**Origin**` body field with `inbound-reported (#NN)` / `internal` values
- [ ] ADR-062's safe-and-valid branch (the `/wr-itil:capture-problem` invocation in the pipeline) stamps `**Origin**: inbound-reported (#NN)` at ticket creation
- [ ] `review-problems` Step 2 likelihood re-assessment (~:41) carries the honest-likelihood-re-score guidance, explicitly framed as observation-evidence risk-keeping (not a rank lever) and citing `RISK-POLICY.md` level 5
- [ ] The WSJF formula and the 1/2/4/8 divisor are unchanged (ADR-067 Confirmation item 4 still holds)
- [ ] Verification-Pending / Parked exclusion still holds across all tiers (ADR-022)

## Pros and Cons of the Options

### Option 1 — Inflate Likelihood

- Good: zero new mechanism; uses an existing field.
- Bad: corrupts the shared `RISK-POLICY.md` Likelihood semantic read by the risk-scorer release-risk gate (ADR-026 grounding violation — an ungrounded number).
- Bad: too weak — Likelihood caps at 5, so it cannot guarantee "reported first" when a ticket is already at 3–4.
- Bad: couples multiplicatively with Impact in ways that are hard to reason about.

### Option 2 — Reported Multiplier in the WSJF numerator

- Good: mirrors the existing Status Multiplier idiom; keeps Impact/Likelihood honest.
- Bad: only nudges within one continuous ranking — cannot guarantee a hard "reported first" tier (a low-effort high-severity internal ticket can out-score a reported one at any finite multiplier).
- Bad: "except most critical" becomes emergent magic-number tuning, not explicit policy.
- Bad: changes the WSJF formula shape, which ADR-067 asserts ownership over (it froze the formula and routed changes through a follow-up ADR).

### Option 3 — Sort tier only

- Good: literal match to the requirement; leaves the WSJF formula and divisor untouched; reuses the Known-Error-first tier idiom; auditable.
- Bad: discards the legitimate "we now have field-observation evidence" signal an inbound report provides.

### Option 4 — Sort tier + honest likelihood re-score (chosen)

- Good: all of option 3's strengths, plus it captures the honest observation-evidence likelihood signal as correct risk-keeping.
- Bad: requires care in framing — the re-score must be presented as risk-keeping, not a rank lever, or it re-opens the option-1 conflict.
- Bad: adds the drift-sync obligation across the P138 surfaces (shared with option 3).

## Reassessment Criteria

Revisit this decision if:

- The critical-bypass tier proves too broad or too narrow in practice (e.g. internally-found critical work is starved, or genuinely-urgent reported work is blocked behind the bypass tier).
- Reported volume grows enough that the reported tier itself needs sub-prioritisation beyond the WSJF ladder.
- ADR-067's deferred divisor/formula work lands and changes the within-tier ranking assumptions.
- The honest-likelihood-re-score guidance is observed being used as a rank lever (the option-1 anti-pattern re-emerging), indicating the framing failed.

## Related

- **Amends** P138 tie-break ladder (`docs/problems/known-error/138-...`) — adds a tier above the ladder; see Confirmation for the full drift-sync surface list.
- **Extends** [ADR-062](062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md) — consumes the `matched_local_ticket` linkage and closes the on-ticket-marker gap via the `**Origin**` field; the pipeline's safe-and-valid branch becomes the Origin writer.
- **Relates to** [ADR-067](067-cost-based-wsjf-effort-tally-first-with-retro-rms-calibration.proposed.md) — the WSJF formula and 1/2/4/8 divisor stay frozen; this tier sits at the sort layer, not the score.
- **Relates to** ADR-026 (agent output grounding) — the load-bearing constraint behind the "honest likelihood re-score is not a rank lever" rule; reported-ness stays out of the risk axes the release-risk gate shares.
- **Composes with** ADR-022 — Verification-Pending / Parked exclusions hold across all tiers.
- **Advances** JTBD-301 (plugin-user — report without pre-classifying) and sits within JTBD-006 (developer — AFK backlog ordering).
- **Commit grain** per ADR-014 — implementation lands across the synced surfaces in appropriately-grained commits.
