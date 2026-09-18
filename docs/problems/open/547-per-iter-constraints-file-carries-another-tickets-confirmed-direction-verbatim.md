# Problem 547: A per-iter constraints file carried another ticket's confirmed direction verbatim, pinning the wrong fix substance onto the dispatched ticket

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 12 (High) — Impact: 3 (Moderate — the agent is handed a *confirmed-direction* instruction belonging to a different ticket; acting on it produces a wrong governance artefact and a falsely-blocked iteration) × Likelihood: 4 (Likely — observed directly; 1 of the 3 constraint files present in this run carried the leak, and the generator reuses a template across iters) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a; the fix is in the orchestrator's per-iter constraint construction (re-ground each per-ticket block against the named ticket, or drop blocks whose preconditions don't resolve), plus a cheap precondition assertion. cf. P211 (same class, adjacent surface, Effort M).
**WSJF**: 6.0 — (12 × 1.0) / 2 (Open multiplier 1.0; Effort M divisor 2) — derived at capture
**JTBD**: JTBD-006
**Persona**: developer

## Description

An AFK orchestrator's per-iter constraints file carried a verbatim block from another ticket's iter file, pinning the wrong ticket's confirmed direction onto the dispatched ticket.

In `.afk-run-state/iter-constraints/iter-160.md`, item 6 read:

> *"Direction already confirmed (2026-09-19) — read the `## Direction (confirmed 2026-09-19)` section in the ticket before doing anything. The maintainer has pinned the fix substance: narrow the evaluator's fix-evidence set to released/resolution sections and completed task checkboxes, and REMOVE decision-record and skill citations as evidence. Do not re-open that choice."*

That is **P463's** direction (the relevance-close evaluator over-firing on citations read as fix-shipped), not **P160's** (ship a quota-pacing surface). Confirmed three ways:

1. `diff .afk-run-state/iter-constraints/iter-463.md .afk-run-state/iter-constraints/iter-160.md` shows item 6 is **byte-identical** between the two files. The only differences are the `P463`→`P160` substitutions in the retro-commit line and the `ticket_id` line, plus the appended P160-specific item 7. The substitution pass rewrote the ID tokens but not the pinned-direction block.
2. P160 has **no** `## Direction (confirmed ...)` section at all. Across the whole corpus only P506, P463, P509 and P530 carry one — so the instruction "read that section in the ticket" pointed at nothing.
3. Item 6 further asserted *"The ticket's `Blocked by` line still stands"* and directed the agent to RECORD a superseding decision and then HOLD implementation pending ratification. P160's actual `Blocked by` line reads *"(none — the gap is independently buildable)"*, and the same file's item 7 says in terms *"This ticket is NOT blocked."*

**The harm if followed.** An agent taking item 6 literally would have authored an ADR superseding ADR-079 in part, carrying fix substance about a relevance-close evaluator that has nothing whatsoever to do with quota pacing, attributed that substance to the maintainer as *confirmed direction*, and then halted the iteration reporting P160 as blocked-pending-ratification. The output would be a confidently wrong, ratification-shaped governance record plus a lost iteration on a Severity-20 Tier-0 ticket.

**Why this is a class, not a one-off.** The leak was only detectable here because the ticket-specific item 7 contradicted item 6 in the same file. A leak into an iter file that carries **no** ticket-specific override section would be silent, and silence is the normal case — item 7 exists on P160 precisely because that ticket needed extra framing, not as a general guard. The contradiction was luck, not a control.

## Symptoms

- `diff .afk-run-state/iter-constraints/iter-463.md .afk-run-state/iter-constraints/iter-160.md` returns only ID-token substitutions and the appended item 7 — the pinned-direction block in item 6 is unchanged.
- A constraints file instructs the agent to read a `## Direction (confirmed <date>)` section that does not exist in the named ticket.
- Two items in the same constraints file make contradictory claims about whether the ticket is blocked.
- Fix substance in the constraints file names artefacts (an evaluator's fix-evidence set, ADR-079) that appear nowhere in the dispatched ticket.

## Workaround

Agent-side, at iter start: before acting on any constraints item that claims a confirmed direction, resolve its preconditions against the actual ticket — does the cited section exist, do the cited artefacts appear in the ticket, does the blocked-state claim match the ticket's `Blocked by` line? Treat a constraints item whose preconditions don't resolve as a leak and fall through to the ticket's own content. This is what happened in the 2026-09-19 P160 iteration, but it depends on the agent noticing, which is exactly the property that fails silently.

## Impact Assessment

- **Who is affected**: `developer` persona running AFK backlog loops (JTBD-006 — "set an AFK loop and walk away"). The promise breaks when the loop can be handed the wrong ticket's confirmed direction: unattended output stops being trustworthy without per-iter human audit, which is the cost the AFK loop exists to remove.
- **Frequency**: Observed once directly (2026-09-19, P160 iter). 1 of the 3 constraint files present in this run carried the leak. The generator reuses a template across iters, so recurrence tracks the per-iter substitution's coverage, not chance.
- **Severity**: Moderate (3) — no published package or installed plugin is affected, but the failure manufactures governance artefacts that *claim maintainer ratification* for substance the maintainer never pinned on that ticket. That is worse than an ordinary wrong edit, because a `human-oversight`-shaped record is trusted downstream and is expensive to detect after the fact (P348 hollow-marker class).
- **Analytics**: `.afk-run-state/iter-constraints/` at 2026-09-19 held `iter-160.md`, `iter-463.md`, `iter-509.md`; the 160/463 pair shares item 6 verbatim.

## Root Cause Analysis

### Preliminary Hypothesis

The orchestrator composes each iter's constraints file from a shared template plus per-ticket additions, and the per-ticket substitution pass operates on **ID tokens** (`P463` → `P160`, `ticket_id:`) rather than on **semantic blocks**. A block whose body carries another ticket's substance but no ID token to rewrite therefore survives the pass intact and reads as though it were authored for the dispatched ticket. Item 6 carries exactly one ID-free pinned-direction payload, which is why it survived.

Two aggravating properties:

1. **The block asserts its own authority** ("Direction already confirmed", "Do not re-open that choice"), so it is written to defeat exactly the scepticism that would catch it.
2. **There is no precondition assertion.** Nothing checks that the `## Direction (confirmed <date>)` section the item tells the agent to read actually exists in the named ticket — a check that is one grep and would have failed loudly here.

`.afk-run-state/` is gitignored runtime state, so the repair target is the orchestrator's iter-prompt/constraints construction contract in `/wr-itil:work-problems`, not a checked-in generator.

### Investigation Tasks

- [ ] Locate the constraints-file construction site in `/wr-itil:work-problems` and determine whether per-iter composition is template-substitution or per-ticket regeneration.
- [ ] Add a precondition assertion: any constraints item citing a `## <Heading>` in the ticket must resolve that heading in the named ticket file, or the item is dropped with an advisory rather than emitted.
- [ ] Add a cross-ticket-contamination check: no emitted constraints item may name a problem/ADR/RFC/story ID that appears in neither the dispatched ticket nor the item's own ID-substitution set.
- [ ] Assert internal consistency of the blocked-state claim against the ticket's `Blocked by` line before emitting a hold-and-report instruction.
- [ ] Behavioural test: compose constraints for two tickets from the same template where one carries a pinned-direction block; assert the block does not appear in the other's file.
- [ ] Re-check P211's fix (closed 2026-05-15) — it addressed prior-ticket `## Fix Strategy` leaking into the dispatch *prompt*; determine whether its remedy can extend to the constraints *file* surface or whether the two construction paths diverged.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P211 (closed — same class at the adjacent surface); P348 (iter subprocesses writing oversight markers without a confirmation event — this defect manufactures the upstream "confirmed direction" such a marker would record); P175 (agent over-narrows scope-pin words and halts the loop on an agent-inferred scope — sibling failure where iter framing text drives a wrong halt).

## Related

- **P211** (`docs/problems/closed/211-work-problems-orchestrator-carries-prior-ticket-fix-strategy-text-into-iter-dispatch-without-re-grounding.md`) — **the direct precursor**. Closed 2026-05-15, reported inbound from downstream bbstats P194. Same class: prior-ticket text leaking into a later iter's dispatch without re-grounding. Different surface: P211 covered the in-turn dispatch prompt built from `## Fix Strategy`; this ticket covers the pre-generated per-iter constraints **file**, and the payload is a *pinned confirmed direction* rather than a fix-strategy hint — a materially higher-authority claim. If the two construction paths share a helper, the fix likely belongs on one surface; that is the first investigation task.
- Captured via `/wr-itil:capture-problem` during the 2026-09-19 P160 iteration retro (Step 2b pipeline-instability scan, category "Skill-contract violations").
- Hang-off pre-filter at capture surfaced >5 candidates on the `ADR-079` signal alone (P045, P544, P214, P315, P346, P375, P385, P386, P433, P519), so the `wr-itil:hang-off-check` subagent dispatch was **skipped per the capture-problem candidate-cap short-circuit** and the candidate list is recorded here for review-time re-evaluation by `/wr-itil:review-problems`. Note that the `ADR-079` signal is itself an artefact of the leak — ADR-079 appeared in this description only because the leaked item 6 named it — so those candidates are expected to be weak matches. P211 (found via the title-only grep at sub-step 2a) is the real anchor.
