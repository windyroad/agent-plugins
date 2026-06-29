---
status: draft
story-id: author-first-manage-problem-gate
reported: 2026-06-29
decision-makers: [Tom Howard]
problems: [P251, P314]
jtbd: [JTBD-008, JTBD-001]
rfcs: [RFC-005]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-013: manage-problem propose-fix gate authors the RFC first, escalates uncovered choices to an ADR

**Status**: draft
**Reported**: 2026-06-29
**Problems**: P251, P314
**JTBD**: JTBD-008, JTBD-001
**RFCs**: RFC-005
**Estimated effort**: M

## User value (INVEST Valuable)

As a maintainer proposing a fix in `/wr-itil:manage-problem`, I want the propose-fix gate to route me by RFC-precondition: if an RFC already traces the problem, implement its stories; if none does, **author the RFC first** (a user-story-map decomposition derived from the problem's RCA) as a deliberate pre-implementation step — never auto-create a skeleton and proceed — so that the fix genuinely implements a pre-existing plan.

## Acceptance criteria (INVEST Testable)

- [ ] Pre-existing RFC → the gate proceeds to implement its stories.
- [ ] No RFC → the gate routes to **author the RFC first** (story-map decomposition from RCA) before any implementation; no auto-create-skeleton-and-proceed.
- [ ] Authoring surfaces a fix-approach choice **not covered** by existing ADRs → the gate **escalates to a new ratified ADR before implementation** (the orchestrator does not pick it).
- [ ] A fix-approach choice **covered** by existing ADRs → cite the ADRs and proceed (no new ADR; P132).
- [ ] No `--rfc-deferred` hatch (carve-out repudiated).

## Driving problem trace (I6)

**P251 / P314.** The shipped manage-problem traversal auto-creates a skeleton via capture-rfc and proceeds (repudiated by ADR-073 RFC-first). This story reworks the interactive propose-fix surface (the ADR-072 gate point) to author-first. Supersedes RFC-005 B4 (rework slice B13).

## JTBD trace (I9)

**JTBD-008** — Decompose a Fix Into Coordinated Changes (the RFC story-map IS the decomposition). **JTBD-001** — Enforce Governance Without Slowing Down (covered choices proceed autonomously; only genuinely-new decisions stop for ratification).

## Release split (per STORY-MAP-002)

This story spans two releases on the map. **Release 1 (walking skeleton)** ships only the **thin routing slice**: consume the STORY-012 predicate signal and route the maintainer to author-first on a *covered* fix — the minimum that makes R1 operable end-to-end. **Release 2** ships the **full gate**: the pre-existing-RFC → implement branch, and the uncovered-approach → escalate-to-ratified-ADR branch.

## Dependencies

- **Blocks**: STORY-016 (bats assert this gate's behaviour).
- **Blocked by**: STORY-012 (consumes the refuse/route predicate signal).

## Related

- RFC-005 B13; supersedes B4. ADR-072 (gate placement), ADR-073 (RFC-first), ADR-070 (uncovered option → ADR), ADR-044 (cat-1 boundary), P132 (don't re-decide covered choices).
