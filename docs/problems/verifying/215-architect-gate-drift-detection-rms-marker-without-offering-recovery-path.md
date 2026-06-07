# Problem 215: architect-gate drift detection rm's marker without offering recovery path

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

`architect-gate.sh::check_architect_gate` `rm`s the `/tmp/architect-reviewed-<SID>` marker and returns 1 (deny) when the stored hash differs from the current hash. After this, the agent has no obvious recovery path other than re-invoking the architect agent — which does not help if the agent has no clear directive to do so.

## Workaround

Manual re-invocation of architect agent and retry of the gated edit.

## Impact Assessment

- **Severity**: Moderate — friction, recoverable with knowledge of the workaround.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Picked the deny-reason approach over `<marker>.stale` rename — matches existing sibling pattern (`REVIEW_GATE_REASON`); marker mechanics unchanged per ADR-009.

## Fix Strategy

Add an `ARCHITECT_GATE_REASON` variable to `check_architect_gate` (architect-gate.sh) mirroring the sibling `REVIEW_GATE_REASON` shape in jtbd/voice-tone/style-guide review-gate.sh. Set the reason per failure mode (no marker / TTL expired / drift detected) with an explicit re-delegation directive naming `wr-architect:agent` and the Agent tool. Append `${ARCHITECT_GATE_REASON}` to the existing BLOCKED deny message in architect-enforce-edit.sh and architect-plan-enforce.sh. Sharpen sibling REVIEW_GATE_REASON messages from vague "Re-run the X agent" to explicit "Re-delegate to wr-X:agent via the Agent tool (subagent_type: 'wr-X:agent') to refresh the marker." for symmetry. Bats tests assert the deny output includes the recovery directive across all failure modes. Marker mechanics unchanged per ADR-009. RFC-021 carries the fix per ADR-071.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/80
- **Pipeline classification**: safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/architect.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-021 | proposed | P215 — architect-gate deny-reason recovery directive |
