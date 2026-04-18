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

**What recurring workflow did I (or the assistant) perform that would be better as a skill?** — multi-step sequences that (a) were invoked multiple times in one session, (b) have a deterministic action order, and (c) are reusable across projects, not project-specific logic. These are **skill candidates**, not problem tickets, and route through Step 4b below.

Examples of skill candidates vs problem tickets:
- `fetch origin → check changesets → score risk → commit → push → release → sync manifest → mark Fix Released` — deterministic, recurring, cross-project → **skill candidate** (e.g. `wr-itil:ship-fix`).
- "The commit gate rejected my work twice because X was misconfigured" — diagnostic, project-specific → **problem ticket**.
- "I always forget to run `npm run verify` before pushing" — short, user-habit rather than codifiable sequence → **BRIEFING.md** note, not a skill.

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

### 4b. Recommend new skills

For each **skill candidate** identified in Step 2, route the decision through `AskUserQuestion`. This is the ADR-013 Rule 1 structured-interaction pattern — do not present the choices as prose enumeration in the skill output.

For each candidate, invoke `AskUserQuestion` with:
- `header: "Skill candidate"`
- `multiSelect: false`
- Three options:
  1. `Create a new skill` — description: "Scaffold a new skill for this recurring workflow. Requires suggested name, scope, and triggers — Step 4b records them for a future scaffolding flow to pick up."
  2. `Track as a problem ticket instead` — description: "File the candidate via /wr-itil:manage-problem so it can be planned and WSJF-ranked alongside other backlog items."
  3. `Skip — not skill-worthy` — description: "Neither create nor track. The candidate is too small, too ambiguous, or too project-specific to codify."

When the user chooses **Create a new skill**, record a candidate entry with:
- **Suggested skill name** (e.g. `wr-itil:ship-fix`) — kebab-case, namespaced to the owning plugin
- **Scope** — one sentence on what the skill does and when it should fire
- **Triggers** — example user prompts that should invoke it
- **Prior uses** — 2-3 observed invocations from this session

Store the candidate entry in the Step 5 summary under "Skill Candidates". Skill scaffolding itself is out of scope for this retrospective — scaffolding may land in a future skill (see P012 skill testing harness for the testing side of that).

When the user chooses **Track as a problem ticket**, fall through to the Step 4 flow with a "this should be a skill" note in the ticket description.

When the user chooses **Skip**, record the candidate in the Step 5 summary under "Skill Candidates" with a `skipped` marker so the pattern is still visible in the session audit trail.

**Non-interactive fallback (per ADR-013 Rule 6):** if `AskUserQuestion` is unavailable, record each candidate in the Step 5 summary under "Skill Candidates" with a `flagged — not actioned (non-interactive)` marker and do not create tickets or scaffold. The user can review the flags and decide when they return.

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

### Skill Candidates
- [suggested name] — [scope]. Triggers: [examples]. Decision: [created / tracked as P<NNN> / skipped / flagged (non-interactive)].

### No Action Needed
- [learnings that were already captured]
```

If the "Skill Candidates" section is empty, omit it rather than rendering an empty header.

$ARGUMENTS
