---
status: proposed
rfc-id: dispatch-marker-writing-review-agents-synchronously
reported: 2026-07-03
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P402, P407]
adrs: [ADR-028]
jtbd: [JTBD-001, JTBD-006]
stories: []
---

# RFC-041: Dispatch marker-writing review agents synchronously so the mark hook fires before the gated action

**Status**: proposed
**Reported**: 2026-07-03
**Problems**: P402, P407
**ADRs**: ADR-028 (extends its "reviewer dispatched synchronously so the PostToolUse mark hook fires" criterion to the pipeline-gate + reviewer-wrapper dispatch surfaces)
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I'm Away)

## Summary

Codify **synchronous dispatch** (`run_in_background: false`) of every marker-writing
review agent at the surfaces that instruct dispatch, so the `PostToolUse:Agent`
mark hook fires in the live session and writes the gate marker **before** the
gated action runs. Covers BOTH the external-comms gate and the pipeline
commit/push/release gate.

## Driving problem trace

- **P407** — named follow-up to P402: the `/wr-*:assess-external-comms` skills' reviewer
  dispatch (the secondary surface deferred from the P402 deny-message commit) must also
  instruct synchronous dispatch. Resolved by the same wrapper/assess/voice-tone edits below.
- **P402** — The `PostToolUse:Agent` mark hook that persists a risk / external-comms
  gate marker fires reliably **only** for a synchronously-dispatched review agent.
  A background-launched (forced-async) reviewer's mark hook does not fire in time
  (or at all) in the live session, so no marker persists despite a PASS verdict and
  the gate re-blocks — forcing habitual `BYPASS_RISK_GATE`, the exact friction the
  gate was meant to retire. Root cause isolated 2026-07-02 (`background` probe →
  marker ABSENT; `synchronous` probe → marker PRESENT under the live SID). The
  2026-07-03 scope-broadening evidence confirms the identical failure mode on the
  `wr-risk-scorer:pipeline` push gate (`Push blocked: No push risk score found`
  after a background scorer), so the fix generalises across both gates.

## Scope

The fix being proposed: at each surface that *instructs or performs* reviewer
dispatch, make synchronous dispatch the codified default.

- The `external-comms-gate.sh` DENY message **already** carries the synchronous
  instruction (shipped precedent, `packages/shared/hooks/external-comms-gate.sh`,
  with behavioural coverage in `external-comms-gate-canonical.bats`). This RFC
  brings the remaining surfaces into line.
- Pipeline gate DENY: append the synchronous-dispatch instruction to the
  "No `<ACTION>` risk score found" message so the marker-absent case (the exact
  P402 trigger) tells the agent to dispatch the scorer synchronously.
- Reviewer-wrapper / assess skills: add `run_in_background: false` to the
  Agent-tool dispatch block so consumers routing through the wrappers dispatch
  synchronously by construction, not by remembering.

Not in scope: making the mark hook fire on background-agent completion — that is a
harness-interaction limitation (async completion does not reliably emit
`PostToolUse:Agent` in time), not a plugin-side bug. Synchronous dispatch is the
reliable trigger (user-chosen option b).

## Tasks

- [ ] `packages/risk-scorer/hooks/lib/risk-gate.sh` — append a synchronous-dispatch
  sentence to the "No `${ACTION}` risk score found. Delegate to
  wr-risk-scorer:pipeline …" DENY message. Preserve the existing
  "No `${ACTION}` risk score found" substring (asserted by `risk-gate.bats`).
- [ ] `packages/risk-scorer/hooks/test/risk-gate.bats` — behavioural assertion that
  the missing-score DENY message now instructs synchronous dispatch (mirrors
  `external-comms-gate-canonical.bats`).
- [ ] `packages/risk-scorer/skills/pipeline/SKILL.md` — add `run_in_background: false`
  to the Agent-tool dispatch block + a one-line P402 rationale note.
- [ ] `packages/risk-scorer/skills/external-comms/SKILL.md` — same shape.
- [ ] `packages/voice-tone/skills/assess-external-comms/SKILL.md` — same shape on the
  reviewer dispatch block.

## Stories

(deferred — per ADR-089 this RFC must gain ≥1 story before it transitions to
`accepted`; author the story at `/wr-itil:manage-rfc RFC-041 accepted`.)

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook.)

## Related

- **P402** — driving problem ticket.
- **ADR-028** — External-comms / voice-tone gate; its Confirmation already records
  synchronous reviewer dispatch. This RFC extends that criterion to the pipeline
  gate + wrapper surfaces.
- **RFC-034 (P370)** — sibling background-dispatch class (forbids backgrounded task
  launches inside `claude -p` iter dispatch). Distinct mechanism (turn-end
  survivor), distinct fix surface; NOT this RFC's vehicle.
- **ADR-052** — behavioural-tests default; the `risk-gate.bats` assertion is the
  load-bearing behavioural surface (SKILL prose dispatch blocks are not
  structurally grep-tested per P081).
