---
name: wr-risk-scorer:assess-wip
description: On-demand WIP risk nudge. Scores the current uncommitted diff for pipeline risk. Use during development to catch high-risk changes before committing.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# WIP Risk Assessment Skill

Run a WIP (work-in-progress) risk assessment on demand. Scores the current uncommitted diff — staged and unstaged — for pipeline risk. Use during development to get early feedback before committing.

This skill is **read-only**. It does not commit, push, or modify files.

Unlike `assess-release`, this skill does not pre-satisfy the commit gate. WIP assessment is a development nudge; the pipeline gate is satisfied only by a full `wr-risk-scorer:pipeline` assessment (via `assess-release` or a commit attempt).

## When to use

- After a significant edit: check whether the change is introducing high pipeline risk
- Before `git add`: confirm the uncommitted diff is within appetite
- Exploratory: understand the risk profile of a branch mid-development

## Steps

### 1. Auto-detect context

Run the following to capture the current WIP state:

```bash
# All uncommitted changes (staged + unstaged, non-binary)
git diff HEAD --stat

# Summary of what's changed
git status --short
```

If `git diff HEAD` is empty (clean working tree), report "No uncommitted changes detected" and exit. Do not invoke the subagent with an empty scope.

### 2. Construct the assessment prompt

Build a self-contained prompt for the wip subagent that includes:
- The edited file path(s) (from `git diff HEAD --name-only`)
- A summary of what changed (stat output)

### 3. Delegate to wr-risk-scorer:wip

Invoke the wip subagent via the `Skill` tool:

```
subagent_type: wr-risk-scorer:wip
prompt: <constructed assessment prompt from step 2>
```

Wait for the subagent to complete.

### 4. Present results

Present the WIP risk nudge to the user. The wip subagent provides guidance and recommendations, not a formal gate score.

**Check `RISK_VERDICT` from the subagent output and handle each case distinctly:**

- **`RISK_VERDICT: CONTINUE`**: changes are in-progress and within risk appetite. Highlight the highest-risk files or change patterns; note whether a full pipeline assessment (`assess-release`) is recommended before committing.

- **`RISK_VERDICT: PAUSE`**: risk exceeds appetite. Prominently surface the `RISK_REMEDIATIONS:` block. Explain each remediation clearly. Do NOT suggest committing until remediations are addressed.

- **`RISK_VERDICT: COMMIT`** (ADR-016): the uncommitted diff consists entirely of completed governance work (problem fixes, SKILL.md updates, closed problem transitions) and risk is within appetite. Present a prominent commit-now suggestion:
  > "The uncommitted changes look like completed governance work. Commit now to reduce WIP and feed the pipeline."
  > *Reason: `<RISK_COMMIT_REASON from subagent>`*
  
  Use `AskUserQuestion` to offer: "Commit completed governance work now?" — Yes (user confirms and runs `git commit`) or "Not yet" (user defers).

$ARGUMENTS
