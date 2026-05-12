<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: list-stories
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-006]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: S
---

# STORY-003: /wr-itil:list-stories read-only display skill

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-006
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred)
**Estimated effort**: S

## User value (INVEST Valuable)

As a plugin maintainer or AFK orchestrator, I want a read-only `/wr-itil:list-stories` view that renders stories grouped by lifecycle state OR filtered by `--rfc RFC-NNN` in the RFC's frontmatter execution order, so I can see the story corpus at a glance and dispatch the next not-done story under any RFC.

## Acceptance criteria (INVEST Testable)

- [x] `packages/itil/skills/list-stories/SKILL.md` ships (~160 lines) mirroring list-problems precedent
- [x] Allowed-tools: Read, Bash, Grep, Glob only (no Write / Edit — read-only contract per ADR-010)
- [x] Unfiltered mode renders 5 lifecycle-grouped tables (draft / accepted / in-progress / done / archived)
- [x] Filtered mode (`--rfc RFC-NNN`) renders single execution-order table from RFC frontmatter `stories:`
- [x] Cache-freshness via `git log -1` per P031
- [x] I11 no-WSJF-leak invariant: no WSJF column in any rendered table
- [x] 7 contract bats green

## Driving problem trace (I6)

**P170** Phase 2 implementation task list (Slice 10).

## JTBD trace (I9)

**JTBD-008** — per-RFC ordered view operationalises the "first-class entity" Desired Outcome at the display surface.
**JTBD-006** — filtered mode feeds the AFK orchestrator's per-RFC iter dispatch in Slice 13.

## Implementation notes

Mirrors `list-problems` precedent (P071 phased-landing split per ADR-010). Architect+JTBD review of broader Slice 7 P170 work established the skill-tier patterns; list-stories is the simplest variant.

## Dependencies

- **Blocks**: (none — read-only)
- **Blocked by**: Filtered mode (`--rfc`) requires Slice 11 RFC stories: extension to be useful in practice.

## Related

- ADR-060 line 294 (skill description authority).
- RFC-003 (parent RFC).
- Commit `c5b21ed`.
