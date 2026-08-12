# Problem 477: Codex collaboration completion bypasses the risk-marker bridge

**Status**: Open
**Reported**: 2026-08-12
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5
**Origin**: internal
**Effort**: S
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The supported-installed risk scorer tells Codex to close a completed pipeline agent with `interrupt_agent`. Version 0.18.10 recognizes that tool name, but current native collaboration calls do not emit the expected parent `PostToolUse` event. `SubagentStop` arrives in the child conversation without the parent's spawn-state record. The scorer returns the correct `RISK_SCORES` and `RISK_CWD`, but marker persistence never runs, so the normal commit gate remains bound to stale or missing state.

The direct downstream witness scored its actual delivery checkout correctly, then produced no new checkout-bound marker after `interrupt_agent`. No commit, bypass, or external-system mutation occurred.

## Workaround

None. Do not hand-edit markers or bypass hooks. Install the repaired package, rerun the scorer in the actual delivery checkout, and close the completed agent normally.

## Root Cause Analysis

The bridge assumed every native collaboration spawn and close would be observable in the parent session. Current Codex emits the child `SubagentStop`, but not the parent `PostToolUse` events needed to create and consume that session-local role state. Code-mode execution also lacks a parent `PreToolUse` event, so the handoff must survive until the next already-enabled parent prompt. Adding the current close name in 0.18.10 fixed routing only where those parent events exist; it did not repair the missing event boundary.

## Fix and Verification

- On a risk-scorer `SubagentStop` without spawn state, publish a short-lived sanitized receipt bound to the exact physical checkout and pipeline state hash.
- On the existing parent `PreToolUse:Bash` path, or the next `UserPromptSubmit` when code mode exposes no tool event, atomically claim the matching receipt and pass it to the existing marker writer under the parent's real session.
- Reproduce distinct child/parent sessions with no spawn-state file and assert scores, state hash, and opaque checkout identity persist only for the assessed checkout.
- Reject malformed output, invalid roots, checkout drift, expired receipts, and duplicate completion without persisting an absolute path.
- Release and supported-install the patch before the downstream consumer retries its normal gate.

No new hook or ADR is required: this restores the intended completed-agent compatibility path using the already-enabled `SubagentStop`, `PreToolUse:Bash`, and `UserPromptSubmit` events without changing the scoring or delivery contract.

## Related

- P461 — separate evidence-boundary correction; not the runtime defect fixed here.
