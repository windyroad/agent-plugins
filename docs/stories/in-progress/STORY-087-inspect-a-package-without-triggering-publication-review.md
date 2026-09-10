---
status: in-progress
story-id: inspect-a-package-without-triggering-publication-review
reported: 2026-09-11
decision-makers: [Tom Howard]
problems: [P537]
jtbd: [JTBD-001]
rfcs: [RFC-091]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-087: Inspect a package without triggering publication review

**Reported**: 2026-09-11
**Problems**: P537
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-091
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to inspect a package before release, as a developer using the publication guard, I want a dry run to remain read-only and fast while every command capable of publishing still receives external-comms review.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A dry-run-only `npm publish` command bypasses publication review.
- [x] Plain publication and `--dry-run=false` remain gated.
- [x] A compound command containing a dry run and a real publication remains gated.
- [x] The canonical hook stays byte-identical with both published consumer copies.
- [x] Focused behavioural tests cover both risk and voice evaluators.

## Driving problem trace (required — I6 invariant)

P537 records that the shared gate classifies the `npm publish` verb without considering its dry-run option, so a diagnostic action is treated as outbound publication.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: governance remains automatic on real outbound actions without charging the same review cost to a command that cannot publish.

## Implementation notes (optional)

Classify already-matched npm publication command segments in the canonical shared hook. Fail closed whenever any segment can perform a real publication, then sync the existing consumer copies.
