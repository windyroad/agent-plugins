---
status: in-progress
story-id: review-the-complete-commit-message-once
reported: 2026-08-29
decision-makers: [Tom Howard]
problems: [P415]
jtbd: [JTBD-006]
rfcs: [RFC-077]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-071: Review the complete commit message once

**Reported**: 2026-08-29
**Problems**: P415
**JTBD**: JTBD-006
**RFCs**: RFC-077
**Story Maps**: STORY-MAP-002
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to land a multi-paragraph commit after one successful external-comms review, as a plugin developer, I want the gate to join every `-m`/`--message` value as a separate paragraph before looking up the review marker.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A review marker keyed to `subject\n\nbody\n\ntrailer` permits a public-repository `git commit` that supplies those paragraphs with mixed `-m` and `--message` flags.
- [x] The gate extracts quoted message values in command order and joins them with exactly one blank line.
- [x] The existing single-message and heredoc commit-message forms retain their marker-key behaviour.

## Driving problem trace (required — I7 invariant)

- **P415** — the gate stops at the first `-m` match, so a marker created for the complete reviewed commit message cannot authorize a multi-paragraph commit.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006 — progress the backlog while I am away. One successful review must authorize the exact commit the unattended iteration then attempts, without a deny-after-PASS retry loop.

## Implementation notes (optional)

- Change only the canonical shared external-comms hook, then run the established sync script for the risk-scorer and voice-tone consumer copies.
- Protect the fix with one behavioural Bats regression covering the full marker-key path.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- RFC-077 — *Review the complete commit message once*, the release row on STORY-MAP-002 activity D, *Implement the changes*.
