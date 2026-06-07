---
name: wr-risk-scorer:pipeline
description: Invokable SKILL wrapper around the wr-risk-scorer:pipeline scoring agent. Delegates to the agent via the Agent tool and returns the agent's structured RISK_SCORES output. Internal-use plumbing used by `/wr-risk-scorer:assess-release` and any other consumer SKILL that needs Skill-tool-shaped invocation of the pipeline scorer per ADR-015's Confirmation literal phrasing. End users should invoke `/wr-risk-scorer:assess-release` instead.
allowed-tools: Read, Glob, Bash, Agent
---

# Pipeline Scoring Skill (Wrapper)

This SKILL is an **invokable wrapper** around the `wr-risk-scorer:pipeline` agent. It exists so consumer SKILLs can invoke the pipeline scorer via the **Skill tool** with `skill: wr-risk-scorer:pipeline` — matching ADR-015's Confirmation literal phrasing.

**End users**: invoke `/wr-risk-scorer:assess-release` instead. This wrapper is internal-use plumbing — calling it directly returns raw scoring output without the gate-satisfaction wrap-up, AskUserQuestion above-appetite handling, or release-context resolution that `/wr-risk-scorer:assess-release` provides.

## Contract

- **Input** (`$ARGUMENTS`): a self-contained scoring prompt with pipeline state context. Caller assembles UNCOMMITTED / UNPUSHED / UNRELEASED sections per `packages/risk-scorer/agents/pipeline.md` § Pipeline State.
- **Output**: the agent's verbatim report, including the structured `RISK_SCORES: commit=N push=N release=N` block, optional `RISK_BYPASS:` line, optional `RISK_REMEDIATIONS:` block, optional `RISK_REGISTER_HINT:` block, and optional `CATALOG_HIT_RATE:` line.
- **Side effects**: the `PostToolUse:Agent` hook (`risk-score-mark.sh`) reads the agent's output downstream of this wrapper and writes the bypass marker files to `${TMPDIR}/claude-risk-${SESSION_ID}/`. The wrapper itself writes no files.

## Steps

### 1. Pass-through to the pipeline agent

Invoke the pipeline subagent via the Agent tool with the caller's `$ARGUMENTS` verbatim:

```
subagent_type: wr-risk-scorer:pipeline
prompt: $ARGUMENTS
```

### 2. Return the agent report verbatim

Return the agent's response to the caller without alteration. Do NOT strip, paraphrase, or post-process the structured output blocks (`RISK_SCORES:`, `RISK_BYPASS:`, `RISK_REMEDIATIONS:`, `RISK_REGISTER_HINT:`, `CATALOG_HIT_RATE:`). The PostToolUse hook depends on the exact byte sequence to parse.

$ARGUMENTS
