---
status: accepted
story-id: see-why-a-subagentstop-risk-receipt-was-not-written
reported: 2026-08-14
decision-makers: [Tom Howard]
problems: [P477]
jtbd: [JTBD-001, JTBD-002]
rfcs: [RFC-067]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-061: See why a SubagentStop risk receipt was not written

**Reported**: 2026-08-14
**Problems**: P477
**JTBD**: JTBD-001, JTBD-002
**RFCs**: RFC-067
**Story Maps**: STORY-MAP-002
**Estimated effort**: S

## User value

In order to repair the integration instead of treating the gate as inexplicably blocked, as a software developer relying on the risk gate, I want a missing Codex subagent receipt to identify its rejection reason without exposing the assessment or repository identity.

## Acceptance criteria

- [ ] A valid pipeline `SubagentStop` records `receipt-written` after creating its normal checkout-bound receipt.
- [ ] Missing output, malformed JSON, invalid session identity, invalid assessed roots, missing scores, state-hash failure, and duplicates record distinct bounded outcomes.
- [ ] The diagnostic contains field presence/types but no response text, working directory, session ID value, agent ID value, or absolute path.
- [ ] The diagnostic is atomically replaced, mode 0600, limited to one file, and emits no stdout.
- [ ] Existing receipt creation, consumption, duplicate suppression, and checkout/state binding tests remain green.
- [ ] A patch changeset releases the diagnostic in `@windyroad/risk-scorer` for supported-install dogfooding.

## Driving problem trace

**P477** produced a correct reducing verdict through a trusted, enabled `SubagentStop`, but no pending receipt. Because all bridge rejection paths were silent and indistinguishable, diagnosis required inspecting a private transcript and still could not prove which field or derived condition failed.

## JTBD trace

This serves **JTBD-001** by making a governance failure actionable instead of forcing manual gate policing, and **JTBD-002** by keeping the evidence privacy-safe and mechanically testable.

## Implementation notes

Use the existing pending directory and one latest-event file. Do not add a logging framework, append-only history, hook registration, or transcript parser.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- RFC-067, P477, ADR-045, STORY-MAP-002.
