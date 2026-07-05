---
status: draft
story-id: afk-loop-anchored-with-native-goal-external-evaluator
reported: 2026-07-06
decision-makers: [Tom Howard]
problems: [P390]
jtbd: [JTBD-006]
rfcs: [RFC-047]
story-maps: []
estimated-effort: M
---

# STORY-039: AFK loop anchored with the native `/goal` external evaluator

**Status**: draft
**Reported**: 2026-07-06
**Problems**: P390
**JTBD**: JTBD-006
**RFCs**: RFC-047
**Story Maps**: (none — populate at accepted transition per I8)
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to trust that an AFK backlog drain only stops when the backlog is genuinely empty, as a developer running `/wr-itil:work-problems` while away, I want the loop anchored with Claude Code's native `/goal` external evaluator — a fresh model judges the completion condition against printed transcript evidence each turn, so the working agent can no longer rationalise a premature `ALL_DONE` (the P390 failure the shipped Gate (0) self-assessment could not prevent).

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] `packages/itil/skills/work-problems/SKILL.md` Step 0e carries the canonical `/goal` condition verbatim plus a copy-paste-complete headless launch one-liner (`claude -p "/goal <condition>"` carrying the skill invocation).
- [ ] Step 0e nudges-and-proceeds when the loop is unanchored (never halts) and places the goal on the orchestrator session only — never on `claude -p` iter subprocesses.
- [ ] Step 2.4 Gate (0) requires the re-scan classification table be PRINTED in turn output (evaluator evidence per ADR-026), and states that a turn-bound goal-clear does not discharge Gate (0).
- [ ] `packages/itil/skills/work-problem/SKILL.md` documents the headless anchor shape for single-ticket runs.
- [ ] Paired promptfoo Tier-A/Tier-B eval cases in `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` are GREEN per ADR-061 Rule 4.
- [ ] `@windyroad/itil` patch changeset lands in the same commit per ADR-014.

## Driving problem trace (required — I6 invariant)

- **P390** (agent declares ALL_DONE prematurely while actionable backlog remains) — the orchestrator invented a subjective stop while a dispatchable Tier-2 backlog remained; the Gate (0) self-assessment fix (shipped 0.55.0) was reopened 2026-07-05 as structurally insufficient (same actor decides "should I stop" and "is stopping justified"). This story moves the stop judgement to an independent per-turn evaluator.

## JTBD trace (required — I9 invariant)

- **JTBD-006** (Progress the Backlog While I'm Away) — a trustworthy AFK drain must not stop early; premature `ALL_DONE` forces the user to babysit and re-prompt, which is the exact outcome the job exists to remove.

## Implementation notes (optional)

Decision authority: ADR-094 (`docs/decisions/094-afk-loops-anchor-completion-with-native-goal-evaluator.proposed.md`). Empirical probes 2026-07-06 (Claude Code v2.1.201): no `--goal` CLI flag; Skill tool rejects `/goal` ("goal is a UI command, not a skill"); headless `claude -p "/goal"` recognized. Anchor is therefore launch-set (headless) or user-set via loop-start nudge (interactive).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **RFC-047** (`docs/rfcs/RFC-047-afk-loop-goal-anchor-external-evaluator.proposed.md`) — parent RFC; this story is its single-story decomposition.
- **ADR-094** — decision authority.
- Claude Code `/goal` docs: https://code.claude.com/docs/en/goal
