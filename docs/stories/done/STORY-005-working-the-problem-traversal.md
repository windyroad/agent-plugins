<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: working-the-problem-traversal
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-001, JTBD-006]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: M
---

# STORY-005: Working-the-problem traversal rewrite (manage-problem + work-problem)

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-001, JTBD-006
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred)
**Estimated effort**: M

## User value (INVEST Valuable)

As a maintainer working a Known Error problem, I want a deterministic Problem → RFC → Story dispatch in manage-problem § Working a Problem so that "implement the fix" is concretely traceable — read the problem's Fix Strategy, traverse referenced RFCs in order, pick the first not-done story from each RFC's frontmatter `stories:` array, implement scope-bounded to the story, attribute via `Refs: STORY-NNN` trailer.

## Acceptance criteria (INVEST Testable)

- [x] manage-problem § Working a Problem → Known Error subsection rewritten with 8-step traversal per ADR-060 lines 300-320
- [x] Atomic-RFC fallback path (empty `stories: []`) preserves Phase 1 per-RFC iter dispatch — JTBD-101 friction guard
- [x] Legacy direct-implementation path (no-RFC Fix Strategy) preserves backwards compat with pre-Phase-1-graduation problems
- [x] Single `Refs: STORY-NNN` trailer per ADR-060 line 307 + amendment 2026-05-10 nitpick N2
- [x] Story auto-transition triggers named: draft → in-progress on first non-capture commit; in-progress → done on all-criteria-ticked + RFC closed
- [x] work-problem § Step 3 Known Error case rewritten to forward-point to manage-problem traversal
- [x] 10 behavioural bats green covering Fix-Strategy extraction + stories: ORDERED contract + filter logic + fallback paths + single-trailer + auto-transitions + forward-pointing

## Driving problem trace (I6)

**P170** Phase 2 implementation task list (Slice 13) plus ADR-060 § Phase 2 commit-grain decomposition line 457.

## JTBD trace (I9)

**JTBD-008** — traversal operationalises "first-class entity" Desired Outcome at implementation time.
**JTBD-001** (extended scope) — change-set-level governance via per-story dispatch.
**JTBD-006** — preserved by atomic-RFC fallback (AFK orchestrator behaviour unchanged for atomic RFCs).

## Implementation notes

Two fallback paths (atomic-RFC empty-stories + legacy no-RFC) preserve all Phase 1 behaviours — zero friction for atomic-fix-adopters or legacy Known Error problems captured before Phase-1 graduation. Held-area path blocked by P141 hook P177 limitation; changeset rides active queue with risk-scorer clearance at 3/25 Low.

## Dependencies

- **Blocks**: Slice 15 bootstrap stories extraction (this story IS one of the bootstrap stories).
- **Blocked by**: STORY-004 (RFC stories: extension provides the `stories:` array that this traversal reads).

## Related

- ADR-060 lines 300-320 (working-the-problem flow authority).
- ADR-060 line 307 + nitpick N2 (single-trailer vocabulary).
- RFC-003 (parent RFC).
- Commit `d0cd2a2`.
