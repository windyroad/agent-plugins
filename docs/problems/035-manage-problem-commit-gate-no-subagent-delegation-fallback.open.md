# Problem 035: manage-problem commit gate has no fallback when subagent delegation is unavailable

**Status**: Open
**Reported**: 2026-04-17
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3)

## Description

The `wr-itil:manage-problem` skill's commit step (step 9e and step 11) hardcodes a single commit-gate path: "Delegate to `wr-risk-scorer:pipeline` (subagent_type) to assess the staged changes and create a bypass marker". When the current tool set does not expose the `wr-risk-scorer:pipeline` subagent-type (e.g., when `manage-problem` is itself running inside a spawned subagent), there is no documented fallback and the commit is silently skipped — leaving completed work uncommitted.

This was observed in a real AFK run on 2026-04-17: the subagent completed the P026 fix (sync-install-utils + CI drift check + bats tests), staged 6 files, but was unable to commit because the `Skill` tool rejected `wr-risk-scorer:pipeline` as "Unknown skill" and the subagent's tool set did not include a way to invoke the subagent-type. Per ADR-014 and ADR-013 non-interactive fail-safe rules, the subagent skipped the commit. All work was left staged with no path to completion without the user's manual intervention.

The skill should document a fallback — e.g., invoke the `/wr-risk-scorer:assess-release` skill (which is a skill, not a subagent-type, and therefore available anywhere the Skill tool works) — so the commit gate can be satisfied from any invocation context.

## Symptoms

- Subagents running `manage-problem work` complete the fix but cannot commit
- Work is staged but not committed at the end of an iteration
- No clear signal to the user that the commit gate failed for a delegation reason (vs. a risk-above-appetite reason)
- AFK loops that rely on `manage-problem` to self-commit accumulate uncommitted work across iterations

## Workaround

The user invokes `/wr-risk-scorer:assess-release` from the main session to generate the bypass marker, then runs `git commit` with the appropriate message.

## Impact Assessment

- **Who is affected**: Solo developers running AFK loops (JTBD-006); any agent-initiated workflow that delegates `manage-problem` to a subagent
- **Frequency**: Every AFK iteration; every subagent-mediated manage-problem invocation
- **Severity**: Medium — work is preserved (staged), but the autonomous commit promise of ADR-014 is broken
- **Analytics**: N/A

## Root Cause Analysis

### Investigation Tasks

- [ ] Confirm which subagent tool sets do not include `wr-risk-scorer:pipeline` as an allowed subagent-type
- [ ] Determine whether the gap should be fixed by (a) adding a fallback path in `manage-problem` SKILL.md, (b) expanding subagent tool sets, or (c) extending ADR-014 to cover the delegation-unavailable case
- [ ] Check whether `/wr-risk-scorer:assess-release` is semantically equivalent to the `wr-risk-scorer:pipeline` subagent-type for gate-satisfaction purposes
- [ ] Create a reproduction test (invoke manage-problem work from a general-purpose subagent, assert commit either lands or produces a clear "gate unavailable" signal)
- [ ] Create INVEST story for permanent fix

## Related

- [JTBD-006](../jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md) — AFK backlog progression (this defect prevents the "git commits happen automatically when risk is within appetite" outcome)
- [ADR-013](../decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — non-interactive fail-safe rule
- [ADR-014](../decisions/014-governance-skills-commit-their-own-work.proposed.md) — commit obligation; the fail-safe matrix does not currently cover delegation-unavailable
- [P036](036-work-problems-commit-gate-subagent-instructions.open.md) — sibling defect in the orchestrator skill
- [packages/itil/skills/manage-problem/SKILL.md](../../packages/itil/skills/manage-problem/SKILL.md) — step 9e and step 11 hardcode the pipeline delegation
