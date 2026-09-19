---
status: accepted
story-id: a-clean-reconciler-result-means-the-tier-really-is-clean
reported: 2026-09-19
decision-makers: [Tom Howard]
problems: [P472]
jtbd: [JTBD-006]
rfcs: [RFC-100]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-099: A clean reconciler result means the tier really is clean

**Reported**: 2026-09-19
**Problems**: P472
**JTBD**: JTBD-006
**RFCs**: RFC-100
**Story Maps**: STORY-MAP-002
**Estimated effort**: M — derived at capture. One predicate plus a bucket split in the reconciler, one gate on the repair helper, one accessor on the shared lib, two bats suites and a changeset.

## User value (required, INVEST Valuable)

In order to use the story reconciler as a real clean/dirty signal instead of learning to
ignore it, as a developer draining the backlog unattended, I want it to demand a
reverse-trace row only from the stories the ratified-stories rule actually covers, and to
say out loud which population it checked — so that a clean result means "checked and
clean" rather than "quietly skipped", and satisfying a finding never requires breaking the
rule the finding exists to protect.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] A story whose map is not ratified, linked to a markdown RFC whose `## Stories` omits it, produces no `MISSING_REVERSE_TRACE` line and the run exits 0.
- [ ] A story whose every named map IS ratified, missing from its markdown RFC's `## Stories`, still produces the `MISSING_REVERSE_TRACE` line and the run exits 1.
- [ ] Every run of the RFC leg writes one line to stderr naming how many pairs were checked, how many were skipped as unratified, and how many were skipped because the story names no map at all — the last counted separately, because that is a corpus defect and not a correct absence.
- [ ] The repair helper that regenerates an RFC's `## Stories` section refuses to write a story whose map is not ratified, so the prescribed repair for a real finding cannot introduce the reference the rule forbids.
- [ ] stdout carries drift lines only and the exit codes stay 0 / 1 / 2, so the skill's line-by-line parse of the redirected stdout is unchanged.

## Driving problem trace (required — I6 invariant)

P472 — the reconciler's RFC leg demands a `## Stories` row for every story that names an
RFC, with no predicate on the story. The ratified-stories rule forbids an RFC from
referencing a story whose map is not ratified, so for those stories the row's absence is
correct and the finding can never be cleared by any compliant action.

## JTBD trace (required — I9 invariant)

JTBD-006 (progress the backlog while I'm away) — an unattended loop reads detector output
as its clean/dirty signal. A detector that reports correct work as drift either pushes the
loop into the violation or trains it to discount the detector everywhere else; both cost
the loop the ability to tell whether the tier is actually clean.

## Implementation notes (optional)

Approval reaches a story through its map, so `story_is_approved` is the predicate — not any
`human-oversight:` field left on a story file, which is legacy and deliberately ignored.
The release-row leg stays ungated: a card is compelled onto the map at capture and cards sit
outside the map's fingerprint basis, so its absence is never correct.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

(captured via /wr-itil:capture-story; expand at next /wr-itil:manage-story invocation)
