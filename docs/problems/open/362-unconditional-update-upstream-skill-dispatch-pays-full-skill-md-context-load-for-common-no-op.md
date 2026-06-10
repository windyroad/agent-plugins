# Problem 362: Unconditional update-upstream Skill dispatch pays full SKILL.md context load for the common no-op case

**Status**: Open
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001, JTBD-006
**Persona**: developer

## Description

manage-problem Step 7 P080 block and transition-problem Step 7b fire `/wr-itil:update-upstream` unconditionally via the Skill tool on EVERY status transition, with the sibling skill's Step 1 no-op exit absorbing the common no-`## Reported Upstream`-section case. The no-op is cheap on the skill side but expensive on the caller side: each Skill-tool dispatch loads the full update-upstream SKILL.md (~14 KB) into the calling agent's context just to discover there is nothing to update. Observed 2026-06-11 AFK work-problems iter 1: P211's K→V transition dispatched update-upstream, which no-op-exited because the ticket has only a `**Reported Upstream**` bullet in `## Related` (inbound issue #97, owned by the ADR-062 pipeline) and no `## Reported Upstream` section. Every transition-bearing AFK iter pays this context cost. Likely fix: add a one-line mechanical pre-check at both call sites (manage-problem Step 7 P080 block + transition-problem Step 7b) — `grep -q '^## Reported Upstream' <ticket>` before the Skill dispatch; skip dispatch with a one-line log when absent. Preserves the unconditional-trigger semantics (the grep IS the trigger; the dispatch fires whenever the section exists) while eliminating the ~14 KB context load for the common case. ADR-038 progressive-disclosure alignment.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check verdict (P346 Phase 3)**: PROCEED_NEW. Single pre-filter candidate P172 (skill-contract interactive-vs-AFK commit-gating anti-pattern) shares only an incidental `update-upstream` keyword — P172 names that surface solely in its "do NOT touch" exclusion list; its scope is mode-gated commit carve-outs vs ADR-014, a different observable with a different fix locus. Absorbing this capture would dilute P172's single-purpose anchor with an unrelated context-budget concern.
- P080 (the bidirectional update-upstream contract this dispatch implements) — the fix preserves P080's unconditional-trigger semantics; only the dispatch mechanics change.
