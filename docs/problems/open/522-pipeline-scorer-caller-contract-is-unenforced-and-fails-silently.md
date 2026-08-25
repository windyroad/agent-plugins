# Problem 522: The pipeline scorer's caller contract is unenforced, so a direct dispatch fails silently and misdirects the blame

**Status**: Open
**Reported**: 2026-08-25
**Priority**: 12 (High) — Impact: 3 (Moderate — a whole session can be spent unable to commit, with the gate message pointing at the wrong cause) × Likelihood: 4 (Likely — any caller reaching the pipeline agent without going through assess-release hits it, and nothing signals the omission)
**Origin**: internal
**Effort**: S
**WSJF**: 12 — (12 × 1.0) / 1
**JTBD**: JTBD-001
**Persona**: developer

## Description

`packages/risk-scorer/hooks/codex-agent-completion.mjs` (`pipelineAssessment`) hard-requires exactly one `RISK_CWD: <absolute git root>` line in the scorer's output to bind an assessment to a physical checkout. `roots.length !== 1` rejects with `missing-risk-cwd` and no receipt is written.

That line is **supplied by the caller**, by design — `skills/pipeline/SKILL.md` states "required `RISK_CWD:` line supplied by the caller", and `/wr-risk-scorer:assess-release` constructs it at its Step 2. The `wr-risk-scorer:pipeline` agent spec does not mention `RISK_CWD` and is not meant to.

Nothing enforces that contract. Dispatch the pipeline agent **directly** — via the Agent tool, or any orchestrator that skips `assess-release` — and the line is absent, the receipt is silently rejected, and the commit gate then blocks with a message that attributes the failure to background-vs-synchronous dispatch (P402) rather than to the missing line. The caller has no way to tell the two apart.

Witnessed 2026-08-25 in this repo: an orchestrator dispatched `wr-risk-scorer:pipeline` directly, received a valid `commit=5` verdict, and could not commit. Diagnosis consumed several round-trips and initially blamed async dispatch and then the agent spec, both wrong. Supplying the line manually produced a correct receipt immediately. The same shape is the most likely explanation for a downstream Codex session on 0.18.16 reporting "the collaboration runner did not persist the scorer receipt" while the score itself was fine.

## Symptoms

- A valid within-appetite `RISK_SCORES` line is returned, and the commit gate still blocks.
- No receipt appears under `$TMPDIR/claude-risk-pending/` for the checkout.
- The gate's advisory names synchronous-vs-background dispatch, which is not the cause.
- The SubagentStop diagnostic records `missing-risk-cwd`, but it is a single shared file and is typically overwritten before anyone reads it.

## Workaround

Invoke `/wr-risk-scorer:assess-release` rather than dispatching `wr-risk-scorer:pipeline` directly. If the agent must be dispatched directly, include in its prompt an instruction to emit exactly one line `RISK_CWD: <absolute repo root>` at line start.

## Impact Assessment

- **Who is affected**: any orchestrator or agent that dispatches the pipeline scorer directly, including AFK loops and cross-tool runners; adopters wiring their own scoring flows.
- **Frequency**: every direct dispatch.
- **Severity**: the session cannot commit; the diagnostic points elsewhere; recovery depends on reading hook source.

## Root Cause Analysis

The contract is documented in prose on the wrapper SKILL but has no runtime enforcement and no distinguishable failure signal. A caller that omits the line gets the same observable outcome as a caller whose mark hook did not fire.

### Investigation Tasks

- [ ] Decide the enforcement point: reject at dispatch, or have the hook emit a distinct actionable rejection the gate surfaces verbatim
- [ ] Make the commit gate's advisory name `missing-risk-cwd` specifically when that is the recorded rejection, instead of defaulting to the P402 background-dispatch text
- [ ] Confirm whether the downstream Codex 0.18.16 failure is this same shape
- [ ] Behavioural coverage per ADR-052 — a direct dispatch without the line must produce a distinguishable, actionable failure

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P477 (the receipt bridge this contract feeds), P402 (the advisory text that currently misdirects)

## Related

- **P477** (verifying) — Codex collaboration completion bypasses the risk-marker bridge. Its fix shipped in 0.18.10 through 0.18.16 and introduced the receipt path this contract gates. This ticket is the caller-side gap that fix did not cover; the receipt writer is correct, the callers are unconstrained.
- **P402** (verifying) — the background-vs-synchronous marker advisory whose text is emitted for this failure too, which is why it misdirects.
- RFC-067 / STORY-061 — carry the observability slice P477 records as residual (the single shared diagnostic).
