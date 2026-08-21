# Problem 477: Codex collaboration completion bypasses the risk-marker bridge

**Status**: Open
**Reported**: 2026-08-12
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5
**Origin**: internal
**Effort**: S
**WSJF**: 20 — (20 × 1.0) / 1 (added 2026-08-21 review)
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The supported-installed risk scorer tells Codex to close a completed pipeline agent with `interrupt_agent`. Version 0.18.10 recognizes that tool name, but current native collaboration calls do not emit the expected parent `PostToolUse` event. `SubagentStop` arrives in the child conversation without the parent's spawn-state record. The scorer returns the correct `RISK_SCORES` and `RISK_CWD`, but marker persistence never runs, so the normal commit gate remains bound to stale or missing state.

The direct downstream witness scored its actual delivery checkout correctly, then produced no new checkout-bound marker after `interrupt_agent`. No commit, bypass, or external-system mutation occurred.

## Workaround

None. Do not hand-edit markers or bypass hooks. Install the repaired package, rerun the scorer in the actual delivery checkout, and close the completed agent normally.

## Root Cause Analysis

The bridge assumed every native collaboration spawn and close would be observable in the parent session. Current Codex emits the child `SubagentStop`, but not the parent `PostToolUse` events needed to create and consume that session-local role state. Code-mode execution also lacks a parent `PreToolUse` event, so the handoff must survive until the next already-enabled parent prompt. Adding the current close name in 0.18.10 fixed routing only where those parent events exist; it did not repair the missing event boundary.

The sanitized receipt path shipped, but a live 2026-08-14 desktop replay exposed a second defect: a trusted and enabled `SubagentStop` completed with the expected pipeline role and reducing verdict, yet no pending receipt was written. The bridge returned silently for every rejected payload or derived-state condition, leaving no way to distinguish an event that did not fire from a payload-shape mismatch, identity rejection, state-hash failure, or receipt collision. This observability gap is part of P477 because it prevents the repaired handoff from being verified or diagnosed without reading private transcripts.

A 2026-08-16 isolated-checkout replay exposed a third failure in the same handoff. Codex executed `git commit` in the assessed checkout, but the compatibility payload exposed only the parent task checkout. The gate correctly rejected the checkout mismatch, then incorrectly deleted the valid reducing marker. Every retry therefore required another score and repeated the same deletion. The hook cannot recover an omitted path from the opaque checkout identity, so it must preserve the marker and prescribe an explicit leading `cd` rather than consume valid evidence.

## Fix and Verification

- On a risk-scorer `SubagentStop` without spawn state, publish a short-lived sanitized receipt bound to the exact physical checkout and pipeline state hash.
- On the existing parent `PreToolUse:Bash` path, or the next `UserPromptSubmit` when code mode exposes no tool event, atomically claim the matching receipt and pass it to the existing marker writer under the parent's real session.
- Reproduce distinct child/parent sessions with no spawn-state file and assert scores, state hash, and opaque checkout identity persist only for the assessed checkout.
- Reject malformed output, invalid roots, checkout drift, expired receipts, and duplicate completion without persisting an absolute path.
- Persist one atomically replaced, mode-0600 diagnostic containing only timestamp, outcome/rejection code, normalized event name, and field presence/types. Never persist response text, working directories, session IDs, agent IDs, or absolute paths.
- When a command arrives from a different checkout than a valid checkout-bound reducing marker, deny without consuming the marker and direct Codex to retry the same command as `cd /absolute/assessed/checkout && ...`. Continue consuming markers on expiry or assessed-state drift.
- Release and supported-install the patch before the downstream consumer retries its normal gate.

No new hook or ADR is required: this restores the intended completed-agent compatibility path using the already-enabled `SubagentStop`, `PreToolUse:Bash`, and `UserPromptSubmit` events without changing the scoring or delivery contract.

## Related

- P461 — separate evidence-boundary correction; not the runtime defect fixed here.
- RFC-067 / STORY-061 — observability slice for the silent receipt rejection.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-067 | proposed | Make Codex risk-receipt failures diagnosable and recoverable |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-061 | STORY-061: See why a SubagentStop risk receipt was not written | accepted |
