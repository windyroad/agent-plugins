---
status: accepted
story-id: reconciler-reports-and-repairs-duplicate-ticket-ids
reported: 2026-09-03
decision-makers: [Tom Howard]
problems: [P533]
jtbd: [JTBD-006]
rfcs: [RFC-090]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-085: See the ID clash instead of the drift it causes

**Reported**: 2026-09-03
**Problems**: P533
**JTBD**: JTBD-006
**RFCs**: RFC-090
**Story Maps**: STORY-MAP-002
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to act on a drift report rather than investigate it — so that time goes into the
backlog instead of into a README inconsistency that was never there — as someone picking the
next ticket out of the queue, I want two tickets claiming one number to be reported as
exactly that, and renumbered on request, so the report names the cause instead of the
symptom it produced.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Two files claiming one ID produce a `CLASH` row naming both files, rather than drift
  rows describing whichever file survived the last-writer-wins map assignment.
- [ ] The `CLASH` row stays inside the 150-byte per-row budget the other drift classes obey.
- [ ] An opt-in `--fix-clashes` flag renumbers the later claimant; the earlier claimant keeps
  the number. Without the flag the script stays read-only, as its contract states.
- [ ] Which ticket claimed the number first comes from the first-add commit on main, so the
  answer does not depend on who checked out what when. Outside a repository it falls back to
  modification time.
- [ ] The replacement ID is `max(local, origin) + 1` per the ratified allocation rule, so a
  renumber cannot land on a number created on origin and recreate the clash it is fixing.
- [ ] References to the renumbered ticket from elsewhere in `docs/` are rewritten wherever
  they resolve; the genuinely ambiguous ones are reported rather than guessed at.
- [ ] The script's docblock no longer claims to be unconditionally read-only, since the flag
  moves files and rewrites content.
- [ ] Behavioural bats in `packages/itil/scripts/test/reconcile-readme.bats` cover detection,
  the renumber including the next-free-ID choice and reference rewriting, and the no-clash
  no-op.
- [ ] A `.changeset/*.md` bumps `@windyroad/itil`.

## Driving problem trace (required — I7 invariant)

- **P533** — `FS_STATUS["$id"]` is a plain associative-array assignment in both enumeration
  loops, so a repeated ID is last-writer-wins with no collision check. The drift check then
  reports ordinary-looking rows about the surviving file and never names the clash. Observed
  with ticket 238 existing as both open and verifying, created by different sessions.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006 (progress the backlog while I'm away): an unattended drain reads this report
to pick its next ticket, and a drift row whose stated cause is not the real one costs it an
iteration and leaves the clash in place for the next run. Secondary JTBD-001 — a governance
check that reports the wrong cause is worse than one that stays quiet, because it spends
attention and returns nothing.
