# Problem 439: External-review round-trips waste cycles on stale repo artifacts (unpushed commits + stale IDE buffer)

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#326)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**JTBD**: JTBD-001
**Persona**: developer

## Description

When the user relays a repo artifact to an external reviewer, the assistant assumes the remote / IDE buffer the reviewer sees is current. With unpushed commits or a stale IDE buffer, the reviewer re-flags already-fixed issues, wasting round-trips. The assistant should proactively hand over the current committed content (SendUserFile + checksum, or offer to push) rather than assume freshness.

## Symptoms

- Reviewer repeatedly re-flags fixed issues because they're reading a stale copy; the assistant does not verify the reviewer's source is current before the round-trip.

## Impact Assessment

- **Who is affected**: the user, on external-review workflows.
- **Frequency**: any review round-trip with unpushed commits / stale buffer.
- **Severity**: Medium — wasted cycles; erodes trust in the review.

## Root Cause Analysis

### Investigation Tasks

- [ ] Assistant behaviour: before an external-review relay, hand over current committed content (SendUserFile + checksum) or offer to push; do not assume the remote/buffer is current.

## Dependencies

- **Composes with**: P116 (unpushed-commit CI blame — distinct surface: reviewer stale-copy vs CI).

## Related

- Inbound issue #326.
