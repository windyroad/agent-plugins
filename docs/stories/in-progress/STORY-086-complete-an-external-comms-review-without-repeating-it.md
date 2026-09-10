---
status: in-progress
story-id: complete-an-external-comms-review-without-repeating-it
reported: 2026-09-11
decision-makers: [Tom Howard]
problems: [P402]
jtbd: [JTBD-001]
rfcs: [RFC-086]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-086: Complete an external-comms review without repeating it

**Reported**: 2026-09-11
**Problems**: P402
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-086
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to continue after a genuine external-comms PASS, as a developer using Codex native reviewers, I want the completed risk and voice reviews to reach their existing marker writers without repeating the review or writing a marker by hand.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] Completed `wr-risk-scorer:external-comms` and `wr-voice-tone:external-comms` reviews reach their existing marker writers through native Codex completion transport.
- [x] Each evaluator remains bound to its exact role, parent session, checkout, policy, surface, and draft key.
- [x] Spawn acknowledgements, running interruptions, stale reviews, unrelated roles, and narrative-only verdicts do not write markers.
- [x] Packed-package tests exercise the configured completion hooks for both evaluators.

## Driving problem trace (required — I6 invariant)

P402 records that an external-comms reviewer can return PASS without the calling task receiving the keyed marker, causing the same guarded action to be denied again.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: genuine governance evidence is transported automatically without weakening the review boundary or making the developer repeat work.

## Implementation notes (optional)

Extend RFC-086's existing Codex completion bridge to the external-comms reviewer identities. Reuse the existing evaluator-specific marker writers.
