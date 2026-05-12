<!-- bootstrap-exempt: STORY-MAP-001 migration per ADR-060 amendment 2026-05-10 -->
---
status: done
story-id: rfc-stories-extension
reported: 2026-05-12
decision-makers: [Tom Howard]
problems: [P170]
jtbd: [JTBD-008, JTBD-101]
rfcs: [RFC-003]
story-maps: [STORY-MAP-001]
estimated-effort: S
---

# STORY-004: RFC frontmatter stories: extension + capture-rfc / manage-rfc updates

**Status**: done
**Reported**: 2026-05-12
**Problems**: P170
**JTBD**: JTBD-008, JTBD-101
**RFCs**: RFC-003
**Story Maps**: STORY-MAP-001 (deferred)
**Estimated effort**: S

## User value (INVEST Valuable)

As a plugin maintainer building Phase 2, I want the RFC frontmatter to carry an ORDERED `stories:` array (0..N cardinality) so that RFCs can reference the stories implementing them in execution sequence, with `capture-rfc --stories STORY-NNN,...` populating at capture and `manage-rfc` rendering a `## Stories` body section from the array on every lifecycle transition.

## Acceptance criteria (INVEST Testable)

- [x] `docs/rfcs/README.md` frontmatter spec gains `stories: [STORY-<NNN>, ...]` field with 0..N + ORDERED contract + atomic-RFC empty-array case
- [x] `docs/rfcs/README.md` body structure spec gains `## Stories (Phase 2 — maintained)` section with lazy-empty discipline
- [x] capture-rfc accepts `--stories STORY-NNN,STORY-NNN,...` flag; populates frontmatter; renders `## Stories` body section before commit
- [x] manage-rfc Step 7 invokes `update-rfc-references-section.sh "$rfc_file" "Stories"` on every lifecycle transition (idempotent + lazy-empty)
- [x] 7 behavioural bats green covering populated + empty stories: handling on Slice 2b helper

## Driving problem trace (I6)

**P170** Phase 2 task list (Slice 11) plus ADR-060 § Phase 2 commit-grain decomposition line 456.

## JTBD trace (I9)

**JTBD-008** — `stories:` array IS the capture-time decomposition mechanism at the RFC tier.
**JTBD-101** — empty `stories: []` ships as atomic RFC, preserving atomic-fix-adopter friction guard per ADR-060 line 262.

## Implementation notes

Unlocks STORY-MAP-001 bootstrap migration (Slice 14) by giving the RFC frontmatter something to populate. Composes with STORY-002 (capture-story) and STORY-003 (list-stories `--rfc` filter mode).

## Dependencies

- **Blocks**: STORY-MAP-001 bootstrap (needs `stories:` array to populate on RFC-001 + RFC-002 + RFC-003).
- **Blocked by**: (none)

## Related

- ADR-060 line 259 (ORDERED contract authority).
- ADR-060 line 262 (atomic-RFC empty-array case).
- ADR-060 line 270 + 296 (manage-rfc body section refresh contract).
- RFC-003 (parent RFC).
- Commit `cb7a90e`.
