---
name: wr-risk-scorer:wip
description: Invokable SKILL wrapper around the wr-risk-scorer:wip nudge agent. Delegates to the agent via the Agent tool and returns the agent's structured WIP risk verdict. Internal-use plumbing used by `/wr-risk-scorer:assess-wip` per ADR-015's Confirmation literal phrasing. End users should invoke `/wr-risk-scorer:assess-wip` instead.
allowed-tools: Read, Glob, Bash, Agent
---

# WIP Scoring Skill (Wrapper)

This SKILL is an **invokable wrapper** around the `wr-risk-scorer:wip` agent. It exists so consumer SKILLs can invoke the WIP nudge scorer via the **Skill tool** with `skill: wr-risk-scorer:wip` — matching ADR-015's Confirmation literal phrasing.

**End users**: invoke `/wr-risk-scorer:assess-wip` instead. This wrapper is internal-use plumbing — calling it directly returns raw nudge output without the present-results layer that `/wr-risk-scorer:assess-wip` provides.

## Contract

- **Input** (`$ARGUMENTS`): a self-contained WIP-scoring prompt — typically the edited file path(s) plus a `git diff HEAD --stat` summary per `packages/risk-scorer/agents/wip.md`.
- **Output**: the agent's verbatim report, including the WIP Risk Assessment markdown table, the cumulative pipeline risk picture, and the structured `RISK_VERDICT: CONTINUE | PAUSE | COMMIT` line.

## Steps

### 1. Pass-through to the wip agent

Invoke the wip subagent via the Agent tool with the caller's `$ARGUMENTS` verbatim:

```
subagent_type: wr-risk-scorer:wip
prompt: $ARGUMENTS
```

### 2. Return the agent report verbatim

Return the agent's response to the caller without alteration. Do NOT strip, paraphrase, or post-process the `RISK_VERDICT:`, `RISK_REMEDIATIONS:`, or `RISK_COMMIT_REASON:` blocks — consumer SKILLs parse them directly.

$ARGUMENTS
