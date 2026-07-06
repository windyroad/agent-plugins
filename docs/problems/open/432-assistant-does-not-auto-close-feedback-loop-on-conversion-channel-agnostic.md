# Problem 432: Assistant does not auto-close the feedback loop on inbound-feedback conversion (channel-agnostic)

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#347)
**Effort**: M. WSJF = (9 × 1.0) / 2 = 4.5.
**JTBD**: JTBD-301
**Persona**: plugin-user

## Description

When inbound feedback is converted into a local ticket, the assistant does not, in the same pass, (a) mark the source entry's triage-state → converted and link the created ticket ID, nor (b) author a user-facing acknowledgement. The close-the-loop step is left to a later manual prompt. This is the conversion-time leg of the JTBD-301 inbound loop, and it should be defined against a channel-agnostic feedback interface (GitHub issue + bespoke sources, e.g. Firestore), not GitHub-only.

## Symptoms

- Inbound report converted to a ticket; the source entry stays untriaged/open and the reporter gets no acknowledgement until a human intervenes.

## Impact Assessment

- **Who is affected**: inbound reporters (plugin-user); the feedback loop stays open at conversion time.
- **Frequency**: every conversion.
- **Severity**: Medium — reporters churn / re-file; erodes the inbound-discovery trust loop.

## Root Cause Analysis

### Investigation Tasks

- [ ] On conversion, auto-set source triage-state → converted + link ticket ID AND author a user-facing ack in the same pass, no prompt; define against a channel-agnostic feedback interface (GitHub issue + bespoke).

## Dependencies

- **Composes with**: P363 (fix-released verdict leg — reopened), P270 (file-on-detect leg), P229 (verdict-shaped ack), P080 (outbound bidirectional update). This is the conversion-time leg of the same JTBD-301 close-the-loop family; the channel-agnostic abstraction argues for a standalone ticket.

## Related

- Inbound issue #347.
