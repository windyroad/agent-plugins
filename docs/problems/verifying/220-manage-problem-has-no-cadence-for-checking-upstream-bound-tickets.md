# Problem 220: manage-problem has no cadence for checking upstream-bound tickets

**Status**: Verification Pending
**Reported**: 2026-05-15
**Origin**: inbound-reported (#63)
**Phase 1 fix landed**: 2026-06-08 — `/wr-itil:work-problems` Step 0d pre-flights `/wr-itil:check-upstream-responses` when the outbound-responses cache is stale or missing AND back-link tickets exist (symmetric to Step 0b's inbound pre-flight). K → V transition deferred to release per ADR-022 P143 fold-fix amendment.
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`wr-itil:manage-problem` defines two terminal states for tickets that aren't being actively worked: `.parked.md` (excluded from WSJF ranking, listed separately) and `.open.md` carrying a `## Reported Upstream` section (still ranked, still surfaced). Neither state describes a cadence for checking whether the upstream has shipped a fix — the maintainer must remember to check manually.

P249 Phase 1 (shipped 2026-05-18, `@windyroad/itil@0.34.0`) provided the manual `/wr-itil:check-upstream-responses` skill but explicitly deferred cadence wiring (SKILL.md line 40: *"Future iter will wire `/wr-itil:work-problems` Step 0c pre-flight … Phase 1 ships manual-invocation only"*). This ticket is the cadence-wiring follow-up. Slot is Step 0d (Step 0c is taken by P271's deferred-placeholder pre-flight).

## Workaround

Manually check `gh issue view <id>` for each upstream-bound ticket periodically, or invoke `/wr-itil:check-upstream-responses` on demand.

## Impact Assessment

- **Severity**: Moderate — upstream-bound tickets age silently; local closure depends on maintainer memory.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems (deferred — placeholder; carried into K → V transition)
- [x] Architect call: extend pre-flight surface — verdict 2026-06-08 = Step 0d in `/wr-itil:work-problems` (NOT review-problems Step 4.5). Discrete intent per ADR-010 skill-granularity; symmetric to Step 0b inbound pipeline. APPROVED-WITH-CONDITIONS (ADR-062 Confirmation amendment + drift-source markers + adopter-portable PATH shim per ADR-049/080).
- [x] JTBD review: PASS — JTBD-006 primary anchor (AFK orchestrator pre-flight), JTBD-004 secondary (cross-repo coordination outbound axis). No new JTBD required; bidirectional axis fits inside existing job definitions.
- [x] Phase 1 fix implemented: `packages/itil/lib/check-outbound-responses-staleness.sh` + `packages/itil/scripts/run-check-outbound-responses-staleness.sh` + `packages/itil/bin/wr-itil-check-outbound-responses-staleness` + Step 0d block in `packages/itil/skills/work-problems/SKILL.md` + tightened `packages/itil/skills/check-upstream-responses/SKILL.md` Invocation surface + ADR-062 Confirmation #5 amended + drift-source contract anchors at all three round-trip sites + behavioural bats `packages/itil/skills/work-problems/test/work-problems-step-0d-outbound-responses-staleness-behavioural.bats` (10/10 GREEN).
- [ ] Sibling: P063 (external-root-cause lineage marker — auto-Verifying when upstream resolves). Step 0d's `STATE` class output is the natural input for P063's auto-transition logic, deferred to a separate iter.

## Fix Strategy

Phase 1 (shipped): wire `/wr-itil:work-problems` Step 0d outbound-responses pre-flight — TTL-staleness helper + PATH shim + SKILL block + behavioural bats. See Investigation Tasks for the file inventory.

**Release vehicle**: .changeset/p220-step-0d-outbound-responses-preflight.md (currently held at `docs/changesets-holding/p220-step-0d-outbound-responses-preflight.md` per ADR-042 R009 auto-apply; attribution-only — the fix code shipped in published 0.49.x regardless; graduation rides the next Step 6.5 cohort pre-check)

## Fix Released

**Phase 1 source landed**: 2026-06-08 (this commit). Files:

- `packages/itil/lib/check-outbound-responses-staleness.sh` — sourceable helper; function `should_promote_outbound_responses_preflight` returns one of five outcomes (no-back-link-tickets / first-run-cache-absent / first-run-last-checked-null / fresh-within-ttl / ttl-expiry).
- `packages/itil/scripts/run-check-outbound-responses-staleness.sh` — adopter-safe wrapper (P317/RFC-009 — sources lib relative to script, not cwd).
- `packages/itil/bin/wr-itil-check-outbound-responses-staleness` — ADR-049/080 PATH shim, generated from `packages/shared/lib/shim-wrapper-template.sh` via `npm run sync:shim-wrappers --check` (all 48 shims drift-free).
- `packages/itil/skills/work-problems/SKILL.md` — new Step 0d section between Step 0c and Step 1; JTBD-006 + JTBD-004 anchors; drift-contract-source marker.
- `packages/itil/skills/check-upstream-responses/SKILL.md` — Invocation surface lines 40 + 104 rewritten present-tense; Confirmation #7 added with drift-contract-source marker.
- `docs/decisions/062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md` — Confirmation #5 amended with Step 0d clause.
- `packages/itil/skills/work-problems/test/work-problems-step-0d-outbound-responses-staleness-behavioural.bats` — 10 behavioural cases (5 outcomes + dual-tolerant layout coverage + custom-TTL + default-TTL).

**Released**: `@windyroad/itil@0.49.4` (published 2026-06-10, release commit 333e24fc) — fix code tarball-verified present from 0.49.3 (2026-06-08); ADR-022 release condition met. One-sentence fix summary: `/wr-itil:work-problems` Step 0d now pre-flights `/wr-itil:check-upstream-responses` on TTL-staleness, closing the upstream-bound-ticket cadence gap. Awaiting user verification. Recovery path: `/wr-itil:transition-problem 220 known-error` (verifying flip-back) if a regression is observed.

**Update 2026-06-11 (AFK iter evidence note)**: the fix is **de facto released** — published `@windyroad/itil@0.49.3` tarball verified (via `npm pack`) to contain all Phase 1 files (Step 0d SKILL prose ×9 mentions, `lib/check-outbound-responses-staleness.sh`, `scripts/run-check-outbound-responses-staleness.sh`, `bin/wr-itil-check-outbound-responses-staleness`, behavioural bats). Changeset holding withholds changelog/version attribution only, not code — the 0.48.0/0.49.x releases (2026-06-08) published main's package contents including commit 0f58210c. The held changeset's **reinstate criterion is also met**: paired work-problems promptfoo Tier-A/B eval landed in 0.47.15 (P324 Phase 1, 9/9 GREEN), flipping the R009 modulator +1 → -1 for the whole 6-changeset work-problems cohort. K→V transition + changeset graduation remain staged through the orchestrator's Step 6.5 cohort-graduation pre-check (Rule 4 evidence floor — orchestrator-owned, not iter-owned); this note exists so the lifted deferral condition is not mis-parsed as still-pending (P184 class).

## Change Log

- **2026-05-15**: Captured. Placeholder Priority/Effort pending review-problems re-rate.
- **2026-06-08** (session 11 iter): Phase 1 fix implemented. Step 0d wired into `/wr-itil:work-problems` via PATH shim + sourceable lib + behavioural bats (10/10 GREEN). Architect verdict APPROVED-WITH-CONDITIONS (ADR-062 Confirmation amendment + drift-source markers honoured). JTBD verdict PASS (JTBD-006 + JTBD-004 anchors). Status remains Known Error until release per ADR-022 P143 fold-fix amendment.
- **2026-06-11** (AFK iter 2): Verification-pending classification confirmed; no Phase 2 scope remains (sole unticked Investigation Task is sibling P063's scope, explicitly a separate iter). Evidence note added to Fix Released: fix de-facto released in published 0.49.x (tarball-verified); held changeset reinstate criterion met via 0.47.15 eval (P324 Phase 1). Graduation + K→V left to orchestrator Step 6.5 cohort pre-check per Rule 4 evidence floor.
- **2026-06-11** (AFK iter 2, same session, later): **K → V transition executed** per orchestrator delegation. `@windyroad/itil@0.49.4` published 2026-06-10 (release commit 333e24fc) — ADR-022 release condition met. P184 conditional-deferral check: proceed-silently (sole unticked task is sibling P063's scope, an explicit scope-split to an existing sibling ticket; the "K→V deferred to release" condition is the one this transition discharges). P330 Release-vehicle seeded. Note: the 0.49.4 drain graduated the P206/P211/P212/P228 cohort siblings but `p220-step-0d-outbound-responses-preflight.md` remains in `docs/changesets-holding/` — attribution-only; code shipped regardless; graduation rides the next Step 6.5 cohort pre-check.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/63
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Composes with**: P063 (external-root-cause lineage marker; Step 0d's STATE output is natural P063 input), P070 (semantic-comparator infrastructure), P249 Phase 1 (the manual skill this step wires into a cadence), P271 (Step 0c sibling — deferred-placeholder pre-flight), P317/RFC-009 (adopter-safe PATH shim grammar), ADR-014 (commit grain), ADR-022 P143 fold-fix amendment (K → V on release), ADR-024 (back-link `## Reported Upstream` is source-of-truth scanned by the helper), ADR-049 (PATH shim), ADR-062 (inbound discovery — Confirmation amended for outbound symmetric counterpart), ADR-080 (highest-version-wins shim wrapper).

## Upstream Lifecycle Updates

- **2026-06-23** — Known Error → Verification Pending (inbound)
  - **Target**: inbound #63 (own repo windyroad/agent-plugins)
  - **Comment URL**: https://github.com/windyroad/agent-plugins/issues/63#issuecomment-4775050591
  - **Disclosure path**: posted-inbound-comment
  - **Gate verdict**: external-comms PASS + voice-tone PASS
  - **Retroactive catchup**: dispatched via per-ticket invocation in the 2026-06-23 update-upstream catchup session (the bundled --catchup scanner only scans the outbound `## Reported Upstream` surface; inbound `**Origin**: inbound-reported (#NN)` catchup scope is the scanner's extension gap, captured separately).
