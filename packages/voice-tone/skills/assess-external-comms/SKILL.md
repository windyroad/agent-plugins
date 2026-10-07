---
name: wr-voice-tone:assess-external-comms
description: On-demand external-comms voice & tone review. Reviews a draft of an outbound prose tool call (gh issue/pr body, security advisory, npm publish content, or .changeset/*.md body) against docs/VOICE-AND-TONE.md. Delegates to wr-voice-tone:external-comms and pre-satisfies the external-comms-gate marker for the current session.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# External-Comms Voice & Tone Assessment Skill

Run a voice & tone review on demand against any drafted outbound prose — outside a hook gate trigger. Pre-satisfies the `external-comms-gate.sh` marker for the current session so the gated tool call (gh issue/pr/api/npm publish/changeset write) proceeds without re-prompting.

This skill is **read-only**. It does not commit, push, or modify files. The marker is written automatically by the `PostToolUse:Agent` hook (`external-comms-mark-reviewed.sh`) after the subagent completes — the skill never writes to `${TMPDIR:-/tmp}/claude-risk-*` directly.

This is the voice-tone half of the external-comms gate. The risk/leak half is handled by `/wr-risk-scorer:assess-external-comms`. When both plugins are installed, both evaluators must PASS independently before the gate permits the tool call.

## When to use

- Before drafting a `gh issue create` / `gh pr create` / `gh issue comment` / `gh pr comment` to a third-party repo.
- Before drafting a `gh api .../security-advisories` body for a vendor private channel.
- Before authoring a `.changeset/*.md` body that will land in CHANGELOG.md and every published npm tarball (P073).
- Before `npm publish` when the README diff is non-trivial.
- After hitting the external-comms gate's deny-and-delegate prompt: this skill is the structured walkthrough that closes the voice-tone loop.

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for either:

- A draft body verbatim (e.g. the user pastes the prose they're about to post).
- A surface hint (`gh-issue-create`, `gh-pr-comment`, `gh-api-security-advisories`, `gh-issue-edit`, `gh-pr-edit`, `gh-issue-comment`, `gh-pr-create`, `gh-api-comments`, `npm-publish`, `changeset-author`).
- A destination hint (`anthropics/claude-code#52831`, `vendor private channel`, `npm public registry`).

If both draft and surface are present, proceed to step 3. If either is missing, step 2.

### 2. Resolve missing context

If the draft is missing, use `AskUserQuestion`:

> "What draft do you want me to review? Paste the body verbatim — I will pass it to the external-comms voice-tone reviewer."

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

Build a self-contained prompt for the `wr-voice-tone:external-comms` subagent. The prompt MUST be structured so the PostToolUse hook can derive the marker key locally (P166 / ADR-028 amended 2026-05-16) — single fire per gate cycle suffices:

```
SURFACE: <surface-name>
<draft>
<draft body verbatim>
</draft>

Destination: <destination if known>
Review against docs/VOICE-AND-TONE.md.
```

Two requirements:

- A leading line `SURFACE: <surface-name>` where `<surface-name>` is one of the canonical strings (`gh-issue-create`, `gh-pr-comment`, etc.) — anchored to line start, single token.
- The **draft body** wrapped verbatim inside `<draft>...</draft>` markers — the hook extracts everything between these markers and uses it for `sha256(DRAFT + '\n' + SURFACE)`.

The orchestrator does NOT pre-compute the key — the hook derives it from the prompt structure. Skip the agent-emitted key entirely.

### 4. Delegate to wr-voice-tone:external-comms

Invoke the subagent via the Agent tool. Dispatch it **synchronously** (`run_in_background: false`) — the `PostToolUse:Agent` mark hook (`external-comms-mark-reviewed.sh`) fires reliably only for a synchronous agent; a background-launched reviewer's mark hook does not fire in time, so no marker persists and the voice-tone gate re-blocks despite a PASS verdict (P402):

```
subagent_type: wr-voice-tone:external-comms
run_in_background: false
prompt: <constructed review prompt from step 3>
```

Wait for the subagent to complete. The subagent outputs a structured verdict block (`EXTERNAL_COMMS_VOICE_TONE_VERDICT: PASS|FAIL` + optional `EXTERNAL_COMMS_VOICE_TONE_REASON: ...` on FAIL). The `PostToolUse:Agent` hook (`external-comms-mark-reviewed.sh`) parses the verdict, derives the marker key from the prompt's `SURFACE:` + `<draft>` structure, and writes the per-evaluator marker automatically on PASS.

On Codex, use `agent_type: wr-voice-tone:external-comms` with
`fork_turns: "none"`. After it reports completion, invoke `interrupt_agent`
exactly once on that completed target so the compatibility hook can persist the
structured verdict.

**Do not write to `${TMPDIR:-/tmp}/claude-risk-*` yourself.** The hook is the only correct mechanism.

### 5. Present results

Present the full review report to the user. Highlight:

- The verdict (PASS / FAIL).
- Each `docs/VOICE-AND-TONE.md` section / principle / banned-pattern entry the draft violated (FAIL only).
- The exact substrings that triggered each finding (FAIL only).
- Whether the voice-tone gate is now pre-satisfied for the current session for this exact draft+surface key (PASS only): "The next attempt to <surface> with this draft body will proceed past the voice-tone evaluator without re-prompting."

When both evaluators are required (voice-tone + risk-scorer both installed), remind the user that the risk-scorer evaluator may still need its own delegation (run `/wr-risk-scorer:assess-external-comms`) before the gate fully permits.

### 6. Correct the authorized draft and re-review (ADR-138; ADR-044)

A FAIL rejects the reviewed draft; it does not withdraw authorization to correct it. The calling assistant must automatically revise routine wording, sentence count, formatting and tense failures within the user's already-authorized intent. For a leak finding, safely redact the detected confidential content when that preserves the authorized message. Do not ask for rewrite permission when the instructions and findings resolve the correction.

This assessment and its reviewer remain read-only. The calling assistant prepares the revised draft in memory, then returns to step 3 with the exact revised text and the same surface. Run every applicable evaluator again, including both voice-tone and risk when installed. A previous PASS or receipt applies only to its original draft; never reuse it to clear changed text, write markers by hand, or fabricate a PASS. Continue the already-authorized action only after substantive reviews of the revised draft PASS. A substantive FAIL is not a mechanical transport failure and cannot be bypassed.

Ask for a substantive choice only when the correction would materially change the intended meaning, factual claims, destination or disclosure authority and the existing user instructions do not resolve that choice. Do not invent evidence, choose a new recipient, or publish the failed draft. If safe revisions still FAIL, report the unresolved finding and obtain only the missing substantive decision. In unattended work, queue unresolved choices and continue independent work per ADR-013 Rule 6; keep the failed communication unpublished.

$ARGUMENTS
