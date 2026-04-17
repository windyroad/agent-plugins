# Problem 036: work-problems skill does not pass commit-gate fallback instructions to spawned subagents

**Status**: Open
**Reported**: 2026-04-17
**Priority**: 6 (Med) — Impact: Moderate (3) x Likelihood: Possible (2)

## Description

The `wr-itil:work-problems` AFK orchestrator spawns subagents to run one iteration of `manage-problem work` per loop. When the spawned subagent hits the commit gate and the `wr-risk-scorer:pipeline` subagent-type is not available in its tool set (see P035), the subagent correctly fail-safes and skips the commit. But the orchestrator has no mechanism to recover — the next iteration spawns a fresh subagent that has no knowledge of the uncommitted work from the previous iteration.

The orchestrator should either:
(a) pass explicit fallback instructions to each spawned subagent ("if pipeline subagent-type unavailable, invoke `/wr-risk-scorer:assess-release` skill instead before committing"), or
(b) detect uncommitted work between iterations and either invoke the assess-release skill at the orchestrator level or stop the loop with a clear "manual commit required" signal.

Without this, an AFK loop can complete N iterations of real work and leave N fixes uncommitted with no audit trail of what was done or why commits didn't land.

## Symptoms

- Subagent completes a problem fix and stages files
- Commit is skipped because of P035 (no fallback)
- Orchestrator loops to next iteration without detecting the uncommitted state
- Over multiple iterations, staged changes accumulate; on user return they face a large unstructured diff
- The "Completed" table in the final summary claims commits landed that actually didn't

## Workaround

Run AFK loops for short periods (1-2 iterations) and manually verify commits landed before leaving again.

## Impact Assessment

- **Who is affected**: Solo developers using `wr-itil:work-problems` for AFK backlog progression (JTBD-006)
- **Frequency**: Every AFK loop that encounters P035 — currently every loop, since P035 is not yet fixed
- **Severity**: Medium — depends on P035 being unfixed; resolves naturally if P035 is fixed at the manage-problem level
- **Analytics**: N/A

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide whether fix should be at the orchestrator level or purely rely on P035's fix at the delegated skill level
- [ ] If orchestrator-level: design the inter-iteration uncommitted-work detection (git status parse, or explicit signal from subagent)
- [ ] If subagent-level: add explicit fallback instructions to the Agent prompt the orchestrator constructs
- [ ] Create a reproduction test (run work-problems, observe whether uncommitted work between iterations triggers a recovery path or a stop)
- [ ] Create INVEST story for permanent fix

## Related

- [JTBD-006](../jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md) — AFK backlog progression
- [P035](035-manage-problem-commit-gate-no-subagent-delegation-fallback.open.md) — the underlying gap this problem surfaces in the orchestrator
- [packages/itil/skills/work-problems/SKILL.md](../../packages/itil/skills/work-problems/SKILL.md) — the orchestrator skill
- [ADR-014](../decisions/014-governance-skills-commit-their-own-work.proposed.md) — commit obligation
