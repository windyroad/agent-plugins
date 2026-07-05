---
status: proposed
rfc-id: afk-loop-goal-anchor-external-evaluator
reported: 2026-07-06
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P390]
adrs: [ADR-094]
jtbd: [JTBD-006]
stories: [STORY-040]
---

# RFC-047: AFK loop `/goal` anchor — external evaluator judges the stop

**Status**: proposed
**Reported**: 2026-07-06
**Problems**: P390
**ADRs**: ADR-094
**JTBD**: JTBD-006

## Summary

Anchor `/wr-itil:work-problems` (and headless single-ticket `/wr-itil:work-problem` runs) with Claude Code's native `/goal` command so a per-turn external evaluator — not the working agent — judges whether the AFK drain is genuinely complete. Decision authority: ADR-094 (AFK loops anchor completion with the native `/goal` external evaluator); this RFC holds no independent decisions per ADR-070 — it is scope + decomposition only.

## Driving problem trace

- **P390** (agent declares ALL_DONE prematurely while actionable backlog remains) — the shipped Step 2.4 Gate (0) self-assessment proved insufficient (reopened 2026-07-05 at user direction): the same agent that invents subjective stops also polices its own `ALL_DONE`. The `/goal` anchor moves the stop decision to an independent evaluator.

## Scope

1. `packages/itil/skills/work-problems/SKILL.md` — new Step 0e "`/goal` loop-anchor": canonical goal condition verbatim; copy-paste-complete headless launch one-liner (`claude -p "/goal <condition> — achieve this by running /wr-itil:work-problems"`); interactive loop-start nudge fallback (proceed regardless, never halt); orchestrator-session-only placement (never iter subprocesses).
2. Step 2.4 Gate (0) amendment — the re-scan classification table MUST be PRINTED in turn output (the evaluator judges only surfaced transcript evidence, ADR-026); one-directional anchor note (a cleared or never-set goal does not discharge Gate (0)). No turn-bound clause (P422 — trust the goal).
3. `packages/itil/skills/work-problem/SKILL.md` — short parallel headless-anchor note for single-ticket runs.
4. Paired promptfoo Tier-A/Tier-B eval cases in `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` per ADR-061 Rule 4 evidence floor.
5. `@windyroad/itil` patch changeset in the same commit per ADR-014.

## Tasks

- [ ] STORY-040 — work-problems Step 0e `/goal` loop-anchor + Gate (0) printed-evidence amendment + singular note + paired evals + changeset (single-story decomposition; the scope is one coordinated SKILL-prose change).

## Commits

(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12)

## Related

- **ADR-094** (`docs/decisions/094-afk-loops-anchor-completion-with-native-goal-evaluator.proposed.md`) — decision authority.
- **P390** (`docs/problems/known-error/390-agent-declares-all-done-prematurely-while-actionable-backlog-remains.md`) — driving problem.
- **JTBD-006** — Progress the Backlog While I'm Away.
- Claude Code `/goal` docs: https://code.claude.com/docs/en/goal


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-040 | STORY-040: AFK loop anchored with the native `/goal` external evaluator | draft |
