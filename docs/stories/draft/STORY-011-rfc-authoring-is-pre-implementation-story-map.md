---
status: draft
story-id: rfc-authoring-is-pre-implementation-story-map
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P399]
jtbd: [JTBD-008]
rfcs: [RFC-005]
estimated-effort: M
---

# STORY-011: RFC authoring produces a pre-implementation story map; the --fix-time byproduct path is retired

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251, P399
**JTBD**: JTBD-008
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

As a maintainer authoring an RFC for a fix, I want `/wr-itil:capture-rfc` (and the heavyweight `/wr-itil:manage-rfc`) to author the RFC as a **pre-implementation user story map** (ADR-060) — not a fix-time `## Scope`+`## Tasks` blob emitted as a byproduct of the fix — so that the RFC is a real plan that precedes implementation, and the held `--fix-time` changeset's repudiated mechanism is retired.

## Acceptance criteria (INVEST Testable)

- [ ] `/wr-itil:capture-rfc` authors a pre-implementation story map (backbone + stories), not a fix-time Scope/Tasks blob.
- [ ] The `capture-rfc --fix-time` byproduct flag/path (shipped 2026-06-28, held) is **retired**; its held changeset is resolved (graduated-as-reworked or dropped).
- [ ] `/wr-itil:manage-rfc` produces/maintains the same story-map shape.
- [ ] **Forward-dogfood**: take a real Known-Error problem from the RFC-005 B7 backlog, author its RFC story map **first** (citing existing ADRs, or escalating an uncovered option to a ratified ADR), THEN implement one story — confirming RFC-first ordering end-to-end.

## Driving problem trace (I6)

**P251 / P399.** P399 corrected the symptom (skeletons under-scoped) but kept the root error (RFC fabricated at/after fix-time); ADR-073 RFC-first repudiates fix-time authoring entirely. This story retires the `--fix-time` path and makes RFC authoring a pre-implementation story-map step. Supersedes RFC-005 B8 + the held B11 `--fix-time` changeset (rework slice B15).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes. The story map IS the decomposition; authoring it before implementation is the dogfood of RFC-first.

## Dependencies

- **Blocks**: STORY-013 (backfill reuses the pre-implementation story-map authoring path), RFC-005 B10 (held-changeset graduation gated on this + STORY-012).
- **Blocked by**: STORY-009 (the author-first gate invokes this authoring path).

## Related

- RFC-005 B15; supersedes B8 + held B11. ADR-073 (RFC-first), ADR-060 (RFC = story map), P399 (the held --fix-time changeset).
