---
status: draft
story-id: gate-bash-writes-without-blocking-read-only-commands
reported: 2026-08-31
decision-makers: [Tom Howard]
problems: [P503]
jtbd: [JTBD-001, JTBD-006, JTBD-008]
rfcs: [RFC-088]
story-maps: [STORY-MAP-002]
estimated-effort: L
---

# STORY-082: Gate Bash writes without blocking read-only commands

**Reported**: 2026-08-31
**Problems**: P503
**JTBD**: JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I Am Away), JTBD-008 (Decompose a Fix Into Coordinated Changes)
**RFCs**: RFC-088
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `implement`
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to trust unattended and interactive edits equally, as a developer using AI agents, I want explicit Bash-routed file writes to pass through the same governance gates and post-write bookkeeping as Edit and Write calls, while read-only shell commands remain fast and silent.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] One canonical, synced classifier returns explicit file targets for supported Bash write forms and returns no target for read-only commands such as `cat` and `grep`.
- [ ] Classified Bash writes pass through the existing architect, JTBD, style-guide, voice-tone, and TDD edit gates without duplicating their path exclusions or authorization rules.
- [ ] Classified Bash writes that introduce architecture or JTBD human-oversight markers pass through the existing marker-discipline gates.
- [ ] After an authorized classified Bash write, architect refreshes the decision hash and compendium entry, and TDD runs its state-transition and test-quality-review post-write paths.
- [ ] Behavioral tests cover write redirection, read-only silence, unauthorized and evidence-backed oversight-marker writes, architect post-write refresh, and both TDD post-write routes.
- [ ] Each changed package contains a patch changeset, and packed candidates contain the classifier, hook registrations, and tests expected for that package.

## Driving problem trace (required — I6 invariant)

P503 records that edit gates use the `Edit|Write` tool matcher as a proxy for file mutation, so Bash-routed writes bypass review and architect post-write bookkeeping, leaving unreviewed changes and a stale decision hash.

## JTBD trace (required — I9 invariant)

- **JTBD-001**: every supported file-write route receives the same automatic governance without false-positive denials on read-only work.
- **JTBD-006**: unattended iterations can use their ordinary Bash route without silently escaping controls or poisoning a later honest edit.
- **JTBD-008**: one vertical story keeps the shared classifier, all gate callers, and their post-write effects together as one releasable fix.

## Implementation notes (optional)

Follow ADR-017: author one canonical helper under `packages/shared/hooks/lib/`, sync byte-identical copies into the five self-contained published plugins, and keep existing gate scripts authoritative for path policy. This story covers explicit supported write shapes only; it does not claim complete shell-language mutation detection.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- P503
- RFC-088
- ADR-005
- ADR-017
- ADR-045
- ADR-052
- ADR-103
