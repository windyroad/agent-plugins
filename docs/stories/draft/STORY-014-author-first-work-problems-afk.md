---
status: draft
story-id: author-first-work-problems-afk
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P314]
jtbd: [JTBD-008, JTBD-006]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-014: Unattended, the agent works the plan and pauses for real decisions

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251, P314
**JTBD**: JTBD-008, JTBD-006
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

As the AFK `/wr-itil:work-problems` orchestrator dispatching a fix on an RFC-less Known Error, I want to **author the RFC's story map first** (for an unambiguous or already-ADR-covered fix) then implement — and to **lawfully halt the loop for ADR ratification** when the fix requires an option-choice no existing ADR covers — so that AFK work never silently builds a hollow fix nor silently makes a new direction-setting decision.

## Acceptance criteria (INVEST Testable)

- [ ] Unambiguous / already-covered fix → the AFK clause authors the RFC story-map first, then implements its stories; no auto-create-and-proceed.
- [ ] Uncovered option-choice → the loop **lawfully halts** and queues the decision for the user's return (JTBD-006 judgment-queue / ADR-019 graceful-stop), rather than picking it.
- [ ] The iter-constraint block reflects "author-RFC-first is the in-scope mandatory step for this iter's fix" (not an aside-capture prohibition violation).
- [ ] Event is structured-logged for the audit trail (JTBD-006).

## Driving problem trace (I6)

**P251 / P314.** The shipped work-problems clause auto-creates the RFC then proceeds (repudiated). This story reworks the AFK surface to author-first with a lawful halt on uncovered decisions. Subordinates JTBD-006's "never stall" to process correctness per ADR-073. Supersedes RFC-005 B5 (rework slice B14).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. **JTBD-006** — Progress the Backlog While I'm Away (deliberately subordinated: a lawful halt for an uncovered decision is correct, not a failure).

## Dependencies

- **Blocks**: STORY-016 (bats assert the AFK behaviour at every effort level).
- **Blocked by**: STORY-012 (predicate signal), STORY-013 (work-problems delegates fix work through the manage-problem traversal).

## Related

- RFC-005 B14; supersedes B5. ADR-073 (RFC-first subordinates never-stall), ADR-019 (graceful-stop), JTBD-006.
