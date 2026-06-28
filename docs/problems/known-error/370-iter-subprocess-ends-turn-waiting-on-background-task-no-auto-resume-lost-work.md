# Problem 370: Iter subprocess ends its turn waiting on a backgrounded task and never resumes — `claude -p` has no auto-resume; commit-bearing work is lost

**Status**: Known Error
**Reported**: 2026-06-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next `/wr-itil:review-problems`)
**Origin**: internal
**Effort**: M (deferred — re-rate at next `/wr-itil:review-problems`)
**JTBD**: JTBD-006
**Persona**: developer

## Description

Captured via `/wr-itil:capture-problem` 2026-06-17 (drain of the outstanding-questions queue; sibling-class to the ScheduleWakeup ban and the bash-polling antipatterns).

**Witnessed mechanism**: an iter subprocess dispatched by `/wr-itil:work-problems` (via `claude -p`) launched a backgrounded task during its turn, ended its turn while still waiting on that background completion, and **never resumed**. `claude -p` is a single-shot CLI invocation — it has no auto-resume affordance equivalent to the interactive Claude Code session's notification-driven re-entry. The iter therefore exited at turn-end with the background task incomplete and its own work staged but uncommitted.

**Witnessing evidence (iter 11, prior AFK loop)**:
- Cost: **$8.02** for the iter subprocess
- Wall-clock: **17 minutes**
- Output: **8 staged files** + **11 GREEN bats tests**
- Commit produced: **NONE** (the iter exited at turn-end before reaching the commit step)
- Recovery: the work was salvaged via the orchestrator main-turn (carry-over pattern from P261-style salvage)

**Class generalisation**: this is the "turn-end-mid-background" failure mode. Sibling-class to:
- **P083 (closed) — ScheduleWakeup ban**: schedule-and-wait patterns introduce the same "turn ends before completion" hazard; P083 closed by removing the pattern from agent prose.
- **P146 (closed) — bash polling antipatterns**: polling loops inside the agent turn share the same "must-not-leak-into-turn-end" constraint.
- **P232 (verifying) — bash polling antipattern recurrence**: the polling-class continues to bite even after P146; this ticket is a different surface (backgrounded task without polling) but the same root class (turn-end-leak).

The common root cause is: `claude -p` IS the agent's whole session — its turn boundary is also its process boundary, so any unfinished work at turn-end is lost. The interactive Claude Code session has notification re-entry that masks this; the AFK iter subprocess does not.

## Symptoms

- Iter subprocess writes files, runs tests, reaches a backgrounded task launch point (e.g. `run_in_background: true` on an Agent or Bash invocation), waits for completion, then exits at turn-end without making a commit.
- Cost meter shows wall-clock + tokens consumed; no committed output on the branch.
- `.afk-run-state/iter*.json` for the affected iter shows non-empty `staged_files` array but no `commit_sha` (or a `commit_sha: null` sentinel).
- The orchestrator main turn observes the iter exit with no `ITERATION_SUMMARY` block (or an `ITERATION_SUMMARY` that names staged-but-uncommitted work).

## Workaround

- Orchestrator main-turn salvages the iter's staged files via the P261-style carve-out (same workaround as the stream-timeout salvage path — both result in staged-but-uncommitted output the main turn must complete).
- Iter-side: avoid launching backgrounded tasks within `claude -p` subprocesses. Use foreground-synchronous invocation (the Agent tool without `run_in_background: true`). Trade-off: foreground-synchronous Agent calls block the iter turn but DO commit; background calls risk the turn-end leak.

## Impact Assessment

- **Who is affected**: every AFK `/wr-itil:work-problems` iter that launches a backgrounded task. Specific witnessed instance: iter 11 of a prior loop.
- **Frequency**: depends on the iter's tool-use pattern. Foreground-only iters are unaffected; iters that fan out background subagents or background Bash are at risk.
- **Severity**: HIGH per instance ($8.02 / 17 min lost; recovery requires orchestrator salvage). LOW frequency historically (one witnessed in iter 11) but the class is a real lurking hazard for any iter that adopts background fan-out.
- **Analytics**: 1 witnessed instance (iter 11); class-history covers P083 / P146 / P232.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next `/wr-itil:review-problems`.
- [ ] Survey: which iters across the `.afk-run-state/iter*.json` corpus show non-empty staged work but no commit_sha? Count + characterise.
- [x] Document the prohibition: amend `/wr-itil:work-problem(s)` SKILL.md iter-prompt-body prose to explicitly forbid `run_in_background: true` (and equivalent background-launch tool surfaces) inside iter dispatch contexts. **DONE 2026-06-28** — Step 5 Constraints clause added to `packages/itil/skills/work-problems/SKILL.md`, scoped to the cross-turn / turn-end-survivor shape (carves out the P146/P232-sanctioned intra-turn `run_in_background` + `BashOutput`-poll-then-`wait` idiom per architect coherence review). Singular `work-problem/SKILL.md` is OUT of scope — it has no iter-prompt-body (selection-and-delegate execution unit, not the `claude -p` prompt builder); the hazard exists only on the plural orchestrator's `claude -p` dispatch path. See RFC-034 for the supersession of this ticket's over-broad locus list.
- [x] Behavioural test: ~~bats fixture~~ promptfoo eval that exercises an iter-shape and asserts no turn-end-survivor background-fan-out tool-call appears in the response. **DONE 2026-06-28** — case added to `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` (`@problem P370`), GREEN. NOT a structural bats fixture: ADR-052's 2026-06-09 amendment deleted the structural escape hatch ("not permitted under any justification"), so a SKILL-prose grep fixture would be a net-new violation. Behavioural promptfoo per ADR-052/ADR-075; also discharges the R009 in-source floor for the prose change.
- [ ] **Deferred follow-on** — Recovery path: codify the orchestrator main-turn salvage protocol (carry-over from P261) into a SKILL.md sub-step so the salvage is mechanical rather than ad-hoc. Tracked in RFC-034 Tasks as a separable, heavier concern; out of scope for the prohibition slice.
- [ ] Cross-reference P083 / P146 / P232 in the prohibition prose so the sibling-class trace is visible.

## Dependencies

- **Blocks**: AFK iter trust on iters that use background fan-out — the work-loss hazard erodes JTBD-006's "decisions resolved via safe defaults" outcome.
- **Blocked by**: (none)
- **Composes with**: P083 (closed — ScheduleWakeup ban); P146 (closed — bash polling antipattern); P232 (verifying — polling antipattern recurrence); P305 (Known Error — parallel iter dispatch race that ratified Option B per-iter git worktree on 2026-06-17 — the worktree mechanism does NOT close this class because the turn-end-leak is INDEPENDENT of working-tree isolation).

## Related

(captured via `/wr-itil:capture-problem` 2026-06-17 during the outstanding-questions drain; trace = developer + JTBD-006 per the queued question's ratified option)

- **P083** (closed) — ScheduleWakeup ban; sibling-class precedent.
- **P146** (closed) — bash polling antipattern; sibling-class precedent.
- **P232** (verifying) — bash polling antipattern recurrence; sibling-class live.
- **P305** (Known Error) — parallel iter dispatch race; same iter-class but different mechanism. P305's worktree fix does NOT close P370.
- **P261** — orchestrator main-turn salvage carve-out (the workaround precedent this ticket's recovery path inherits).
- `packages/itil/skills/work-problems/SKILL.md` — amendment locus for the prohibition prose.
- `packages/itil/skills/work-problem/SKILL.md` — singular sibling; same amendment.
- `.afk-run-state/iter*.json` — analytics corpus for the survey investigation task.

## Fix Strategy

(Step 4b Stage 2 — proposed fix strategy.)

**Option 3 — Other codification shape.**

**Shape**: SKILL.md prose amendment (prohibition + recovery protocol) + behavioural test (bats fixture + promptfoo eval).

**Suggested name / locus**:
- Prohibition prose: `packages/itil/skills/work-problem/SKILL.md` + `packages/itil/skills/work-problems/SKILL.md` iter-prompt-body section — "DO NOT launch backgrounded tasks (`run_in_background: true`, etc.) inside iter dispatch contexts. The iter's turn boundary is its process boundary; background tasks that outlive the turn lose their work. Use foreground-synchronous Agent/Bash invocation instead."
- Recovery protocol: orchestrator main-turn salvage sub-step (P261-style carve-out, parametrised to handle both stream-timeout and turn-end-mid-background shapes).
- Behavioural test: `packages/itil/skills/work-problem/test/work-problem-no-background-fanout-in-iter.bats` + a promptfoo eval that exercises an iter-shape.

**Routing target**: when ratified for build, capture an RFC per ADR-060 tracing this ticket + the SKILL loci + the test fixture. Implementation is foreground-lightweight (prose + bats) — likely a single iter once the RFC scope lands.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-034 | proposed | Forbid backgrounded-task launches inside `claude -p` AFK iter dispatch contexts |
