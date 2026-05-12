---
status: in-progress
rfc-id: p170-phase-2-story-tier-framework
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
adrs: [ADR-060]
jtbd: [JTBD-008, JTBD-001, JTBD-006, JTBD-101]
stories: [STORY-001, STORY-002, STORY-003, STORY-004, STORY-005, STORY-006, STORY-007]
---

# RFC-003: P170 Phase 2 — Story-tier framework + working-the-problem traversal

**Status**: in-progress
**Reported**: 2026-05-12
**Problems**: P170
**ADRs**: ADR-060 (Phase 2 amendment 2026-05-10 + encoding amendment 2026-05-12)
**JTBD**: JTBD-008 (primary), JTBD-001 (extended scope), JTBD-006 (AFK orchestrator protection), JTBD-101 (atomic-fix-adopter friction guard)

## Summary

Ships the Phase 2 story tier of the Problem-RFC-Story framework per ADR-060 amendment 2026-05-10 + encoding amendment 2026-05-12. Forward-dogfood RFC captured retroactively mid-implementation to satisfy ADR-060's Phase 2 self-dogfooding requirement (meta-recursive proof at the Phase 2 layer mirroring RFC-001's Phase 1 demonstration on P168).

## Driving problem trace

**P170** — Problem tickets strain as fixes decompose into multiple coordinated changes — need an RFC framework that ties all changes back to problems. Phase 2 SHIPS the story-tier primitives (capture-story / manage-story / reconcile-stories / list-stories) + RFC frontmatter `stories:` extension + working-the-problem traversal rewrite + hook exemption globs for the new HTML story-map surfaces. Story-map skills (Slices 3-6) are blocked on marketplace release of Slice 2.5 hook exemptions; bootstrap migration of STORY-MAP-001 (Slice 14) is similarly blocked.

## Scope

In scope (this RFC):
- Slice 2.5 — Hook exemption globs across 4 enforce-edit hooks (STORY-001)
- Slice 7 — `/wr-itil:capture-story` lightweight aside skill (STORY-002)
- Slice 10 — `/wr-itil:list-stories` read-only display skill (STORY-003)
- Slice 11 — RFC frontmatter `stories:` extension + capture-rfc/manage-rfc updates (STORY-004)
- Slice 13 — Working-the-problem traversal rewrite in manage-problem § Working a Problem → Known Error (STORY-005)
- Slice 9 — `/wr-itil:reconcile-stories` trio (STORY-006)
- Slice 8 — `/wr-itil:manage-story` heavyweight lifecycle skill (STORY-007)

Out of scope (deferred to a follow-on RFC after marketplace release):
- Slices 3-6 (story-map skills) — blocked on marketplace release of Slice 2.5 hook exemptions
- Slice 14 (STORY-MAP-001 bootstrap migration) — same blocker
- Slice 15 full bootstrap stories extraction — the 7 representative stories ship under this RFC; full extraction of every Slice 0-15 backbone + ribs deferred
- Slice 16 (P170 transition Known Error → Verification Pending) — final transition, separate commit

## Stories

(Auto-rendered from frontmatter `stories:` array in execution order via `update-rfc-references-section.sh "$rfc_file" "Stories"` — Slice 2b + 11 helper. Lazy-empty discipline: empty `stories: []` would omit the section entirely.)

1. [STORY-001](../stories/done/STORY-001-hook-exemption-globs.md) — Hook exemption globs across 4 enforce-edit hooks (done)
2. [STORY-002](../stories/done/STORY-002-capture-story.md) — `/wr-itil:capture-story` lightweight aside skill (done)
3. [STORY-003](../stories/done/STORY-003-list-stories.md) — `/wr-itil:list-stories` read-only display skill (done)
4. [STORY-004](../stories/done/STORY-004-rfc-stories-extension.md) — RFC frontmatter `stories:` extension + capture-rfc/manage-rfc updates (done)
5. [STORY-005](../stories/done/STORY-005-working-the-problem-traversal.md) — Working-the-problem traversal rewrite (done)
6. [STORY-006](../stories/done/STORY-006-reconcile-stories.md) — `/wr-itil:reconcile-stories` trio (done)
7. [STORY-007](../stories/done/STORY-007-manage-story.md) — `/wr-itil:manage-story` heavyweight skill (done)

## Commits

Auto-maintained by the commit-message trailer hook per ADR-060 line 270 + Phase 1 item 12:

- `b60f576` — Slice 2.5 hook exemption globs (STORY-001)
- `b9085b9` + `8280815` — Slice 7 capture-story (STORY-002)
- `c5b21ed` — Slice 10 list-stories (STORY-003)
- `cb7a90e` — Slice 11 RFC stories extension (STORY-004)
- `d0cd2a2` — Slice 13 working-the-problem traversal (STORY-005)
- `2f3c220` — Slice 9 reconcile-stories trio (STORY-006)
- `51de089` — Slice 8 manage-story (STORY-007)
- `<this commit>` — RFC-003 capture + 7 bootstrap stories (Slice 15 partial)

## Verification

Phase 2 framework code ships per the 7 stories above. Forward-dogfood validates each story's acceptance criteria. Held-changeset graduation per ADR-042 / P162 gates adopter release.

**Outstanding**: Slices 3-6 (story-map skills) + Slice 14 (STORY-MAP-001 bootstrap) remain blocked on marketplace release of Slice 2.5 hook exemptions. RFC-003 reaches `verifying` when those slices ship in a follow-on session post-release.

## Related

- **P170** — driving problem ticket.
- **ADR-060** — Problem-RFC-Story framework; Phase 2 amendment 2026-05-10 + encoding amendment 2026-05-12.
- **RFC-001** — Phase 1 retro on P168 (precedent for retroactive RFC capture).
- **RFC-002** — P069 forward-dogfood (precedent for in-flight RFC graduation).
- **JTBD-008** — Decompose a Fix Into Coordinated Changes; primary persona-anchor.
- **JTBD-001** — Enforce Governance Without Slowing Down (extended scope per Phase 2).
- **JTBD-006** — Progress the Backlog While I'm Away (I11 no-WSJF-leak protects orchestrator).
- **JTBD-101** — Plugin-developer atomic-fix-adopter friction guard.
