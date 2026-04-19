---
name: wr-retrospective:run-retro
description: Run a session retrospective. Updates docs/BRIEFING.md with learnings and creates problem tickets for failures and friction.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

# Session Retrospective

Reflect on the current session, update the project briefing, and create problem tickets for failures and friction.

## Steps

### 1. Read the current briefing

Read `docs/BRIEFING.md` to understand what previous sessions already captured.

### 2. Reflect on this session

Consider the work done in this session and identify:

**What you wish you'd been told up front** — things that were non-obvious and caused wasted effort or wrong assumptions. These should be added to BRIEFING.md "What You Need to Know" if they aren't already there.

**What surprised you** — things that contradicted reasonable expectations. These should be added to BRIEFING.md "What Will Surprise You" if they aren't already there.

**What was harder than it should have been** — friction points, tool limitations, process overhead, confusing code. These should become problem tickets via the `/problem` skill.

**What failed** — things that broke, bugs encountered, hooks that errored, tests that failed unexpectedly. These should become problem tickets via the `/problem` skill.

**What should we make easier or automate** — repetitive manual steps, missing tooling, things that could be scripted. These should become problem tickets via the `/problem` skill.

**What recurring pattern did I (or the assistant) observe that would be better codified?** — a pattern that (a) was invoked multiple times in one session or across sessions, (b) has a deterministic action order or a clear invariant, and (c) is reusable beyond one project. These are **codification candidates** and route through Step 4b below. Do not treat them as problem tickets unless the user explicitly picks that routing option.

For each codification candidate, also identify the **best shape** for the codification. The Windy Road suite supports many shapes — pick the one that fits the pattern, not the one you happened to learn first:

- **Skill** — deterministic multi-step sequence the user invokes by name (e.g. `wr-itil:ship-fix`). Worked example: `fetch origin → check changesets → score risk → commit → push → release → sync manifest → mark Fix Released`.
- **Agent** — bounded investigation or review the main agent should delegate to (e.g. a performance-specialist the architect calls in for runtime-path changes). Place under `packages/<plugin>/agents/`.
- **Hook** — event-driven enforcement or prompt injection (PreToolUse, PostToolUse, UserPromptSubmit). Use when "I keep forgetting to X before Y" — hooks make X unmissable without adding memory load.
- **Settings entry** — `.claude/settings.json` changes: allowlisted commands, env vars, hook wiring. Best fit when a session repeatedly hits permission prompts for the same benign tool.
- **Shell or Node script** — reusable repo-level tooling in `scripts/` (e.g. `sync-install-utils.sh`, `sync-plugin-manifests.mjs`). Best fit for multi-step shell sequences worth scripting.
- **CI step** — `.github/workflows/*.yml` insertion. Best fit for "we'd have caught that earlier with a CI check".
- **ADR** — architectural decision worth recording. Route to `/wr-architect:create-adr`.
- **JTBD** — job-to-be-done record for a persona. Route to `/wr-jtbd:update-guide`.
- **Guide** — voice, style, or risk policy edit. Route to `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, or `/wr-risk-scorer:update-policy`.
- **Problem ticket** — diagnostic, project-specific friction (the default for flaws). Route to `/wr-itil:manage-problem`.
- **Test fixture** — regression test for a recurring failure pattern (bats fixture, unit test). Best fit when the observation is "this kept breaking the same way".
- **Memory** — per-user or per-project memory note in `~/.claude/.../memory/`. Best fit for short, user-habit observations that aren't a codifiable sequence (e.g. "I always forget to run `npm run verify` before pushing").

If no shape fits — the observation is a one-off learning, not a repeating pattern — it belongs in BRIEFING.md (Step 3), not Step 4b.

Counter-examples (what does **not** become a codification candidate):
- "The commit gate rejected my work twice because X was misconfigured" — diagnostic, project-specific → **problem ticket** shape (route via Step 4b).
- "I always forget to run `npm run verify` before pushing" — short, user-habit rather than codifiable sequence → **memory** shape or **BRIEFING.md** note.

### 3. Update BRIEFING.md

Edit `docs/BRIEFING.md`:

- **Add** new learnings to the appropriate section ("What You Need to Know" or "What Will Surprise You")
- **Remove** stale items that are no longer true. A learning is stale when:
  - The issue has been fixed (e.g., "CI doesn't test v2" after v2 tests are added)
  - It's now documented elsewhere (e.g., in an ADR, CLAUDE.md, or README)
  - The codebase has changed enough that it's no longer relevant
- **Update** items where the details have changed
- Keep the file concise — under 2000 tokens. Each item should be 1-2 lines.

Use the AskUserQuestion tool to confirm any removals: "I'd like to remove [item] from BRIEFING.md because [reason]. Is this correct?"

### 4. Create or update problem tickets

For each item identified in "What was harder than it should have been", "What failed", and "What should we make easier or automate", use the `/problem` skill to:

- Check if a problem ticket already exists in `docs/problems/`
- If yes: update it with new evidence from this session
- If no: create a new problem ticket

### 4b. Recommend new codifications

For each **codification candidate** identified in Step 2, route the decision through a single `AskUserQuestion` call. This is the ADR-013 Rule 1 structured-interaction pattern — do not present the choices as prose enumeration in the skill output. The shape identified in Step 2 determines which option rows the user picks from; every shape routes through the same `AskUserQuestion` so the decision stays one structured interaction (architect decision: flat shape-prefixed options, not a two-step type-then-action flow).

For each candidate, invoke `AskUserQuestion` with:
- `header: "Codification candidate"`
- `multiSelect: false`
- Options (a flat list; each option names the shape up front so the decision is auditable):
  1. `Skill — create stub` — description: "Record a stub candidate (suggested name, scope, triggers, prior uses) for a future scaffolding flow. Skill scaffolding itself is out of scope for this retrospective."
  2. `Agent — create stub` — description: "Record a stub candidate for a new agent (suggested name, scope, trigger conditions, delegating skill). Place under `packages/<plugin>/agents/` when scaffolded."
  3. `Hook — create stub` — description: "Record a stub candidate for a new hook (event: PreToolUse / PostToolUse / UserPromptSubmit; trigger; action summary)."
  4. `Settings — propose entry` — description: "Record a proposed `.claude/settings.json` entry (allowlist / env / hook wiring) for later review."
  5. `Script — create stub` — description: "Record a stub `scripts/*.sh` or `scripts/*.mjs` candidate (shebang + TODO + scope)."
  6. `CI — propose step` — description: "Record a proposed `.github/workflows/ci.yml` insertion."
  7. `ADR — invoke create-adr` — description: "Delegate to `/wr-architect:create-adr` so the decision is captured with proper MADR structure. Routing skill, not a stub."
  8. `JTBD — invoke update-guide` — description: "Delegate to `/wr-jtbd:update-guide` to add or amend a job-to-be-done record. Routing skill, not a stub."
  9. `Guide — invoke update-guide / update-policy` — description: "Delegate to `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, or `/wr-risk-scorer:update-policy` depending on the guide touched."
  10. `Problem — invoke manage-problem` — description: "Delegate to `/wr-itil:manage-problem` so the candidate is WSJF-ranked against other backlog items. Routing skill, not a stub."
  11. `Test fixture — create stub` — description: "Record a candidate bats / unit-test fixture for the recurring failure pattern."
  12. `Memory — propose note` — description: "Record a proposed memory note (per-user or per-project) for a short user-habit observation that isn't a codifiable sequence."
  13. `Skip — not codify-worthy` — description: "Neither stub nor route. The observation is too small, too ambiguous, or a one-off learning that belongs in BRIEFING.md."

If the option count is impractical for a single `AskUserQuestion` payload in a given Claude Code version, fall back to a two-question flow: (1) `"Which shape fits?"` with the shape list, (2) `"What action?"` with `Create stub / Invoke dedicated skill / Skip` — but prefer the single call when the surface allows it.

When the user chooses any of the **Create stub** shapes (skill / agent / hook / settings / script / CI / test / memory), record a candidate entry in the Step 5 summary under "Codification Candidates" with:
- **Shape** — which codification type (skill, agent, hook, etc.)
- **Suggested name** — for skills: `wr-<plugin>:<action>`; for agents: `<plugin>:<name>`; for hooks: `<event>:<trigger>`; for scripts: `scripts/<name>.<ext>`; etc.
- **Scope** — one sentence on what the codification does and when it should fire
- **Triggers** — example user prompts or events that should invoke it
- **Prior uses** — 2-3 observed invocations from this session

When the user chooses any of the **Invoke <dedicated skill>** routes (ADR / JTBD / Guide / Problem), delegate to the named skill with a context hand-off describing the candidate. Record the routing decision in the Step 5 summary under "Codification Candidates" with Shape = the routing target and a `routed to <skill>` marker.

When the user chooses **Skip**, record the candidate in the Step 5 summary under "Codification Candidates" with a `skipped` marker so the pattern is still visible in the session audit trail.

**Non-interactive fallback (per ADR-013 Rule 6):** if `AskUserQuestion` is unavailable, record each candidate in the Step 5 summary under "Codification Candidates" with a `flagged — not actioned (non-interactive)` marker, noting the identified Shape. Do not create stubs, route to dedicated skills, or scaffold. The user can review the flags and decide when they return.

**Backward compatibility**: "Skill" is retained as one shape among many so existing P044 muscle memory and `run-retro-skill-candidates.bats` continue to hold. Use the singular shape name in the summary (e.g. `Shape: skill`) so legacy greps still match.

### 5. Summary

Present a summary to the user:

```
## Session Retrospective

### BRIEFING.md Changes
- Added: [items added]
- Removed: [items removed with reasons]
- Updated: [items modified]

### Problems Created/Updated
- [problem ticket]: [summary]

### Codification Candidates

| Shape | Suggested name | Scope | Triggers | Decision |
|-------|---------------|-------|----------|----------|
| skill | [suggested name] | [scope] | [examples] | created stub / routed to <skill> / skipped / flagged (non-interactive) |
| agent | ... | ... | ... | ... |
| hook  | ... | ... | ... | ... |

### No Action Needed
- [learnings that were already captured]
```

If the "Codification Candidates" table has no rows, omit it rather than rendering an empty header. The legacy "Skill Candidates" heading is preserved as a worked-example row in the Shape column so downstream tooling that grepped for "Skill Candidates" continues to find skill-shaped entries within the unified table.

$ARGUMENTS
