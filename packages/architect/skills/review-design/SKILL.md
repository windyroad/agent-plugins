---
name: wr-architect:review-design
description: On-demand architecture compliance review. Checks staged changes and recent commits against existing ADRs in docs/decisions/. Use before editing architecture-bearing files or before a release.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Skill
---

# Architecture Compliance Review Skill

Run an architecture compliance review on demand — outside the pre-tool-use hook gate. Reviews staged changes and recent commits against the project's ADRs in `docs/decisions/`.

This skill is **read-only**. It does not commit, push, or modify files.

## One headline, no riders

Each ADR records only one independently changeable headline decision. Split multiple decisions into separate ADRs. Include context, alternatives, rationale, consequences and decision-level confirmation criteria. Keep implementation instructions, commands, resource configuration and delivery tasks outside ADRs. No riders: ratification covers only the single explicitly presented headline decision. Additional decisions, clauses or conditions require separate ratification. Context, rationale, consequences and confirmation criteria must not introduce additional mandatory choices. Preserve ratified substance; propose amendments through separate successor proposals rather than rewriting it unilaterally.

## ADR lifecycle: propose, use, then accept

A proposed ADR may guide implementation before human ratification. Keep it `status: proposed` and `human-oversight: unconfirmed` while building and learning; proposal implementation does not grant acceptance. Do not request final ratification merely to unblock implementation.

Acceptance requires **both** explicit human ratification of the final decision substance **and** evidence of successful actual production use satisfying its Confirmation criteria. Confirmation must contain evidence that the chosen architecture has worked in actual production use, sufficient for a human to evaluate it. Operational receipts and delivery instructions belong in the delivery artifact. Local tests, CI, publication, previews, staging, and synthetic evaluations alone are insufficient. Missing either condition means the ADR stays proposed. Do not invent evidence or automatically promote historical ADRs.

Once production evidence is complete, finish the draft, obtain cognitive accessibility review, present the complete substance, and seek human ratification through the existing ratification flow. Only then record acceptance; preserve existing supersession procedures. Direction to experiment or build is not final ratification. Existing architecture, story-map, job, risk, and release gates still apply.

## When to use

- Pre-flight before a release or client handover: confirm no ADR violations crept in
- After a large refactor: verify the new structure still complies with decisions
- When proposing a structural change: get a review before editing architecture-bearing files
- Any time the hook gate is not convenient: e.g., planning mode, exploratory spikes

## Output Formatting

When referencing decision IDs (ADR-<NNN>), problem IDs (P<NNN>), or JTBD IDs in prose output, always include the human-readable title on first mention. Use the format `ADR-013 (Skill manifest in package.json)`, not bare `ADR-013`.

## Steps

### 1. Parse arguments

Read `$ARGUMENTS` for an explicit review scope (e.g., "review my changes to the auth module", "check the new API routes", "pre-release review"). If a scope is provided, use it. If empty, proceed to auto-detection.

### 2. Auto-detect context

Run the following to establish what needs reviewing:

```bash
# Staged changes
git diff --cached --stat

# Recent commits not yet pushed
git log origin/$(git rev-parse --abbrev-ref HEAD)..HEAD --oneline 2>/dev/null || git log HEAD -5 --oneline

# Changed files
git diff --cached --name-only
git diff --name-only HEAD
```

Summarise:
- Files staged or recently committed
- Whether the changes are architectural (source code, config, schema, tooling) vs purely documentary

### 3. Resolve ambiguity

If there are no staged changes and no recent unpushed commits, use `AskUserQuestion` to ask:

> "I don't see any staged or unpushed changes. What would you like me to review?
> (a) A specific set of files — please name them
> (b) All changes since the last tag
> (c) A planned change you'd like to describe
> (d) Cancel"

Do not ask if there is an obvious set of changed files.

### 4. Construct the assessment prompt

Build a self-contained prompt for the architect subagent that includes:
- The list of changed/staged files
- The git diff summary (stat output)
- Any explicit scope from the user
- The request: "Review these proposed changes against the project's ADRs. Flag any violations, gaps that need a new ADR, or compliance questions."

The architect permits implementation against documented proposals without prior ratification. It flags **[Premature Acceptance]** when acceptance lacks either final human ratification or successful actual production-use evidence. Apply this distinction to plans and edits alike; missing ratification alone does not block building.

### 5. Delegate to the architect agent

Use the runtime-native architect agent path with the constructed prompt.

Claude Code invocation:

```
subagent_type: wr-architect:agent
prompt: <constructed review prompt from step 4>
```

Codex invocation:

```
agent: wr-architect:agent
prompt: <constructed review prompt from step 4>
```

The Codex installer generates `.codex/agents/wr-architect-agent.toml` from the installed plugin's `agents/agent.md` and registers the exact identity `wr-architect:agent`. SessionStart repairs the user-scoped registration when needed. Adopter projects do not need to ship their own agent configuration. Restart Codex if that exact identity is not visible; do not substitute the built-in `default` agent because the review marker consumes the architect identity. The repo-local `.codex/agents/wr-architect.toml`, kept in sync from `packages/architect/agents/agent.md` by `scripts/sync-codex-agents.mjs`, remains the short-name `wr-architect` alias for source-repo dogfooding.

Wait for the agent to complete.

### 6. Present results

Present the full compliance report to the user. The architect subagent will report:
- PASS: no violations found
- FLAGGED: specific violations or compliance questions with ADR references
- NEW ADR NEEDED: decisions that should be recorded before proceeding

If violations are flagged, use the runtime's structured question mechanism to ask how the user wants to proceed:
- (a) Address the violations before continuing
- (b) Proceed with a documented exception
- (c) Draft a new ADR that supersedes the ratified decision, or edit the existing ADR only when it is still unratified

Do not make the decision unilaterally — per ADR-013 Rule 1, architectural risk decisions are the user's.

$ARGUMENTS
