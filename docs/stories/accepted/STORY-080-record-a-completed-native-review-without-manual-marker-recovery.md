---
status: accepted
story-id: record-a-completed-native-review-without-manual-marker-recovery
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P402]
jtbd: [JTBD-001]
rfcs: [RFC-086]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-080: Record a completed native review without manual marker recovery

**Reported**: 2026-08-31
**Problems**: P402
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down)
**RFCs**: RFC-086
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to keep a genuine governance PASS from blocking my next edit, as a developer using Codex native reviewers, I want completed ordinary style-guide and voice-tone reviews to reach their existing marker writers with the parent session and checkout still bound.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] A registered ordinary style-guide or voice-tone reviewer completion delivered through completed close, completed wait, or `SubagentStop` reaches the package's existing marker writer.
- [x] Spawn acknowledgements, empty waits, interrupted running reviews, narrative summaries, stale or unrelated reviews, and mismatched parent sessions or physical checkouts do not approve an edit.
- [x] Duplicate completion delivery is claimed atomically, and marker-writer failure remains retryable and returns failure.
- [x] Packed-package tests cover both packages while voice-tone external-comms, JTBD, runtime configuration, plugin caches, and Claude behavior remain unchanged.

## Driving problem trace (required — I6 invariant)

P402 records that Codex can complete a genuine review without delivering its result through the ordinary style-guide or voice-tone `PostToolUse:Agent` marker path, leaving the parent edit blocked despite substantive approval.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: transporting a genuine completion through the existing writer restores automatic governance without adding a manual marker-recovery step or weakening the gate.

## Implementation notes (optional)

Generate the Codex-only compatibility bridge from the existing surface generator under ADR-083 and ADR-017. Bind role, target, parent session, and physical checkout; keep external-comms keyed review transport outside this slice.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P402
- RFC-086
- ADR-017
- ADR-083
