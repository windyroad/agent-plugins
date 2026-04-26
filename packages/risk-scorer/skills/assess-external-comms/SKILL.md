---
name: wr-risk-scorer:assess-external-comms
description: On-demand external-comms risk review. Reviews a draft of an outbound prose tool call (gh issue/pr body, security advisory, npm publish content, or .changeset/*.md body) for confidential-information leaks per RISK-POLICY.md. Delegates to wr-risk-scorer:external-comms and pre-satisfies the external-comms-gate marker for the current session.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# External-Comms Risk Assessment Skill

Run a confidential-information leak review on demand against any drafted outbound prose — outside a hook gate trigger. Pre-satisfies the `external-comms-gate.sh` marker for the current session so the gated tool call (gh issue/pr/api/npm publish/changeset write) proceeds without re-prompting.

This skill is **read-only**. It does not commit, push, or modify files. The marker is written automatically by the `PostToolUse:Agent` hook (`risk-score-mark.sh`) after the subagent completes — the skill never writes to `${TMPDIR:-/tmp}/claude-risk-*` directly.

## When to use

- Before drafting a `gh issue create`/`gh pr create`/`gh issue comment`/`gh pr comment` to a third-party repo.
- Before drafting a `gh api .../security-advisories` body for a vendor private channel.
- Before authoring a `.changeset/*.md` body that will land in CHANGELOG.md and every published npm tarball (P073).
- Before `npm publish` when the README diff is non-trivial.
- After hitting the external-comms gate's deny-and-delegate prompt: this skill is the structured walkthrough that closes the loop.

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for either:

- A draft body verbatim (e.g. the user pastes the prose they're about to post).
- A surface hint (`gh-issue-create`, `gh-pr-comment`, `gh-api-security-advisories`, `gh-issue-edit`, `gh-pr-edit`, `gh-issue-comment`, `gh-pr-create`, `gh-api-comments`, `npm-publish`, `changeset-author`).
- A destination hint (`anthropics/claude-code#52831`, `vendor private channel`, `npm public registry`).

If both draft and surface are present, proceed to step 3. If either is missing, step 2.

### 2. Resolve missing context

If the draft is missing, use `AskUserQuestion`:

> "What draft do you want me to review? Paste the body verbatim — I will pass it to the external-comms reviewer."

If the surface is missing AND cannot be inferred from context (e.g. user just said "before I post this comment"), use `AskUserQuestion`:

- header: "Target surface"
- options:
  1. `gh issue create` (public third-party repo)
  2. `gh issue comment` (public third-party repo)
  3. `gh pr create` / `gh pr comment` (public third-party repo)
  4. `gh api .../security-advisories` (vendor private channel)
  5. `npm publish` (permanently published artefact)
  6. `.changeset/*.md` (lands in CHANGELOG + Release PR + every npm tarball)

Do not ask if the surface is obvious from the conversation context.

### 3. Construct the review prompt

Build a self-contained prompt for the `wr-risk-scorer:external-comms` subagent that includes:

- The **draft body** verbatim (between explicit `<draft>...</draft>` markers so the agent's substring extraction is unambiguous).
- The **target surface** (one of the canonical strings above).
- The **destination** when known.
- A reminder to compute `EXTERNAL_COMMS_RISK_KEY = sha256(draft + '\n' + surface)`.

### 4. Delegate to wr-risk-scorer:external-comms

Invoke the subagent via the `Skill` tool:

```
subagent_type: wr-risk-scorer:external-comms
prompt: <constructed review prompt from step 3>
```

Wait for the subagent to complete. The subagent will output a structured verdict block (`EXTERNAL_COMMS_RISK_VERDICT: PASS|FAIL` + `EXTERNAL_COMMS_RISK_KEY: <sha>` + optional `EXTERNAL_COMMS_RISK_REASON: ...`). The `PostToolUse:Agent` hook (`risk-score-mark.sh`) reads that output and writes the marker automatically.

**Do not write to `${TMPDIR:-/tmp}/claude-risk-*` yourself.** The hook is the only correct mechanism.

### 5. Present results

Present the full review report to the user. Highlight:

- The verdict (PASS / FAIL).
- Each Confidential Information class the draft matched against (FAIL only).
- The exact substrings that triggered each finding (FAIL only).
- Whether the gate is now pre-satisfied for the current session for this exact draft+surface key (PASS only): "The next attempt to <surface> with this draft body will proceed without re-prompting."

### 6. Above-appetite handling (ADR-013 Rule 6)

If the verdict is FAIL, do NOT auto-rewrite the draft. Use `AskUserQuestion`:

- header: "Leak detected — next step"
- options:
  1. `Rewrite the draft and re-review` — return to step 1 with the rewritten body.
  2. `Move to a private channel` — direct the user to a non-public surface (vendor private email, internal Slack, etc.) where the leak does not apply.
  3. `Override anyway` — set `BYPASS_RISK_GATE=1` for the next gated tool call. Reserved for cases where the user has confirmed the content is safe to publish (e.g. the "client name" is actually their own org).
  4. `Cancel` — abandon the post.

Do not make the decision unilaterally — per ADR-013 Rule 1, all leak/no-leak judgement calls outside the regex pre-filter belong to the user.

$ARGUMENTS
