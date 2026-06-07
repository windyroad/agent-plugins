---
name: wr-risk-scorer:external-comms
description: Invokable SKILL wrapper around the wr-risk-scorer:external-comms leak-review agent. Delegates to the agent via the Agent tool and returns the agent's structured EXTERNAL_COMMS_RISK_VERDICT. Internal-use plumbing used by `/wr-risk-scorer:assess-external-comms` per ADR-015's Confirmation literal phrasing. End users should invoke `/wr-risk-scorer:assess-external-comms` instead.
allowed-tools: Read, Glob, Grep, Bash, Agent
---

# External-Comms Leak Review Skill (Wrapper)

This SKILL is an **invokable wrapper** around the `wr-risk-scorer:external-comms` agent. It exists so consumer SKILLs can invoke the leak reviewer via the **Skill tool** with `skill: wr-risk-scorer:external-comms` — matching ADR-015's Confirmation literal phrasing.

**End users**: invoke `/wr-risk-scorer:assess-external-comms` instead. This wrapper is internal-use plumbing — calling it directly returns the raw verdict without the structured AskUserQuestion above-appetite handling (Rewrite / Move to private channel / Override / Cancel) that `/wr-risk-scorer:assess-external-comms` provides.

## Contract

- **Input** (`$ARGUMENTS`): a self-contained leak-review prompt structured per `packages/risk-scorer/agents/external-comms.md` § "What you receive":
  - A leading `SURFACE: <name>` line (one of the canonical surface strings).
  - The draft body wrapped verbatim inside `<draft>...</draft>` markers (the PostToolUse hook derives the marker key from this).
  - The destination when known.
- **Output**: the agent's verbatim verdict — `EXTERNAL_COMMS_RISK_VERDICT: PASS | FAIL` plus, on FAIL, an `EXTERNAL_COMMS_RISK_REASON:` block naming each Confidential Information class and the substrings that triggered it.
- **Side effects**: the `PostToolUse:Agent` hook (`risk-score-mark.sh`) parses the verdict and writes the `external-comms-gate.sh` marker on PASS. The wrapper itself writes no files.

## Steps

### 1. Pass-through to the external-comms agent

Invoke the external-comms subagent via the Agent tool with the caller's `$ARGUMENTS` verbatim. The `SURFACE:` line and `<draft>...</draft>` markers MUST be preserved exactly — the PostToolUse hook depends on the prompt structure for marker-key derivation:

```
subagent_type: wr-risk-scorer:external-comms
prompt: $ARGUMENTS
```

### 2. Return the agent report verbatim

Return the agent's response to the caller without alteration. Do NOT strip, paraphrase, or post-process the `EXTERNAL_COMMS_RISK_VERDICT:` or `EXTERNAL_COMMS_RISK_REASON:` blocks — the hook parses the verdict and consumer SKILLs surface the reason directly.

$ARGUMENTS
