<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: capture-story
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-001]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: M
---

# STORY-002: /wr-itil:capture-story lightweight aside skill

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-001
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred — Slice 14 blocked)
**Estimated effort**: M

## User value (INVEST Valuable)

As a plugin maintainer mid-flow, I want a lightweight `/wr-itil:capture-story` aside skill that captures INVEST-shaped stories with mandatory problem + JTBD traces in a single commit so I can slice an RFC into stories without leaving my current task context.

## Acceptance criteria (INVEST Testable)

- [x] `packages/itil/skills/capture-story/SKILL.md` ships (~430 lines) mirroring capture-rfc shape
- [x] Positional grammar `<problem-trace> <jtbd-trace> <description>` — both mandatory at capture (I6 + I9 hard-block)
- [x] Optional `--rfc` + `--story-map` flags (I7 + I8 enforce-at-accepted, not at capture per ADR-060 line 291)
- [x] Inline `max(local, origin) + 1` STORY-NNN ID allocation (ADR-019 inline path)
- [x] Single `Refs: STORY-NNN` trailer (single-trailer vocabulary per ADR-060 line 307)
- [x] Inline reverse-trace `## Stories` refresh on problem + JTBD + RFC parents; NO refresh on story-map HTML
- [x] 12 behavioural bats green covering load-bearing surfaces

## Driving problem trace (I6)

**P170** Phase 2 implementation task list (Slice 7) names this skill explicitly.

## JTBD trace (I9)

**JTBD-008** — capture-story is the load-bearing surface for capture-time decomposition decisions at the story tier.
**JTBD-001** (extended scope) — story-level governance via INVEST gates at acceptance.

## Implementation notes

Architect AMEND verdict 2026-05-12 closed (finding 1 single-trailer + finding 2 no story-map inline refresh both applied). JTBD PASS verdict.

## Dependencies

- **Blocks**: STORY-007 (manage-story extends this surface with lifecycle management).
- **Blocked by**: (none)

## Related

- ADR-060 line 291 (skill description authority).
- RFC-003 (parent RFC).
- Commits `b9085b9` + `8280815`.
