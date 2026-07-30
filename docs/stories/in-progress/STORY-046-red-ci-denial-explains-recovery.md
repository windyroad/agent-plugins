---
status: in-progress
story-id: red-ci-denial-explains-recovery
reported: 2026-07-23
decision-makers: [Tom Howard]
problems: [P208]
jtbd: [JTBD-002]
rfcs: [RFC-049]
story-maps: [STORY-MAP-002]
estimated-effort: S
human-oversight: confirmed
oversight-hash: cd0846926ac20f1d84363f31c2844afe7865b563be742133bd6f948ef995ec0c
---

# STORY-046: Red-CI denial explains the recovery path

**Reported**: 2026-07-23
**Problems**: P208
**JTBD**: JTBD-002 (Ship AI-Assisted Code with Confidence)
**RFCs**: RFC-049
**Story Maps**: STORY-MAP-002 (Decompose a Fix Into Coordinated Changes)
**Estimated effort**: S

## User value

In order to keep repairing a broken pipeline without weakening its safeguards, as
a software contributor whose push is denied because the latest CI run is red, I want
the denial to explain how to prove my outgoing commits repair that exact failure
and obtain the existing risk-reducing classification, so I continue the goal
instead of incorrectly declaring it blocked or asking for a bypass.

## Acceptance criteria

- [x] A completed-red-CI push denial includes the run URL and explicitly says red
  CI is not itself a goal blocker.
- [x] The denial tells the agent to inspect the failed run, verify the outgoing
  commits directly repair that failure, delegate to `wr-risk-scorer:pipeline` with
  CI-recovery context, and retry `npm run push:watch` only after a net
  risk-reducing verdict creates the existing `reducing-push` marker.
- [x] The denial says unrelated outgoing commits remain blocked.
- [x] A completed-red-CI release denial tells the agent to fix and push the CI
  repair, wait for green CI, then retry release; it retains the live-outage
  `incident-release` route.
- [x] Behavioural BATS assertions pin the push and release guidance without
  changing the gate's deny decision.
- [x] A patch changeset for `@windyroad/risk-scorer` lands with the implementation.

## Driving problem trace

- **P208** (red-CI push/release gate) - the gate correctly denies but exposes no
  actionable, policy-authorised recovery path, causing agents to stop goals that
  can proceed through a narrowly proven CI repair.

## JTBD trace

- **JTBD-002** (Ship AI-Assisted Code with Confidence) - confidence requires both
  preserving the red-CI safety gate and giving the agent a deterministic route to
  repair it without bypassing policy.

## Implementation notes

Change only the red-conclusion message branch in `check_ci_status`. The scorer,
not the gate, decides whether the outgoing change is net risk-reducing.

## Dependencies

- **Blocks**: P208 guidance fix.
- **Blocked by**: human ratification and accepted transition.

## Related

- RFC-049 (Make the red-CI gate explain the CI-repair recovery path).
- STORY-MAP-002 (Decompose a Fix Into Coordinated Changes).
