# Problem 362: Unconditional update-upstream Skill dispatch pays full SKILL.md context load for the common no-op case

**Status**: Verification Pending
**Reported**: 2026-06-11
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: S (actual — two byte-equivalent SKILL prose edits + one ADR amendment)
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

**Root cause**: The P080 bidirectional-lifecycle-update contract (ADR-024 2026-06-09 amendment) specified the trigger as **unconditional** — fire `/wr-itil:update-upstream <NNN>` via the Skill tool on every transition, relying on the sibling skill's Step 1 no-op exit to absorb the common no-`## Reported Upstream`-section case. That design optimised for trigger-side simplicity but mislocated the cost: the Skill-tool dispatch loads the full sibling SKILL.md (~14 KB, per ADR-054's measurement table) into the *calling* agent's context before the sibling can discover there is nothing to update. The no-op is cheap on the sibling side and expensive on the caller side; every transition-bearing iteration paid it.

**Fix**: Relocate the common-case short-circuit to a caller-side mechanical pre-check at both lockstep trigger sites (ADR-010 P093 copy-not-move pair): `grep -q '^## Reported Upstream' <ticket-file>` BEFORE the Skill dispatch; skip the dispatch with a one-line log when absent. The grep IS the trigger — observable behaviour is unchanged (an upstream comment posts iff the section is present) while the ~14 KB load is eliminated for the common no-op case. The sibling retains its own Step 1 no-op exit as defence-in-depth (a stale-grep miss degrades to the old no-op, never to a wrong post). Recorded as an ADR-024 mechanism-refinement amendment (2026-06-16, P362) citing ADR-054 (runtime-budget policy) with ADR-038 (progressive disclosure) as the ancestor principle.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — Effort confirmed S (two prose edits + one amendment); Priority unchanged at 3 (re-rate formally at next review)
- [x] Investigate root cause — caller-side context load mislocated by the unconditional-trigger design (above)
- [x] Create reproduction test — paired promptfoo Tier-A behavioural eval covering the changed P080 trigger prose at both sites: a new case in `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` (Step 7) and a new `packages/itil/skills/transition-problem/eval/promptfooconfig.yaml` + runner (Step 7b — first eval slice for that skill). Each asserts the agent describes the `grep '^## Reported Upstream'` pre-check BEFORE the `/wr-itil:update-upstream` dispatch and the skip-the-dispatch outcome on the no-section case, and NOT an unconditional-dispatch-first shape. Discharges the R009 prose-surface floor for the P080 trigger paragraph (the pre-existing eval cases covered only K→V Release-vehicle / conditional-deferral prose) per ADR-075 / ADR-052. A structural grep on SKILL.md prose would be a wasteful non-test per P081 — the eval is behavioural (exercises the agent under the SKILL prompt).

## Fix Released

- **2026-06-16 (this session, AFK work-problems iter 33)** — caller-side grep pre-check added at `packages/itil/skills/manage-problem/SKILL.md` Step 7 P080 block and `packages/itil/skills/transition-problem/SKILL.md` Step 7b (byte-equivalent lockstep reword); ADR-024 mechanism-refinement amendment recorded; `@windyroad/itil` patch changeset added. Committed under ADR-014 single-commit grain. **Pending**: release verification (no push/release in AFK) — verify the cache-installed @windyroad/itil carries the pre-check, then close.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Hang-off-check verdict (P346 Phase 3)**: PROCEED_NEW. Single pre-filter candidate P172 (skill-contract interactive-vs-AFK commit-gating anti-pattern) shares only an incidental `update-upstream` keyword — P172 names that surface solely in its "do NOT touch" exclusion list; its scope is mode-gated commit carve-outs vs ADR-014, a different observable with a different fix locus. Absorbing this capture would dilute P172's single-purpose anchor with an unrelated context-budget concern.
- P080 (the bidirectional update-upstream contract this dispatch implements) — the fix preserves P080's unconditional-trigger semantics; only the dispatch mechanics change.
