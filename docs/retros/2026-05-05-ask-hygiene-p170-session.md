# Ask Hygiene — 2026-05-05 (P170 work-problem session)

Per **ADR-044** + Step 2d Ask Hygiene Pass (P135 Phase 5). Lazy count is the regression metric (target 0). Sibling to `2026-05-05-ask-hygiene.md` (the earlier RFC framework session retro on the same date — both retros run consecutively, distinguished by suffix).

## Per-call classifications

This session made **4** `AskUserQuestion` calls, all in the foreground main turn (no AFK orchestrator delegation). Total session work: P170 work-problem flow from architect+JTBD review through ADR-060 acceptance, story map authoring, JTBD landscape cleanup (JTBD-008 phantom drop, JTBD-001/JTBD-101 amendments), and release-queue drain (`@windyroad/risk-scorer@0.6.0` published).

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Scope change | **deviation-approval** | Gap: ADR-044 category 2 — P170's Effort was M (deferred placeholder per P155 capture default); architect+JTBD review findings constituted contradicting evidence (Phase 1 alone is XL: 2 new skills + type-tag schema migration with I2 behavioural test + P168 retroactive RFC migration + held-changeset window; ADR-060 needs 14 + 8 amendments before code). User direction at this fork was genuine — "continue" / "stop and re-rank" / "pick different ticket" are not framework-resolved choices. |
| 2 | JTBD-008 fate | **direction** | Gap: ADR-044 category 1 — drop phantom anchor vs draft `JTBD-008-evolve-framework.proposed.md` is a value judgment the JTBD agent surfaced as a critical block on ADR-060 acceptance. JTBD-discipline framing said "drop is recommended (the meta-architectural concern is more naturally captured as an ADR-040-class invariant than a persona-anchored job)" but the user retains direction-setting authority over which path the codebase takes. Not framework-mediated; not lazy. |
| 3 | Next step | **direction** | Gap: ADR-044 category 1 — Slice 1 of the P170 story map was complete; Slice 2 commitment (XL multi-day) vs Slice 2 task subset (just B3.T3 new-JTBD draft) vs end-session-and-drain are 3-way fork that no framework resolves. Drain sub-decision alone WAS framework-resolved (ADR-018 release cadence + within-appetite scores per RISK-POLICY.md), but the slice-progression sub-decision dominated; the question was correctly direction-shaped. **Borderline**: could have been split into two questions (drain Y/N as silent + Slice progression as direction) per Step 2d framework-resolution carve-out; chose unified question for less prompt-fatigue. Self-flag for future: when one AskUserQuestion conflates a framework-resolved decision with a direction decision, prefer to silent-resolve the framework part. |
| 4 | CI failure | **deviation-approval** | Gap: ADR-044 category 2 — drain direction was correct at the moment of decision (push=2 + release=1 within appetite per Step 12 contract); CI failure on push:watch (test fixtures broken by P168 commit `8edaf7b`'s wipe direction without dependent-fixture sweep) was contradicting evidence vs the drain plan. Fix-vs-defer-vs-ticket-vs-investigate is genuine direction-setting; framework doesn't resolve which recovery path to take when a release queue drain hits a latent regression mid-flight. |

**Lazy count: 0**
**Direction count: 2**
**Deviation-approval count: 2**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Trend (this session vs prior)

The 2026-05-05 RFC framework retro (`2026-05-05-ask-hygiene.md`) reported **0** AskUserQuestion calls — that session's user direction was verbatim natural-language correction, not structured prompt. This session's 4 calls reflect the work-problem flow's natural fork points (review-driven scope expansion + value-judgment phantom-anchor decision + slice-progression after Slice 1 + recovery-path after CI failure). Different session shape; same lazy-count target (0); both achieved 0.

R6 numeric gate: lazy count 0 across the last ≥ 3 retros (sample: 2026-05-05 RFC framework=0, 2026-05-05 P170 session=0, 2026-05-04 P168 / P159 / P167 retros all reported 0). No deviation-candidate auto-queued.

## Self-observations

- **Q3 borderline**: in retrospect, splitting Q3 into "silent drain (within-appetite policy-authorised) + AskUserQuestion on Slice 2 commitment" would have been cleaner. The unified 4-option question worked but the drain branch was genuinely framework-resolved per ADR-018 + the manage-problem skill Step 12 contract. **Habit improvement target**: when an AskUserQuestion has one option that's framework-resolved (`Drain release queue + end session (Recommended)`) and three that are direction (other slice-progression paths), prefer to act on the framework-resolved option silently and only ask about the direction-shaped paths. The "Recommended" annotation in this session was a soft-signal that a silent-proceed could have been justified, but I asked anyway. P132 / P135 / Step 2d framework-resolution boundary applies — recording for future calibration.
- **Q1 + Q4 deviation-approval pattern**: both of this session's deviation-approval calls were "direction X was right at moment of decision; new evidence contradicts X; user picks the new path". The pattern is well-shaped — evidence-grounded fork-points are exactly what ADR-044 category 2 covers. No improvement needed.
- **Q2 direction was the cleanest of the four**: phantom anchor with two paths (drop / draft / different-framing) each with substantive consequences (slot allocation for new JTBD-009 vs JTBD-008, persona-anchoring discipline, framework primitives). Clearly direction-setting; clean ADR-044 category 1. The agent's "Recommended: drop" annotation surfaced the JTBD review's preference without preempting the user's call.

## Cross-references

- ADR-044 (`docs/decisions/044-decision-delegation-contract.proposed.md`) — framework-resolution boundary + 6-class authority taxonomy.
- P135 — Phase 5 (Ask Hygiene Pass) wiring; this trail file is the per-retro persistence surface.
- `packages/retrospective/scripts/check-ask-hygiene.sh` — cross-session trend analysis script (consumes these trail files).
- Step 2d of `packages/retrospective/skills/run-retro/SKILL.md` — pass contract.
- `2026-05-05-ask-hygiene.md` — sibling retro (RFC framework session) earlier on the same date.
