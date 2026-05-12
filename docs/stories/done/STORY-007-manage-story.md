<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: manage-story
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-001]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: L
---

# STORY-007: /wr-itil:manage-story heavyweight story lifecycle skill

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-001
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred)
**Estimated effort**: L

## User value (INVEST Valuable)

As a plugin maintainer, I want a heavyweight `/wr-itil:manage-story` skill that handles the full story lifecycle (draft → accepted → in-progress → done → archived) with I7+I8+I10 hard-block at accepted transition, INVEST 4-axis check, auto-transitions on `Refs: STORY-NNN` commit trailers + linked RFC closure, and inline reverse-trace refresh on 4 parent tiers, so that stories progress through their lifecycle with all invariants enforced and parent artefacts stay current.

## Acceptance criteria (INVEST Testable)

- [x] `packages/itil/skills/manage-story/SKILL.md` ships (~310 lines) mirroring manage-rfc shape
- [x] Lifecycle: draft → accepted → in-progress → done → archived (5 states, native per-state subdir)
- [x] I6-I11 invariant table; I7+I8+I10 hard-block at accepted transition
- [x] INVEST 4-axis check (Testable / Valuable / Independent / Estimable); L/XL decomposition-candidate advisory per nitpick N3
- [x] Single `Refs: STORY-NNN` trailer per ADR-060 line 307
- [x] Auto-transition triggers: draft→in-progress on first non-capture commit; in-progress→done on all-criteria-ticked + RFC closed
- [x] Bootstrap-exemption marker contract per ADR-060 line 339
- [x] Reverse-trace refresh on 4 parent tiers (problem / JTBD / RFC via helpers; story-map manual)
- [x] P062 README refresh on every transition
- [x] 19 contract bats green covering all surfaces above

## Driving problem trace (I6)

**P170** Phase 2 implementation task list (Slice 8). Companion to capture-story (STORY-002).

## JTBD trace (I9)

**JTBD-008** — INVEST enforcement at accepted gate ensures stories are well-formed before implementation.
**JTBD-001** (extended scope) — story-level governance via lifecycle transitions.

## Implementation notes

Largest skill in the story-tier MVP. Companion to capture-story (Slice 7) per ADR-032 lightweight + heavyweight split. Together with STORY-002 + STORY-003 + STORY-006, completes the story-tier MVP.

## Dependencies

- **Blocks**: Story lifecycle progression — without manage-story, draft stories can never reach accepted/in-progress/done.
- **Blocked by**: STORY-002 (capture-story produces drafts).

## Related

- ADR-060 lines 200-253 (story tier spec).
- ADR-060 line 252 (INVEST shape authority).
- ADR-060 line 292 (auto-transition triggers).
- ADR-060 line 339 + ADR-053 (bootstrap-exemption marker).
- RFC-003 (parent RFC).
- Commit `51de089`.
