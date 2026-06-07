---
status: proposed
rfc-id: p215-architect-gate-deny-reason-recovery-directive
reported: 2026-06-07
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P215]
adrs: [ADR-009, ADR-052, ADR-071, ADR-014]
jtbd: [JTBD-001, JTBD-006]
stories: []
---

# RFC-021: P215 — architect-gate deny-reason recovery directive

**Status**: proposed
**Reported**: 2026-06-07
**Problems**: P215
**ADRs**: ADR-009 (gate marker lifecycle — TTL + drift unchanged by this fix), ADR-052 (behavioural-tests-default — bats assertions on deny-message contents), ADR-071 (every fix goes through an RFC — why this RFC exists), ADR-014 (governance skills commit their own work)
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down — clear recovery affordance reduces blocked-edit friction), JTBD-006 (Progress the Backlog While I'm Away — AFK iter doesn't stall on opaque deny)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P215 fix under the RFC-first framework. It carries **no independent architectural decisions** — the substantive choice (deny-reason refactor vs `.stale` rename) was pinned in the iter task brief and matches the existing sibling pattern (`review-gate.sh` REVIEW_GATE_REASON). Pattern modelled on RFC-015 (P333 retro-fit) and RFC-018 (P270 thin).

## Summary

P215: `architect-gate.sh::check_architect_gate` silently `rm`s the `/tmp/architect-reviewed-<SID>` marker and returns 1 (deny) when stored hash differs from current, leaving the agent without a differentiated recovery directive. The downstream deny message in `architect-enforce-edit.sh` is static — it doesn't distinguish no-marker / TTL-expired / drift-detected cases. Sibling `review-gate.sh` (jtbd / voice-tone / style-guide) already exposes a `REVIEW_GATE_REASON` variable appended to the deny message; the architect gate is the asymmetric outlier.

The fix adds an `ARCHITECT_GATE_REASON` variable matching the sibling shape, sets it for each failure mode with an explicit re-delegation directive (subagent_type-named), and appends it to the deny message in `architect-enforce-edit.sh` and `architect-plan-enforce.sh`. The sibling messages are sharpened from vague "Re-run the X agent" to "Re-delegate to wr-X:agent via the Agent tool (subagent_type: 'wr-X:agent') to refresh the marker." for symmetry. The P353-class substance-aware drift fix shipped earlier reduces how often drift fires; this RFC closes the residual UX gap when it does.

## Driving problem trace

- **P215** (`docs/problems/known-error/215-architect-gate-drift-detection-rms-marker-without-offering-recovery-path.md`) — architect-gate drift detection `rm`s marker without offering recovery path. Status: Known Error.

## Scope

(deferred — populate at /wr-itil:manage-rfc accepted transition)

## Tasks

- [ ] (deferred — populate at /wr-itil:manage-rfc accepted transition)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

(captured via /wr-itil:capture-rfc; expand at next /wr-itil:manage-rfc invocation)
