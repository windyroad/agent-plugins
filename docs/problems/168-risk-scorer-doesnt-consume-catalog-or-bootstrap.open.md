# Problem 168: Risk-scorer doesn't consume `docs/risks/` catalog or bootstrap from `.risk-reports/`

**Status**: Open
**Reported**: 2026-05-04
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

User direction (2026-05-04, follow-up to P167): the risk-scorer agent should:

(a) **Bootstrap-from-empty**: when `docs/risks/` is empty (or has only README + TEMPLATE), walk `.risk-reports/` to derive and document the risk classes previously surfaced. One-time pass, transparent to the user — same job ADR-047 Phase 3 deferred.

(b) **Consume-catalog on every per-action assessment**: READ `docs/risks/` first, filter to risks applicable to THIS action, assess whether documented controls are in effect for this action, compute residual against the **same 4/Low appetite**, append any newly-conceived risk classes back to the catalog (ADR-047 Phase 2 back-channel).

Today the agent does **neither**. Every commit/push/release/external-comms assessment regenerates risk classes from scratch. The gap-analysis Explore agent (invoked from P167's session) found ~327 unique risk titles across 181 reports clustering into 12-14 themes — order-of-magnitude duplication of the same risk-class derivation effort, with no carry-forward.

User's framing: this is wasted effort plus a missed-risk-class hazard. The agent might omit a risk it has surfaced before because it didn't think of it this assessment.

The catalog framing landed in `RISK-POLICY.md` commit `9e339d0` (new `## Risk Catalog` section) — the policy now describes the consume-catalog and bootstrap-from-empty workflow explicitly. But no agent implements it.

User direction also includes **wiping the existing 6 R<NNN> entries before bootstrap** so:
- The bootstrap behaviour can be tested on an empty catalog.
- The existing entries (authored under pre-correction conservatism — particularly RC2 controls undercredited per P167) are replaced with bootstrap-derived entries that apply the new `## Control Composition` rule (RISK-POLICY.md commit `9e339d0`).

This ticket **supersedes** P167's original Phase 1-3 plan (manual R007-R011 authoring + R002/R005 extensions + R001-R006 re-rate). The bootstrap approach replaces all three.

## Symptoms

- 6 standing risks in `docs/risks/`, but ~327 unique risk titles across 181 `.risk-reports/` — register coverage is ~1.8% of surfaced risk classes (RC1 from P167, empirically confirmed).
- Per-action assessments regenerate risk classes from scratch on each invocation; no continuity across sessions.
- Same risk classes surface repeatedly (e.g. "ADR drift", "hook regression", "register drift") with the agent re-deriving the assessment each time.
- Risk classes that haven't been documented can be missed in a later assessment if the agent doesn't think of them.
- Authoring 6 standing risks manually under pre-correction conservatism produced residuals that mostly read above appetite (R001:9, R002:8, R003:5, R004:6, R005:12, R006:8) — gap analysis from P167 attributes this to RC1+RC2 (sparse coverage + undercredited controls), both of which the bootstrap approach is positioned to address structurally.

## Workaround

(deferred to investigation — current state is "agent regenerates risks each assessment", which is the wasted-effort cost the user named explicitly. No interim mitigation other than the manual-authoring path P167 originally proposed, which is itself superseded.)

## Impact Assessment

- **Who is affected**: plugin-maintainer (every commit / push / release pays the regeneration cost), tech-lead persona reading risk reports (sees the same risk classes re-derived inconsistently across assessments), solo-developer persona governance flow (per-action assessments under-leverage the persistent catalog and may miss risk classes).
- **Frequency**: every per-action risk assessment — typically multiple per session. 181 cumulative reports observed in this project alone.
- **Severity**: Medium — wasted compute + cognitive load every assessment, plus the missed-risk-class hazard. False-negative on a risk class the agent "forgets to think of" can let an action proceed when it should have been gated.
- **Analytics**: count of distinct risk titles per `.risk-reports/` entry vs catalog size; ratio measures the regeneration-vs-reuse efficiency.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next `/wr-itil:review-problems`
- [ ] Architect review: design contract for the bootstrap-from-empty behaviour. Open questions: where does the bootstrap fire (SessionStart hook? agent SKILL.md preamble? marker-gated one-shot?); how does it dedupe risk classes across 181 reports; what's the threshold for "this risk class warrants a standing entry"; what citation back to source `.risk-reports/` does the bootstrap-derived entry carry.
- [ ] Architect review: design contract for the consume-catalog behaviour on every per-action assessment. Open questions: how does the agent filter the catalog to "risks applicable to THIS action"; what's the agent's protocol for adding a newly-conceived risk class back to the catalog (auto-write vs surface-only); how does the agent reconcile the catalog's residual with the per-action residual when controls applied for this action differ.
- [ ] JTBD review: which persona jobs are served by the bootstrap-from-empty + consume-catalog behaviour. Likely JTBD-001 (governance without slowing), JTBD-202 (pre-flight checks), JTBD-201 (audit trail).
- [ ] Decide: is wiping `docs/risks/` R001-R006 part of this ticket's scope, or a separate transition step? Tradeoff: wipe-first means the bootstrap is genuinely tested; preserve-and-merge means existing register effort is not lost.
- [ ] Decide: which agent owns the bootstrap behaviour — `wr-risk-scorer:pipeline` (the per-action scorer), a new dedicated bootstrap skill, or extend `/wr-risk-scorer:create-risk` to detect the empty-catalog case.
- [ ] Decide: does this ticket warrant a new ADR or an in-window amendment to ADR-047 (Phase 2/3 promote-to-active). Architect verdict on P167 already named ADR-047 amendment as the cheaper alignment surface for the gap-analysis methodology.
- [ ] Create reproduction test: register-coverage assertion (extending the P167 investigation task that asked for the same). The bootstrap should produce a catalog where ≥80% of `.risk-reports/` themes have a corresponding R<NNN> entry.
- [ ] Test the bootstrap on an empty catalog: wipe `docs/risks/R001-R006`, run the bootstrap, verify the result against ADR-047 Phase 3 Confirmation criterion (when defined).

## Dependencies

- **Blocks**: (P167's investigation tasks for R007-R011 / R002+R005 extensions / R001-R006 re-rate are all superseded by this ticket; P167's status itself is not blocked but its substantive remaining work is delegated here)
- **Blocked by**: (none — design work can begin immediately; the wipe step depends on the bootstrap behaviour being designed first)
- **Composes with**: P167 (driver — captures the symptom this ticket addresses), P033 (created the register; this ticket is its Phase 2/3 promote-to-active), P034 (cross-project risk-report aggregation; sibling), P102 (register invocation surface), P110 (pipeline back-channel hint — this ticket is the implementation), ADR-047 (Phase 2 + Phase 3 deferred to follow-up; this ticket promotes both).

## Related

- `RISK-POLICY.md` — `## Risk Catalog` section (commit `9e339d0`) describes the consume-catalog + bootstrap workflow this ticket implements.
- `RISK-POLICY.md` — `## Control Composition` section (commit `9e339d0`) is the rule the bootstrap will apply when computing residuals for derived entries.
- `docs/problems/167-risk-register-aggregate-reads-as-dont-ship.open.md` — driver / parent ticket. P167's Update section names this ticket as the substantive successor.
- `docs/decisions/047-install-updates-scaffolds-governance-artefacts.proposed.md` — Phase 2 (back-channel) and Phase 3 (one-time backfill) explicitly deferred there; this ticket promotes both to active work per user direction.
- `.risk-reports/` — 181 concrete reports that the bootstrap pass will walk.
- Sibling Explore agent gap-analysis output (P167's session, 2026-05-04) identified 12-14 distinct themes; that analysis is a useful starting point for the bootstrap deduplication design.
- Captured via /wr-itil:capture-problem; substantive design ticket — superseder of P167's original Phase 1-3 plan.
