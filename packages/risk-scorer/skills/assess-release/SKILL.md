---
name: wr-risk-scorer:assess-release
description: On-demand release risk assessment. Scores commit, push, and release risk for the current unpushed changes. Delegates to wr-risk-scorer:pipeline and satisfies the commit gate for the current session.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# Release Risk Assessment Skill

Run a pipeline risk assessment on demand — outside a hook gate trigger. Scores commit, push, and release risk layers for the current unpushed changes and satisfies the gate for the current session.

This skill is **read-only**. It does not commit, push, or modify files. The bypass marker is written automatically by the `PostToolUse:Agent` hook (`risk-score-mark.sh`) after the subagent completes — the skill never writes to `$TMPDIR/claude-risk-*` directly.

## When to use

- Before committing: confirm the risk score before running `git commit`
- Pre-flight release check: get a release readiness score before deciding to ship
- On-demand: any time you want a risk score without triggering a gate event

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for an explicit release scope (e.g., "release v1.3.0", "commits since last tag", "changeset X"). If a scope is provided, use it. If empty, proceed to auto-detection.

### 2. Auto-detect context

Run the following to establish the assessment scope:

```bash
# Unpushed commits
git log origin/$(git rev-parse --abbrev-ref HEAD)..HEAD --oneline 2>/dev/null || git log HEAD --oneline -10

# Staged diff
git diff --cached --stat

# Changesets directory (if present)
ls .changeset/*.md 2>/dev/null | head -20
```

Summarise what you find:
- Number of unpushed commits and their subjects
- Files staged for commit (if any)
- Changesets queued for release (if any)

### 3. Resolve ambiguity

If the scope is genuinely ambiguous (e.g., no unpushed commits but the user said "assess the release"), use `AskUserQuestion` to ask:

> "I don't see any unpushed commits. What scope should I assess?
> (a) All commits since the last git tag
> (b) Only the currently staged diff
> (c) A specific range — please specify
> (d) Cancel"

Do not ask if there is an obvious unpushed commit queue.

### 4. Construct the assessment prompt

Build a self-contained prompt for the pipeline subagent that includes:
- The git log summary (unpushed commits with subjects)
- The staged diff summary (file names and line counts)
- The changeset list (if any)
- Any explicit scope the user provided

### 5. Delegate to wr-risk-scorer:pipeline

Invoke the pipeline scorer via the `Skill` tool. The `wr-risk-scorer:pipeline` SKILL is a thin wrapper around the pipeline agent (per ADR-015 — see `packages/risk-scorer/skills/pipeline/SKILL.md`):

```
skill: wr-risk-scorer:pipeline
prompt: <constructed assessment prompt from step 4>
```

Wait for the wrapper to return. The wrapper invokes the pipeline agent internally; the agent's structured `RISK_SCORES:` block flows back through the wrapper verbatim. The `PostToolUse:Agent` hook (`risk-score-mark.sh`) fires on the wrapper's inner Agent invocation and writes the bypass marker files automatically.

**Do not write to `$TMPDIR/claude-risk-*` yourself.** The hook is the only correct mechanism.

### 6. Present results

Present the full risk report to the user. Highlight:
- The three risk scores (commit / push / release) and their labels
- Any risks above appetite (score ≥ 5 per RISK-POLICY.md)
- Whether the gate is now pre-satisfied for the current session (i.e., a subsequent `git commit` will reuse the bypass marker without re-triggering the scorer)

If any score is above appetite, the action is **framework-mediated, not a user decision** (P377/RFC-029; ADR-044 category-3 explicitly excludes above-appetite). Per **ADR-042 Rule 1**: auto-apply scorer remediations incrementally until residual risk is within appetite, OR halt per ADR-042 Rule 5 if the scorer cannot converge. **MUST NOT commit/push/release above appetite, and MUST NOT use `AskUserQuestion` to ask whether to proceed anyway** — there is no "proceed anyway (bypass)" option; the answer is always reduce-risk-or-halt. The only sanctioned non-blocking path is the risk-reducing path (a genuinely risk-reducing change clears via the `reducing` bypass). Under non-interactive contexts the ADR-013 Rule 6 fail-safe is the terminal fallback: skip the action and report the uncommitted/unreleased state.

$ARGUMENTS
