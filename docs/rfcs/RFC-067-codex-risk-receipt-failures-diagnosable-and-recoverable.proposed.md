---
status: proposed
rfc-id: codex-risk-receipt-failures-diagnosable-and-recoverable
reported: 2026-08-14
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P477]
adrs: [ADR-029, ADR-045, ADR-083]
jtbd: [JTBD-001, JTBD-002]
stories: [STORY-061]
---

# RFC-067: Make Codex risk-receipt failures diagnosable and recoverable

**Status**: proposed
**Reported**: 2026-08-14
**Problems**: P477
**JTBD**: JTBD-001, JTBD-002

## Summary

Keep checkout binding fail-closed while making Codex receipt failures actionable. Record privacy-safe `SubagentStop` rejection reasons. When Codex omits an isolated command's workdir, preserve a valid marker bound to that checkout and direct the agent to retry the same command with an explicit leading `cd`; do not force a rescore that will repeat the same failure.

## Scope

- Retain opaque physical-checkout identity and pipeline-state-hash validation.
- Consume reducing markers on expiry or assessed-state drift, not on a different checkout's event.
- Persist no working directory, response text, session ID, or agent ID in diagnostics or markers.
- Add focused behavioral coverage for receipt diagnostics and isolated-checkout command recovery.
- Ship the repair as a patch release of `@windyroad/risk-scorer`.

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-061 | See why a SubagentStop risk receipt was not written | accepted |

## Related

- P477
- ADR-029, ADR-045, ADR-083
