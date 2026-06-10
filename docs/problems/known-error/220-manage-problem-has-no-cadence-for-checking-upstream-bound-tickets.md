# Problem 220: manage-problem has no cadence for checking upstream-bound tickets

**Status**: Known Error
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

## Fix Released

**Phase 1 source landed**: 2026-06-08 (this commit). Files:

- `packages/itil/lib/check-outbound-responses-staleness.sh` — sourceable helper; function `should_promote_outbound_responses_preflight` returns one of five outcomes (no-back-link-tickets / first-run-cache-absent / first-run-last-checked-null / fresh-within-ttl / ttl-expiry).
- `packages/itil/scripts/run-check-outbound-responses-staleness.sh` — adopter-safe wrapper (P317/RFC-009 — sources lib relative to script, not cwd).
- `packages/itil/bin/wr-itil-check-outbound-responses-staleness` — ADR-049/080 PATH shim, generated from `packages/shared/lib/shim-wrapper-template.sh` via `npm run sync:shim-wrappers --check` (all 48 shims drift-free).
- `packages/itil/skills/work-problems/SKILL.md` — new Step 0d section between Step 0c and Step 1; JTBD-006 + JTBD-004 anchors; drift-contract-source marker.
- `packages/itil/skills/check-upstream-responses/SKILL.md` — Invocation surface lines 40 + 104 rewritten present-tense; Confirmation #7 added with drift-contract-source marker.
- `docs/decisions/062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md` — Confirmation #5 amended with Step 0d clause.
- `packages/itil/skills/work-problems/test/work-problems-step-0d-outbound-responses-staleness-behavioural.bats` — 10 behavioural cases (5 outcomes + dual-tolerant layout coverage + custom-TTL + default-TTL).

**Release pending**: K → V transition deferred until `@windyroad/itil` next release per ADR-022 P143 fold-fix amendment. Recovery path: `/wr-itil:transition-problem 220 known-error` after reverting this commit.

## Change Log

- **2026-05-15**: Captured. Placeholder Priority/Effort pending review-problems re-rate.
- **2026-06-08** (session 11 iter): Phase 1 fix implemented. Step 0d wired into `/wr-itil:work-problems` via PATH shim + sourceable lib + behavioural bats (10/10 GREEN). Architect verdict APPROVED-WITH-CONDITIONS (ADR-062 Confirmation amendment + drift-source markers honoured). JTBD verdict PASS (JTBD-006 + JTBD-004 anchors). Status remains Known Error until release per ADR-022 P143 fold-fix amendment.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/63
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
- **Composes with**: P063 (external-root-cause lineage marker; Step 0d's STATE output is natural P063 input), P070 (semantic-comparator infrastructure), P249 Phase 1 (the manual skill this step wires into a cadence), P271 (Step 0c sibling — deferred-placeholder pre-flight), P317/RFC-009 (adopter-safe PATH shim grammar), ADR-014 (commit grain), ADR-022 P143 fold-fix amendment (K → V on release), ADR-024 (back-link `## Reported Upstream` is source-of-truth scanned by the helper), ADR-049 (PATH shim), ADR-062 (inbound discovery — Confirmation amended for outbound symmetric counterpart), ADR-080 (highest-version-wins shim wrapper).
