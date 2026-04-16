# Problem 017: `create-adr` skill does not flag or split multi-decision inputs

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 9 (Medium) — Impact: Moderate (3) x Likelihood: Possible (3)

## Description

When the user asks `/wr-architect:create-adr` to record an architectural decision whose description actually contains multiple distinct decisions, the skill produces a single conflated ADR instead of splitting it or flagging the issue. The skill's intake does no decision-boundary analysis.

This is the same failure mode as P016 (`manage-problem` conflating multi-concern tickets) — different skill, identical pattern. ADRs are a core governance artefact; a single ADR covering two unrelated decisions damages auditability, defeats status transitions (one decision may land while the other is still proposed), and makes it hard to reference the decision from downstream artefacts.

## Symptoms

- ADRs in `docs/decisions/` that weave together two or more unrelated decisions under one ID.
- Status transitions stall when one half of the ADR is accepted and the other is not — the file cannot move from `.proposed.md` to `.accepted.md` cleanly.
- Cross-references from problems, JTBDs, and code comments become ambiguous ("see ADR-009" — which part?).
- The "Consequences" and "Alternatives" sections bloat trying to cover two decision spaces at once.
- No prompt in the skill asks "does this description contain multiple distinct decisions?"

## Workaround

Rely on the user to spot the conflation and request a split after the fact. Same expensive rework pattern as P016.

## Impact Assessment

- **Who is affected**:
  - Tech-lead persona (governance + auditability) — ADRs are the primary audit artefact; conflation weakens the trail.
  - Plugin-developer persona (JTBD-101 Extend the Suite) — inconsistent ADR scoping makes the "clear patterns, not reverse-engineering" outcome harder to meet.
  - Solo-developer persona (JTBD-001 Enforce Governance Without Slowing Down) — downstream skills that reference ADRs get garbled signals.
- **Frequency**: Any session where the user describes an architectural question in a paragraph spanning more than one decision surface. Common during retros or when capturing multiple learnings at once.
- **Severity**: Medium. The skill still works; the artefacts are just wrong-shaped and require rework.
- **Analytics**: Observed anecdotally this session. User reported: "the create-adr has a similar issue where it groups multiple decisions that should be separate ADRs."

## Root Cause Analysis

`create-adr` (`packages/architect/skills/create-adr/SKILL.md`) gathers context and writes a single file. It has no decision-boundary-analysis step. Contributing factors mirror P016:

1. **No boundary heuristic.** No prompt asks "list the distinct decisions; if >1, propose a split."
2. **Single-file output assumption.** The skill writes exactly one `.proposed.md`. Emitting `NNN` + `NNN+1` is not contemplated.
3. **No cross-skill pattern.** P016 identifies the same gap in `manage-problem`. Fixing them independently would duplicate logic; a shared "concern-splitting" pattern would be better but is not yet designed.

### Investigation Tasks

- [ ] Decide whether the fix is a per-skill step or a shared helper used by both `create-adr` and `manage-problem`. A shared helper implies a new pattern — architect noted this might warrant its own ADR covering both P016 and P017 fixes.
- [ ] Design the decision-boundary heuristic. Candidates mirror P016: (a) LLM self-check listing distinct decisions; (b) structural signal — if the input names multiple components, subsystems, or conflicting trade-offs, force the split prompt; (c) post-draft heuristic — count distinct "Decision" or "Context" blocks
- [ ] Decide automatic vs AskUserQuestion-gated split (tension with P014 "capture should interrupt flow minimally")
- [ ] Update `packages/architect/skills/create-adr/SKILL.md` with the new step
- [ ] Add a test case with a deliberately multi-decision input to exercise the split behaviour

## Related

- Sibling: `docs/problems/016-manage-problem-should-split-multi-concern-tickets.open.md` — same failure mode in a different skill
- Related tension: `docs/problems/014-aside-capture-for-problems.open.md` — split friction vs capture friction
- `packages/architect/skills/create-adr/SKILL.md` — target for the fix
- JTBD-001: `docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`
- JTBD-101: `docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`
- Tech-lead persona: `docs/jtbd/tech-lead/persona.md`
