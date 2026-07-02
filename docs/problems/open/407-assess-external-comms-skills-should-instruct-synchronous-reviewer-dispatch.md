# Problem 407: `/wr-*:assess-external-comms` skills should instruct synchronous reviewer dispatch (P402 follow-up)

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 4 (Low) — Impact: 2 × Likelihood: 2. Impact 2: secondary surface — the gate deny message (the primary agent-in-the-loop surface) already instructs synchronous dispatch as of the P402 fix (commit 16c180e8), so an agent that hits the gate is already corrected; this only affects an agent invoking the assess skill proactively without hitting a deny. Likelihood 2: the deny-message path covers most cases.
**Origin**: internal
**Effort**: S — two skill-doc edits (`/wr-risk-scorer:assess-external-comms` + `/wr-voice-tone:assess-external-comms`, Step 3). WSJF = (4 × 1.0) / 1 = 4.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

Named follow-up to P402. The external-comms mark hook (`PostToolUse:Agent`) fires reliably only when the reviewer agent is dispatched **synchronously** (`run_in_background: false`); a background-launched reviewer never persists its marker (P402). The P402 fix (16c180e8) added a synchronous-dispatch instruction to the canonical gate **deny message** — the primary surface an agent sees when blocked.

The **secondary** surface — the two `/wr-*:assess-external-comms` skills' Step 3, which dispatch the reviewer during a manual walkthrough — was deferred from that commit (architect confirmed safe to defer). Those skills should carry the same synchronous-dispatch note so an agent invoking the skill proactively (before hitting a deny) also dispatches synchronously.

## Symptoms

- An agent invoking `/wr-risk-scorer:assess-external-comms` (or the voice-tone peer) proactively may dispatch the reviewer in the background, leaving the marker unpersisted, so the subsequent commit still denies.

## Workaround

Dispatch the reviewer synchronously by hand; or hit the gate deny (which now instructs it).

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a synchronous-dispatch note to Step 3 of `packages/risk-scorer/skills/assess-external-comms/SKILL.md` and `packages/voice-tone/skills/assess-external-comms/SKILL.md`.
- [ ] Behavioural coverage (if a promptfoo/behavioural surface exists for the skill).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P402 (parent), P356 (key-discipline sibling)

## Related

- **P402** (`docs/problems/open/402-...md`) — parent; the deny-message half shipped 16c180e8; ADR-028 amended 2026-07-02.
