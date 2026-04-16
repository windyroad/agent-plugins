---
name: wr-jtbd:review-jobs
description: On-demand JTBD alignment review. Checks staged changes and recent commits against documented persona jobs in docs/jtbd/. Use before a release or when adding new features.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# JTBD Alignment Review Skill

Run a Jobs To Be Done alignment review on demand — outside the pre-tool-use hook gate. Reviews staged changes and recent commits against the documented persona jobs in `docs/jtbd/`.

This skill is **read-only**. It does not commit, push, or modify files.

## When to use

- Pre-flight before a release or client handover: confirm delivered features trace to documented persona needs
- When adding new features: verify the feature serves a documented JTBD before building
- After a significant capability change: check whether existing jobs are still served
- Any time the hook gate is not convenient: planning mode, spike work, design review

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for an explicit review scope (e.g., "review the new skill I just wrote", "check persona alignment for the release", "does this feature serve a documented job?"). If a scope is provided, use it. If empty, proceed to auto-detection.

### 2. Auto-detect context

Run the following to establish what needs reviewing:

```bash
# Staged changes
git diff --cached --stat
git diff --cached --name-only

# Recent commits not yet pushed
git log origin/$(git rev-parse --abbrev-ref HEAD)..HEAD --oneline 2>/dev/null || git log HEAD -5 --oneline

# All unstaged changes
git diff --name-only HEAD
```

Summarise:
- Files staged or recently committed
- Whether the changes are feature additions, behavioural changes, or purely documentary

### 3. Resolve ambiguity

If there are no staged changes and no recent unpushed commits, use `AskUserQuestion` to ask:

> "I don't see any staged or unpushed changes. What would you like me to review?
> (a) A specific set of files or a planned feature — please describe it
> (b) All changes since the last tag
> (c) Cancel"

Do not ask if there is an obvious set of changed files.

### 4. Construct the assessment prompt

Build a self-contained prompt for the JTBD subagent that includes:
- The list of changed/staged files
- The git diff summary (stat output)
- Any explicit scope from the user
- The request: "Review these changes against the project's documented JTBD personas and jobs. Identify which jobs are served, whether any gaps exist (changes that don't trace to a documented job), and whether any jobs are unintentionally broken."

### 5. Delegate to wr-jtbd:agent

Invoke the JTBD subagent via the `Skill` tool:

```
subagent_type: wr-jtbd:agent
prompt: <constructed review prompt from step 4>
```

Wait for the subagent to complete.

### 6. Present results

Present the full alignment report to the user. The JTBD subagent will report:
- PASS: changes trace to documented jobs, no gaps
- GAPS: changes that don't trace to any documented job — new JTBD entry may be needed
- BREAKS: changes that appear to remove or degrade a documented job outcome
- NEW JOB NEEDED: capabilities being added that serve an undocumented need

If gaps or breaks are identified, use `AskUserQuestion` to ask how the user wants to proceed:
- (a) Document the new job before continuing (recommended)
- (b) Proceed with a documented exception
- (c) Revise the approach to serve an existing job

Do not make the decision unilaterally — per ADR-013 Rule 1, JTBD alignment decisions are the user's.

$ARGUMENTS
