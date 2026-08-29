# Problem 477: Codex collaboration completion bypasses the risk-marker bridge

**Status**: Closed (closed-on-evidence 2026-08-30 — an installed native `wr-risk-scorer:pipeline` collaboration completed, its checkout-bound marker was accepted by the governed commit of `9712a054`, and the same agent completed again after `followup_task`. Recovery: rerun /wr-itil:transition-problem 477 known-error to reopen)
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

Do not hand-edit markers or bypass hooks. In Codex, put an explicit leading
`cd /absolute/path/to/the/assessed-checkout &&` inside governed commit, push,
release, and changeset commands; a tool `workdir` alone may be hidden from the
checkout-binding hook. Rescore only if the assessed checkout actually changed
or the binding is missing.

## Root Cause Analysis

The bridge assumed every native collaboration spawn and close would be observable in the parent session. Current Codex emits the child `SubagentStop`, but not the parent `PostToolUse` events needed to create and consume that session-local role state. Code-mode execution also lacks a parent `PreToolUse` event, so the handoff must survive until the next already-enabled parent prompt. Adding the current close name in 0.18.10 fixed routing only where those parent events exist; it did not repair the missing event boundary.

The sanitized receipt path shipped, but a live 2026-08-14 desktop replay exposed a second defect: a trusted and enabled `SubagentStop` completed with the expected pipeline role and reducing verdict, yet no pending receipt was written. The bridge returned silently for every rejected payload or derived-state condition, leaving no way to distinguish an event that did not fire from a payload-shape mismatch, identity rejection, state-hash failure, or receipt collision. This observability gap is part of P477 because it prevents the repaired handoff from being verified or diagnosed without reading private transcripts.

A 2026-08-16 isolated-checkout replay exposed a third failure in the same handoff. Codex executed `git commit` in the assessed checkout, but the compatibility payload exposed only the parent task checkout. The gate correctly rejected the checkout mismatch, then incorrectly deleted the valid reducing marker. Every retry therefore required another score and repeated the same deletion. The hook cannot recover an omitted path from the opaque checkout identity, so it must preserve the marker and prescribe an explicit leading `cd` rather than consume valid evidence.

A 2026-08-21 verification pass confirmed every declared defect against the shipped
code and left one residual observation about the diagnostic itself. The diagnostic
is a single shared path under the pending-receipt directory, not scoped per session.
The completion event fires for every risk-scorer agent on Claude Code as well, where
the receipt path is neither needed nor satisfiable, so each of those events overwrites
the file with a benign `missing-risk-cwd` rejection. A genuine Codex rejection is
therefore stomped by the next unrelated completion before anyone reads it, which
blunts the observability this ticket set out to add. The single atomically replaced
file was specified here deliberately, so narrowing or scoping it is a design question
for the observability slice rather than a defect in this fix — carried by RFC-067 and
STORY-061.

## Fix and Verification

### Recurrence on 0.18.16

A live 2026-08-27 Codex run produced a valid checkout-bound score, then the
commit gate resolved the parent task worktree because Codex did not expose the
nested `exec_command.workdir`. The generic score path incorrectly prescribed a
rescore even though the valid marker remained usable through an explicit
leading `cd`. Transcript inspection also found expired unmatched receipts and
typed pipeline agents recursively invoking the wrapper. Per ADR-022, this live
recurrence returns P477 to Known Error until the complete repair is released
and verified.

The complete repair keeps checkout binding fail-closed, teaches Codex callers
to put the absolute checkout in the command itself, preserves a valid ordinary
score when only the hook-visible checkout differs, prevents a typed pipeline
scorer from recursively dispatching itself, and reaps only expired
receipt-shaped files. Unrelated files and the privacy-safe diagnostic are never
cleanup candidates.

- On a risk-scorer `SubagentStop` without spawn state, publish a short-lived sanitized receipt bound to the exact physical checkout and pipeline state hash.
- On the existing parent `PreToolUse:Bash` path, or the next `UserPromptSubmit` when code mode exposes no tool event, atomically claim the matching receipt and pass it to the existing marker writer under the parent's real session.
- Reproduce distinct child/parent sessions with no spawn-state file and assert scores, state hash, and opaque checkout identity persist only for the assessed checkout.
- Reject malformed output, invalid roots, checkout drift, expired receipts, and duplicate completion without persisting an absolute path.
- Persist one atomically replaced, mode-0600 diagnostic containing only timestamp, outcome/rejection code, normalized event name, and field presence/types. Never persist response text, working directories, session IDs, agent IDs, or absolute paths.
- When a command arrives from a different checkout than a valid checkout-bound reducing marker, deny without consuming the marker and direct Codex to retry the same command as `cd /absolute/assessed/checkout && ...`. Continue consuming markers on expiry or assessed-state drift.
- Release and supported-install the patch before the downstream consumer retries its normal gate.

No new hook or ADR is required: this restores the intended completed-agent compatibility path using the already-enabled `SubagentStop`, `PreToolUse:Bash`, and `UserPromptSubmit` events without changing the scoring or delivery contract.

## Fix Strategy

The complete recurrence repair is the bounded risk-scorer patch in commit
`e67183ad0d56d23d9e02a3721af8183264db5d4c`. It preserves checkout binding
while repairing the caller and cleanup edges exposed by the 2026-08-27 replay.

**Release vehicle**: `.changeset/calm-risk-receipts.md`

## Fix Released

Released in `@windyroad/risk-scorer@0.18.17` from complete repair commit
`e67183ad0d56d23d9e02a3721af8183264db5d4c` via
`.changeset/calm-risk-receipts.md` (version-packages commit
`cb749f1f53650ae933106aaefd5f93b8ea47e1c4`, PR #451, merge commit
`cf5cf39a0f6623eb4ccaf434e6239f2d641d0ea8`, release date 2026-08-27;
npm published 2026-08-28T11:15:04Z).

The complete repair requires explicit checkout-bound governed commands,
preserves valid scores across hidden-workdir mismatches, prevents recursive
pipeline scoring, and reaps only expired receipt-shaped files. The focused
behavioural suites passed 94 of 94 on 2026-08-29. Versions 0.18.10 through
0.18.16 and the release vehicles listed under Prior Fix Released were partial
and are not the recurrence fix cited here.

Awaiting post-release verification through a supported installed Codex
collaboration and governed-command journey.

## Prior Fix Released

Versions 0.18.10 through 0.18.16 carried the partial completion bridge. A live
2026-08-27 run on 0.18.16 reproduced the hidden-workdir failure, proving that
the earlier release was incomplete.

The completion bridge now writes a checkout-bound receipt when a risk-scorer
`SubagentStop` arrives without parent spawn state, and claims it on the next parent
`PreToolUse:Bash` or `UserPromptSubmit`. The marker persists under the parent's real
session without ever needing a parent `PostToolUse` event.

**Release vehicle**: `.changeset/bright-close-bridge.md`, `.changeset/close-child-risk-receipt.md`, `.changeset/risk-scorer-subagentstop-diagnostics.md`, `.changeset/risk-scorer-preserve-checkout-marker.md`

Verified 2026-08-21 by reading the shipped hook and running its behavioural suites —
`npx bats packages/risk-scorer/hooks/test/codex-agent-completion.bats packages/risk-scorer/hooks/test/reducing-marker-persistence.bats`,
40 of 40 passing. Every declared fix bullet has a named passing test:

| Declared fix | Implementation | Passing test |
|---|---|---|
| Receipt on `SubagentStop` without spawn state | `persistPendingPipeline` | 2 — desktop pipeline SubagentStop hands a checkout-bound receipt to the parent without spawn state |
| Claim on parent `PreToolUse:Bash` or `UserPromptSubmit` | `risk-pending-receipt.sh` plus `consumePending` | 8, 9 — Codex parent prompt imports a completed child receipt; imported score retains the original assessment timestamp |
| Persist only for the assessed checkout across distinct child/parent sessions | `checkoutId` and `stateHash` binding | 3, 11 — a distinct completion supersedes an unchanged checkout score; pending receipt rejects checkout drift |
| Reject malformed output, invalid roots, drift, expiry, duplicates | `pipelineAssessment`, TTL check, `wx` writes | 4, 12, 13, 20 |
| Mode-0600 diagnostic carrying no paths, sessions or response text | `diagnoseSubagentStop` | 5, 6, 7 |
| Deny a checkout mismatch without consuming the marker | `risk-score-commit-gate.sh`, `git-push-gate.sh` | 25, 27, 29 |

Live evidence that the `SubagentStop` leg executes in production: the shipped hook
wrote `$TMPDIR/claude-risk-pending/subagent-stop-diagnostic.json` at
2026-08-21T08:48:26Z, mode 0600, carrying only a timestamp, an outcome, a rejection
reason and a field-type map.

## Related

- P461 — separate evidence-boundary correction; not the runtime defect fixed here.
- RFC-067 / STORY-061 — observability slice for the silent receipt rejection, and the
  home for the shared-diagnostic-overwrite observation recorded above.
- P402 — sibling, not the same defect. There the Claude Code harness forces an Agent
  dispatch into the background so the parent `PostToolUse` mark hook never fires; here
  Codex native collaboration never emits the parent event at all. Different trigger,
  same surface: no marker persists. Both fail closed — the gate blocks rather than
  letting work through — so neither is a bypass in the permissive sense. The receipt
  machinery built for this ticket is wired on Claude Code too, but cannot produce a
  receipt there: the assessed-checkout binding that makes the agent echo `RISK_CWD:`
  is appended only to the Codex agent build by
  `packages/risk-scorer/scripts/codex-agents.mjs`, so `packages/risk-scorer/agents/pipeline.md`
  never carries it. Extending the receipt to cover background dispatch belongs to P402.
- P368 — unrelated mechanism, same silent-no-op class. That ticket is a shell-environment
  defect: a marker shim reads an empty `CLAUDE_SESSION_ID` from the Bash environment and
  exits without a trace. This bridge takes `session_id` from the hook's JSON payload,
  validates it, and now records the rejection reason when it fails.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-067 | proposed | Make Codex risk-receipt failures diagnosable and recoverable |

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-061 | STORY-061: See why a SubagentStop risk receipt was not written | accepted |
