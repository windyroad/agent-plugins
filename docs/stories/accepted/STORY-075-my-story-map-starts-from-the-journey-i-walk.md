---
status: accepted
story-id: my-story-map-starts-from-the-journey-i-walk
reported: 2026-08-30
decision-makers: [Tom Howard]
problems: [P509]
jtbd: [JTBD-008]
rfcs: [RFC-081]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-075: My story map starts from the journey I walk

**Reported**: 2026-08-30
**Problems**: P509
**JTBD**: JTBD-008
**RFCs**: RFC-081
**Story Maps**: STORY-MAP-002
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to approve the journey through a fix rather than a breakdown of its implementation work, as a developer decomposing a fix into coordinated changes, I want the capture flow to derive the steps I walk before it names the map or writes its backbone.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A capture whose description names a change derives a title that names the persona's journey.
- [ ] The same capture derives an ordered backbone of actions the persona walks from trigger to outcome, rather than techniques, phases, invariants, or implementation tasks.
- [ ] The closed `preRfc` rule is unchanged while P509 symptom 2 awaits its governance decision.
- [ ] The focused behavioural skill evaluation passes.

## Driving problem trace (required — I6 invariant)

P509 records that story-map capture derives titles and backbones from the change description instead of the confirmed persona journey.

## JTBD trace (required — I9 invariant)

JTBD-008 requires a developer to decompose a fix into coordinated changes through a trustworthy journey-shaped approval surface.

## Implementation notes (optional)

Change the shared capture contract and keep one live behavioural evaluation. Do not change how already-working capability is represented.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P509
- RFC-081
- STORY-MAP-002
