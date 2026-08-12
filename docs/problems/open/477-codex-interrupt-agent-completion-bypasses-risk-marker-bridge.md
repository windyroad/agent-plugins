# Problem 477: Codex `interrupt_agent` completion bypasses the risk-marker bridge

**Status**: Open
**Reported**: 2026-08-12
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5
**Origin**: internal
**Effort**: S
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The supported-installed risk scorer tells Codex to close a completed pipeline agent with `interrupt_agent`, but its hook matcher, dispatcher, and completion bridge do not recognize that current tool name. They recognize legacy and older close names only. The scorer returns the correct `RISK_SCORES` and `RISK_CWD`, but marker persistence never runs, so the normal commit gate remains bound to stale or missing state.

The direct downstream witness scored its actual delivery checkout correctly, then produced no new checkout-bound marker after `interrupt_agent`. No commit, bypass, or external-system mutation occurred.

## Workaround

None. Do not hand-edit markers or bypass hooks. Install the repaired package, rerun the scorer in the actual delivery checkout, and close the completed agent normally.

## Root Cause Analysis

The runtime changed its unqualified completed-agent tool name from the bridge's recognized variants to `interrupt_agent`. The skill contract was updated to use that name, but the three runtime routing lists and behavioral fixture were not updated with it.

## Fix and Verification

- Add `interrupt_agent` to the PostToolUse matcher, dispatcher, and completion bridge close-name set.
- Reproduce the exact `spawn_agent` response plus `interrupt_agent` completion payload.
- Assert scores and opaque checkout identity persist for `RISK_CWD`, not the task root.
- Release and supported-install the patch before the downstream consumer retries its normal gate.

No ADR is required: this restores the already-intended completed-agent compatibility path without changing the scoring or delivery contract.

## Related

- P461 — separate evidence-boundary correction; not the runtime defect fixed here.
