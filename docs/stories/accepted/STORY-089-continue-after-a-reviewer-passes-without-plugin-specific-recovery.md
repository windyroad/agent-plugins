---
status: accepted
story-id: continue-after-a-reviewer-passes-without-plugin-specific-recovery
reported: 2026-09-14
decision-makers: [Tom Howard]
problems: [P539]
jtbd: [JTBD-001]
rfcs: [RFC-093]
story-maps: [STORY-MAP-002]
estimated-effort: L
---

# STORY-089: I can continue after a reviewer passes, without plugin-specific recovery

**Reported**: 2026-09-14
**Problems**: P539
**JTBD**: JTBD-001
**RFCs**: RFC-093
**Story Maps**: STORY-MAP-002
**Estimated effort**: L — shared native-event decoder, four ordinary reviewer packages, the specialised risk-scorer consumer, packed-package tests, and releases

## User value

In order to continue governed work without repeating a completed review, as a developer using governance reviewers in Codex, I want every reviewer plugin to persist its required review marker from the same native completion event.

## Acceptance criteria

- [ ] One canonical helper decodes dotted and flattened native collaboration event names plus object, JSON-string, and `input_text` array responses.
- [ ] Packed style-guide, voice-tone, and JTBD plugins persist their existing marker after a bound genuine PASS delivered through dotted collaboration events and `input_text` arrays.
- [ ] Architect consumes the same canonical decoder through its existing package-specific packing and dispatch flow.
- [ ] Risk-scorer consumes the same canonical decoder without weakening its specialised SubagentStop receipt, checkout, state-hash, or completion-identity controls.
- [ ] Malformed, unrelated, stale, policy-drifted, checkout-mismatched, duplicate, non-PASS, and writer-failure completions remain fail-closed.
- [ ] All affected packages are published and a fresh installed Codex task exercises the native completion path without manual marker recovery.

## Driving problem trace

P539 records that plugin-local fixes did not propagate because reviewer packages did not share one current native completion decoder.

## JTBD trace

JTBD-001 requires governance to complete automatically without forcing the developer to repeat a valid review or recover marker files manually.

## Implementation notes

Reuse ADR-017's canonical-source plus per-package sync pattern. Keep the ordinary review state machines and risk-scorer's specialised receipt state machine package-local; share only native event and response decoding.

## Dependencies

- **Blocks**: reliable Codex reviewer marker persistence across governance plugins
- **Blocked by**: (none)

## Related

- P402 and P477 are bounded predecessors whose fixes remain valid.
