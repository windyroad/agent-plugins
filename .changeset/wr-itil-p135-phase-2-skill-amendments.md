---
"@windyroad/itil": patch
---

P135 Phase 2 (Skill amendments — `@windyroad/itil` half) per ADR-044 (Decision-Delegation Contract).

Removes per-action `AskUserQuestion` calls in `work-problems`, `manage-problem`, and `transition-problem` where the framework has already resolved the decision (lazy deferral per Step 2d Ask Hygiene Pass classification). Replaces with silent agent-action + summary surfacing. User correction via the P078 capture-on-correction surface (authentic-correction per ADR-044 category 6).

**`work-problems` Step 5 dispatch (iter prompt body)**: added explicit constraint clause: *"NEVER call `AskUserQuestion` mid-loop in AFK"*. Direction / deviation-approval / one-time-override / silent-framework observations queue at `ITERATION_SUMMARY.outstanding_questions` for loop-end batched presentation per the existing Step 2.5b surfacing routine. Per-iter `AskUserQuestion` calls are sub-contracting framework-resolved decisions back to the user.

**`manage-problem` Step 9d verification close**: replaced per-`.verifying.md` `AskUserQuestion` with close-on-evidence: agent collects in-session evidence per ADR-026 grounding; when concrete and unambiguous, delegates to `/wr-itil:transition-problem <NNN> close` (per ADR-014 commit grain) WITHOUT firing `AskUserQuestion`. Ambiguous-evidence path preserved (left as Verification Pending). Closes are reversible (`/wr-itil:transition-problem <NNN> known-error` flip-back); recovery path documented inline.

**`transition-problem` Step 5 P063 external-root-cause detection**: replaced the 3-option `AskUserQuestion` (invoke-now / defer-and-note / not-actually-upstream) with the silent default behaviour (defer-and-note marker). The marker wording is fixed; recovery is user-initiated (false-positive marker append OR direct `/wr-itil:report-upstream` invocation). AFK and interactive modes use identical behaviour.

**Bats coverage** (Phase 2 R5):
- `packages/itil/skills/manage-problem/test/manage-problem-step-9d-recovery-path.bats` (NEW per R5) — 10 assertions covering close-on-evidence dispatch, ADR-044 / ADR-026 / ADR-022 citations, reversibility affirmation, recovery skill invocation naming, P124 precedent citation, ambiguous-evidence preservation, authentic-correction routing, output-table-with-citation contract.

Refs: P135 (master), ADR-044 (anchor), ADR-014 (commit grain), ADR-022 (lifecycle), ADR-026 (grounding), ADR-013 Rule 1 narrowing precedent, P063 (external-root-cause detection), P078 (authentic-correction surface), P124 (verifying-flip-back precedent), P132 (inverse-P078 enforcement).
