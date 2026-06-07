# Problem 212: work-problems iteration boundary leaves run-retro BRIEFING.md edits uncommitted

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

Iteration retros inside `/wr-itil:work-problems` write to `docs/BRIEFING.md` but cannot commit per ADR-014 (run-retro is out of scope for committing its own work). The orchestrator therefore has to add separate "BRIEFING hand-off" commits between iterations to keep Step 6.75 dirty-state classification clean. Each hand-off commit triggers another `wr-risk-scorer:pipeline` subagent invocation, doubling the gate overhead per iter.

## Workaround

Accept the doubled commit/gate overhead per iter. Tolerable for short loops; meaningful friction for long AFK runs.

## Impact Assessment

- **Severity**: Moderate — friction; not a correctness issue.

## Root Cause Analysis

Three contributing facts compose the symptom:

1. **ADR-014 Scope explicitly excludes run-retro** ("Out of scope for now (to be addressed when those skills are worked)" — Scope section lists `packages/retrospective/skills/run-retro/SKILL.md`). run-retro's Step 3 EDITS `docs/BRIEFING.md` / `docs/briefing/*.md` but its own SKILL.md confirms "run-retro does not commit its own work" (Step 4 ownership boundary line 475, Step 2b line 143).
2. **work-problems Step 5 retro-on-exit prose carried a factually-wrong cite**: the clause asserted "run-retro commits its own work per ADR-014" — contradicted by ADR-014's own Scope section AND run-retro's own SKILL.md. The false assertion masked the actual contract gap.
3. **Step 6.75 absorbed the BRIEFING refresh as dirty-for-known-reason hand-off**: the orchestrator main turn then added a `chore(briefing)` commit AT ORCHESTRATOR-MAIN-TURN COST, invoking `wr-risk-scorer:pipeline` a second time per iter (once for the ticket commit, once for the hand-off).

## Fix Strategy

**Option N (chosen) — iter-owned BRIEFING commit, SKILL-prose-only within existing ADR-014 scope.**

Modify `packages/itil/skills/work-problems/SKILL.md` ONLY:

1. **Step 5 retro-on-exit clause #4** — replace the false "run-retro commits its own work per ADR-014" assertion with the correct contract: run-retro is out-of-scope per ADR-014; the iter (NOT run-retro, NOT the orchestrator main turn) commits run-retro's BRIEFING edits. Concrete sequence after retro completes: check `git status --porcelain docs/BRIEFING.md docs/briefing/`; if non-empty, stage → delegate to `wr-risk-scorer:pipeline` → commit as `chore(briefing): refresh from iter retro (P<NNN>)`. The commit-message format matches ADR-014's existing chore-class precedents (`chore(problems): reconcile README ...` + `chore(problems): check upstream responses`).
2. **Step 6.75 dirty-state classification table** — amend so dirty `docs/BRIEFING.md` / `docs/briefing/*.md` at iter exit is now a bug class (the iter's retro-on-exit clause failed) rather than an expected hand-off the orchestrator absorbs.

**Effect.** Same number of commits per iter (ticket commit + `chore(briefing)` commit when retro touches BRIEFING) — the audit trail is preserved. The second `wr-risk-scorer:pipeline` invocation MOVES from expensive orchestrator-main-turn context to cheaper iter-subprocess context, eliminating the per-iter main-turn cost that the ticket flagged. The orchestrator's Step 6.75 sees clean-tree-at-iter-exit and proceeds without a hand-off commit.

**ADR scope.** Architect verdict PASS — no new or amended ADR required. ADR-014 governs WHICH SKILLS auto-commit; it does NOT prohibit an orchestrator from committing on behalf of a sub-skill it invoked. The work-problems iter committing run-retro's BRIEFING output preserves ADR-014's Scope (run-retro stays out-of-scope) while addressing the orchestrator-side hand-off cost. JTBD verdict PASS — strengthens JTBD-006 (audit trail preserved; main-turn cost reduces; longer AFK loops more sustainable).

**Rejected alternatives.**

- *Option A — amend ADR-014's Scope to bring run-retro in-scope.* Task constraints explicitly classify "amending ADR-014's scope" as genuinely-new-ADR class — out of scope for this iter per the AFK governance contract (NEW/AMENDED ADRs require user ratification first).
- *Option B — combine BRIEFING refresh into manage-problem's Step 11 commit (single commit, single scoring call).* Requires run-retro to fire BEFORE manage-problem's Step 11, which loses the "retro has access to the iteration's rich tool-call history" benefit the current ordering depends on. Also requires touching manage-problem to stage BRIEFING — broader surface change.
- *Option C — keep the orchestrator-side hand-off (status quo).* The workaround the ticket already documented. Does not address the per-iter main-turn cost.

### Investigation Tasks

- [x] Architect call — PASS (no new ADR, work-problems-orchestrator concern, commit format matches ADR-014 chore-class precedent)
- [x] JTBD call — PASS (JTBD-006 preserved + strengthened)
- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (Verification Pending will surface the re-rate prompt)
- [ ] Behavioural test asserting iter N's commit OR orchestrator commit carries the BRIEFING refresh in the same logical unit — deferred to P012 skill testing harness per ADR-014 § Confirmation precedent (structural grep tests on SKILL.md are anti-pattern per ADR-051 / feedback_behavioural_tests; the behavioural assertion needs the skill-invocation harness which is P012-tracked).

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/83
- **Pipeline classification**: JTBD-aligned (JTBD-006); safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil (work-problems SKILL.md prose only). run-retro SKILL.md unchanged.
- **ADR-014**: § Scope (line 96-99) — run-retro listed as out-of-scope; § commit-message convention table — `chore(<scope>):` precedent for mechanical-pass commits writing derived content.

## Fix Released

_Pending — fix lands in `@windyroad/itil` patch via Step 6.5 release-cadence drain at orchestrator stop. Verification: next AFK loop with a retro-touching-BRIEFING iter must (a) emit a `chore(briefing): refresh from iter retro (P<NNN>)` commit inside the iter subprocess, AND (b) the orchestrator's Step 6.75 must observe clean tree at iter exit (no main-turn hand-off commit). Recovery path if rollback needed: `/wr-itil:transition-problem 212 known-error` after reverting the iter commit._
