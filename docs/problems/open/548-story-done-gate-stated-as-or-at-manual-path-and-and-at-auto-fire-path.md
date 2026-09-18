# Problem 548: The story `done` gate is stated as an OR on the manual path and an AND on the auto-fire path, so the same story is simultaneously done-eligible and not

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 6 (Medium) — Impact: 2 (Minor — dev tooling / governance-contract ambiguity; no published package or installed plugin misbehaves, but two agents reading two sentences in the same SKILL reach opposite lifecycle verdicts) × Likelihood: 3 (Possible — fires whenever a story's criteria are all ticked while its RFC is still `verifying`, which is the normal shape for a multi-story RFC whose last story lands before the RFC closes) — derived at capture per Step 4a
**Origin**: internal
**Effort**: S — derived at capture per Step 4a; the repair is a prose reconciliation across three sentences in two SKILL files plus a stale ADR-060 line-number anchor. No code path changes.
**WSJF**: 6.0 — (6 × 1.0) / 1 (Open multiplier 1.0; Effort S divisor 1) — derived at capture
**JTBD**: JTBD-008
**Persona**: developer

## Description

`in-progress → done` for a story is specified three times, and the manual path's condition is strictly weaker than the auto-fire path's:

- `packages/itil/skills/manage-story/SKILL.md` line 112 — the **manual** `manage-story <NNN> done` gate: *"ALL `- [ ]` checkboxes in `## Acceptance criteria` are ticked (i.e. zero unticked); linked RFC status is `closed` **OR** the RFC's other stories have closed"*.
- `packages/itil/skills/manage-story/SKILL.md` line 134 — the **auto-fire** trigger: *"all `- [ ]` lines in `## Acceptance criteria` are ticked **AND** the linked RFC is `closed`"*.
- `packages/itil/skills/manage-problem/SKILL.md` line 236 — same AND form, plus the explicit rationale: *"the story stays at `in-progress` until the RFC closes — this preserves the trace coupling"*.

For a story whose criteria are all ticked, whose sibling stories are all terminal, and whose RFC is still `verifying`, line 112 says done-eligible and lines 134/236 say not-yet. Both readings are defensible from the text; nothing in the SKILL says the manual and auto-fire gates are *meant* to differ, and line 236 supplies a substantive reason (trace coupling) for the stricter form that line 112 silently discards.

**Observed 2026-09-19** during the P160 iteration. STORY-044 had all eight acceptance criteria ticked; its siblings STORY-039 (archived), STORY-042 (done) and STORY-043 (done) were all terminal; RFC-046 was `verifying`. The iteration transitioned it to `done` on line 112's OR branch, and the architect gate confirmed that reading as correct-for-the-manual-path while flagging the divergence as a real corpus inconsistency. The transition is not in doubt; the contract is.

A further wrinkle the same review surfaced: `archived` is a terminal state distinct from `done` (line 113 defines it as "manual close-without-completion"). Line 112's OR branch says "**closed**", which admits an archived sibling; `manage-problem` line 238's problem-level trigger says all stories must be "**done**", which does not. That asymmetry may be deliberate, but it is undocumented, and it decided a real outcome in the P160 iteration (STORY-039 being archived is why the problem-level Known Error → Verification Pending trigger did not fire).

## Symptoms

- `grep -n "linked RFC" packages/itil/skills/manage-story/SKILL.md` returns both the OR form (line 112) and the AND form (line 134).
- A story with all criteria ticked and a `verifying` RFC is done-eligible or not depending on which sentence the agent read.
- `manage-problem` SKILL.md line 236 states a rationale ("preserves the trace coupling") for a stricter gate than its sibling SKILL's manual path enforces.
- The `## Related` anchor `ADR-060 line 292` (cited at `manage-story/SKILL.md` line 255) points at the reverse-trace-helpers bullet in the current ADR-060 body; the auto-transition triggers are at line 310. `manage-problem`'s "line 309" citation for the trace-coupling clause is off by one for the same reason.

## Workaround

Read line 112 as governing the manual `manage-story <NNN> done` invocation and lines 134/236 as governing the auto-fire sweep at `manage-rfc` close, treating the divergence as intentional. This is what the 2026-09-19 architect review concluded and what the P160 iteration acted on. It is a reading, not a statement in the text — a different agent may reasonably pick the AND form and leave a completed story stranded at `in-progress` until its RFC closes.

## Impact Assessment

- **Who is affected**: `developer` persona decomposing a fix into coordinated changes (JTBD-008). The story tier exists to make "what is left to do" legible; a lifecycle gate with two readings makes the answer depend on which agent ran, which is the opposite of that.
- **Frequency**: Fires whenever the last story under a multi-story RFC completes before the RFC closes. That is the normal ordering, not an edge case — RFC-046's own shape produced it.
- **Severity**: Minor (2) per RISK-POLICY.md — dev tooling affected; published packages and installed plugins unaffected. The cost is drift between the Story Rankings table and reality, plus agent-to-agent inconsistency in an audit surface (JTBD-201).
- **Analytics**: Three divergent statements across two SKILL files, observed 2026-09-19. One real transition (STORY-044) decided on the weaker branch.

## Root Cause Analysis

### Preliminary Hypothesis

The manual gate and the auto-fire trigger were written at different times against different needs. The auto-fire form is the original ADR-060 line 310 contract (strict AND, trace coupling preserved). The manual form's OR branch looks like a later pragmatic relaxation — without it, a story cannot be marked done ahead of its RFC even when every sibling is terminal and the work is demonstrably shipped, which would strand the Story Rankings table. The relaxation was applied to one of the three statements and not propagated, and no note records that the divergence is intentional.

If that reading is right the fix is prose, not logic: state explicitly that the manual path is deliberately weaker, say why, and cross-reference both sentences to each other. If the divergence is *not* intentional, one of the two forms is a defect and the other is the contract.

### Investigation Tasks

- [ ] Determine from ADR-060's body (line 310) and its amendment history whether the manual OR branch was an intentional relaxation or unpropagated drift.
- [ ] Reconcile the three statements: either document the manual/auto-fire asymmetry explicitly at all three sites, or converge them on the correct single form.
- [ ] Document whether a terminal-but-`archived` sibling satisfies "the RFC's other stories have closed" (line 112) and why the problem-level trigger at `manage-problem` line 238 requires "done" instead — or converge those two as well.
- [ ] Repair the stale ADR-060 line anchors in `manage-story/SKILL.md` line 255 (cites 292, should be 310) and `manage-problem/SKILL.md` (cites 309, should be 310). **Do NOT repair by editing ADR-060** — it carries `human-oversight: confirmed` and changes only by supersession per ADR-116. Fix the citing prose.
- [ ] Behavioural test asserting one consistent verdict for the criteria-ticked + RFC-verifying + siblings-terminal case, whichever form wins.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P160 (the iteration that surfaced this — STORY-044's transition was decided on the OR branch); ADR-060 (the story-tier framework whose line 310 states the auto-fire trigger); ADR-096 (removed `draft → in-progress`; the adjacent lifecycle-edge clarification precedent).

## Related

- `packages/itil/skills/manage-story/SKILL.md` lines 112, 113, 134, 255 — the manual gate, the `archived` definition, the auto-fire trigger, and the stale ADR-060 anchor.
- `packages/itil/skills/manage-problem/SKILL.md` lines 236, 238 — the AND-form auto-fire trigger with its trace-coupling rationale, and the problem-level "all stories done" trigger that `archived` does not satisfy.
- `docs/decisions/060-problem-rfc-story-framework-with-mandatory-problem-trace-and-unified-problem-ontology.accepted.md` line 310 — the auto-transition triggers (`human-oversight: confirmed`; amend only by supersession per ADR-116).
- Surfaced by the `wr-architect:agent` pre-edit review during the 2026-09-19 P160 iteration, which flagged it as "a real corpus inconsistency worth a ticket — it is not a defect in this proposal". Captured via `/wr-itil:capture-problem` at that iteration's retro (Step 2b, category "Skill-contract violations").
