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

**What existing skill, agent, hook, ADR, guide, or other codifiable showed a flaw, gap, or friction this session that a targeted edit would fix?** — the **improvement axis** of the codification surface. Criteria: (a) the flaw is reproducible and specific, (b) the fix is a bounded edit to an existing file, (c) no new concept is being invented. Improvement observations flow through the same Step 4b `AskUserQuestion` call as creation candidates, but their options name the improvement shape (e.g. `Skill — improvement stub`, `ADR — supersede or amend`) and the resulting Step 5 row records `Kind: improve` rather than `Kind: create`. An improvement that touches multiple unrelated concerns must be split using the P016 / P017 concern-boundary pattern before routing. If a single output accumulates ≥ 3 improvements in one session, prefer a single coordinating problem ticket over N separate tickets.

For each codification candidate, also identify the **Kind** (`create` for a new output, `improve` for a targeted edit to an existing output) and the **best shape** for the codification. The Windy Road suite supports many shapes — pick the one that fits the pattern, not the one you happened to learn first:

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

### 4a. Verification-close housekeeping (P068)

Problems whose fix shipped but whose closure is still pending (`docs/problems/*.verifying.md` per ADR-022) accumulate across sessions. When this session's activity exercised a pending fix successfully, run-retro surfaces the evidence so the user can close on observed fact rather than by calendar age (P048's `Likely verified` heuristic) or deferred user review (manage-problem Step 9d's baseline user-initiated path). This step extends those paths with **session-context evidence**; the close decision remains the user's.

**Ownership boundary**: run-retro surfaces evidence and asks; `/wr-itil:manage-problem` Step 7 Verification Pending → Closed transition (rename + Status edit + P057 re-stage + ADR-014 commit per ADR-022) is invoked via the Skill tool to perform the actual file rename and commit. run-retro does **not** rename, edit the Status field, or commit — those remain `manage-problem`'s responsibility. ADR-014 lists run-retro as out of scope for its own commits; the delegated manage-problem call commits per ADR-014 + ADR-022 and that boundary is preserved.

**Steps:**

1. **Glob**: enumerate `docs/problems/*.verifying.md` (the driven-by-filename surface per ADR-022).

2. **Read the `## Fix Released` section** of each file and extract the fix-summary keyword set: release marker (version, commit SHA, or date), affected source path(s), new test file path(s), and any named skill / hook / gate the fix exercises.

3. **Evidence scan** against the session's in-context activity. For each ticket, collect specific citations (tool invocation, timestamp or position in the session, and the observable outcome). Accepted evidence classes:
   - **Test invocations** that ran the fix's test file or a superset and returned zero (e.g. `npx bats packages/itil/skills/manage-problem/test/manage-problem-external-root-cause-detection.bats` — 14/14 passed at session position N).
   - **Commits** whose diff covered the fix's source path (cite the commit SHA and path).
   - **Skill invocations** that rely on the fix (e.g. `manage-problem` using P056's corrected next-ID lookup; cite the invocation and the observable that the fix contract held — "ID 072 computed without origin_max blob-SHA false-match").
   - **Hook firings** on gate paths the fix established (cite the tool call that triggered the hook and the hook's observed behaviour).
   - **Release cycles** (`push:watch` / `release:watch`) that shipped a commit dependent on the fix (cite the workflow run ID and exit status).

4. **Categorise** each `.verifying.md` ticket into one of three buckets:
   - **Exercised successfully in-session** — at least one citation from step 3. Record the ticket as a close-candidate. Citations MUST be specific (tool invocation + observable outcome), not bare counts — per ADR-026 grounding. If no specific citation can be produced, the ticket does NOT go in this bucket regardless of how often the fix's area was touched.
   - **Not exercised in-session** — no citation collected. Leave as Verification Pending; nothing surfaces for this ticket.
   - **Exercised with regression** — the fix's contract observably failed (test red, hook misfired, skill produced incorrect output). This is a distinct problem, not a closure candidate. Flag it in the retro report as a new problem ticket (route via Step 4) with the regression evidence, and leave the `.verifying.md` file alone.

5. **Prompt the user (interactive path per ADR-013 Rule 1)** — for each close-candidate use `AskUserQuestion`:
   - `header: "Close verified ticket?"`
   - `multiSelect: false`
   - Question body MUST include the fix summary AND the specific citations collected in step 3 (not just ticket ID + title). The prompt is self-contained so the user can decide without reading the full ticket file.
   - Options:
     1. `Close P<NNN>` — description: "Delegate to /wr-itil:manage-problem for Verification Pending → Closed transition. manage-problem renames, updates Status, and commits per ADR-014 + ADR-022."
     2. `Leave as Verification Pending` — description: "Evidence noted but not yet sufficient to close. Ticket stays in the Verification Queue."
     3. `Flag for manual review` — description: "The evidence is ambiguous or contested; defer to a dedicated manage-problem review session."

6. **For each `Close P<NNN>` confirmation**, invoke the Skill tool with `wr-itil:manage-problem` and arguments like `<NNN> close — verified in-session via <citation summary>`. manage-problem performs the `git mv` .verifying.md → .closed.md, updates the Status field, re-stages per P057, and commits with message `docs(problems): close P<NNN> <title>` per ADR-014. The commit message should reference the retro session in its body.

7. **Non-interactive / AFK fallback (per ADR-013 Rule 6)**: when `AskUserQuestion` is unavailable (autonomous retro, batch session-wrap), do NOT auto-close and do NOT delegate to manage-problem. Instead, write a "Verification Candidates" section into the retro report (Step 5 summary) listing each close-candidate with its ticket ID, fix summary, and the specific citations collected in step 3. The user reviews on return and can run `/wr-itil:manage-problem <NNN> close` per ticket, or run `/wr-itil:manage-problem review` to fire Step 9d's baseline verification prompt. This deferral is explicit per the user's documented preference (feedback_verify_from_own_observation.md memory): surface evidence from the agent's own in-session observations, but the close decision remains user-confirmed per ADR-022.

**ADR-027 compatibility note**: when ADR-027's Step-0 auto-delegation lands on run-retro (run-retro is named in ADR-027's Scope as in-scope but has no Step 0 today), the evidence scan in step 3 becomes load-bearing on main-agent session context that a delegated subagent does not automatically inherit. The SKILL.md contract for that migration: either (a) run Step 4a in the main-agent context BEFORE Step-0 delegation to the subagent, or (b) have the Step-0 delegation prompt include an explicit session-activity summary (tool invocations, commits, skill calls observed in main-agent context) so the subagent has citable evidence. Option (a) is preferred because it keeps the evidence scan as close as possible to the observed activity; option (b) is the fallback if the subagent boundary must be crossed first.

**Interaction with other surfaces**:
- **manage-problem Step 9d** (baseline user-initiated verification review per P048) still fires on `/wr-itil:manage-problem review` — it is the age-based heuristic path. Step 4a here is the evidence-based session-wrap path. The two compose: a ticket that is both "≥ 14 days old" (Step 9d highlight) AND "exercised successfully this session" (Step 4a candidate) should be surfaced in both paths independently; closing via either path moves the ticket to `.closed.md` and de-lists it from both queues.
- **Skipped in this step**: `.verifying.md` tickets for fixes that ship in the currently-running session (e.g. P066, P063 just transitioned to `.verifying.md` this session) — a session cannot verify its own fix beyond "bats passed at commit time"; subsequent-session exercise is the meaningful signal. Treat same-session verifyings as "not exercised in-session" for closure purposes unless a later-session exercise path is in the citation list.

### 4b. Recommend new codifications

For each **codification candidate** identified in Step 2, route the decision through a single `AskUserQuestion` call. This is the ADR-013 Rule 1 structured-interaction pattern — do not present the choices as prose enumeration in the skill output. The shape and Kind identified in Step 2 determine which option rows the user picks from; every shape and Kind routes through the same `AskUserQuestion` so the decision stays one structured interaction (architect decision: flat shape-prefixed options, not a two-step type-then-action or Kind-then-shape flow).

For each candidate, invoke `AskUserQuestion` with:
- `header: "Codification candidate"`
- `multiSelect: false`
- Options (a flat list; each option names the shape and Kind up front so the decision is auditable):

  **Creation axis (Kind: create)** — new outputs:
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

  **Improvement axis (Kind: improve)** — targeted edits to existing outputs (P051):
  13. `Skill — improvement stub` — description: "Record a proposed targeted edit to an existing skill's SKILL.md (file path, observed flaw, evidence, edit summary). Use when an existing skill has a bounded, reproducible gap."
  14. `Agent — improvement stub` — description: "Record a proposed targeted edit to an existing agent file (path, observed flaw, edit summary)."
  15. `Hook — improvement stub` — description: "Record a proposed targeted edit to an existing hook script or `.claude/settings.json` wiring."
  16. `ADR — supersede or amend` — description: "Delegate to `/wr-architect:create-adr` with a `supersedes ADR-N` hint so the new ADR explicitly replaces or amends the outdated one. Routing skill, not a stub."
  17. `Guide — improvement edit` — description: "Delegate to `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-jtbd:update-guide`, or `/wr-risk-scorer:update-policy` for a targeted edit to an existing guide (voice / style / JTBD / risk policy)."
  18. `Problem — edit existing ticket` — description: "Delegate to `/wr-itil:manage-problem <NNN>` update flow to amend an existing open or known-error ticket with new observations from this session."

  **Default:**
  19. `Skip — not codify-worthy` — description: "Neither stub nor route. The observation is too small, too ambiguous, or a one-off learning that belongs in BRIEFING.md."

If a single output has accumulated ≥ 3 improvement candidates in one session, prefer offering a single coordinating ticket (`Problem — invoke manage-problem` with an "apply N improvements to X" scope) over recording N separate improvement stubs — this reduces ticket churn and keeps the affected output's improvement queue coherent.

If an improvement candidate touches multiple unrelated concerns, apply the P016 / P017 concern-boundary split before routing: re-run the `AskUserQuestion` once per concern, each with its own shape + Kind selection. This mirrors the concern-boundary analysis used when creating new problem tickets.

If the option count is impractical for a single `AskUserQuestion` payload in a given Claude Code version, fall back to a two-question flow: (1) `"Which shape fits?"` with the shape list, (2) `"Create, improve, or skip?"` with `Create stub / Improvement stub / Invoke dedicated skill / Skip` — but prefer the single call when the surface allows it.

When the user chooses any of the **Create stub** shapes (skill / agent / hook / settings / script / CI / test / memory), record a candidate entry in the Step 5 summary under "Codification Candidates" with:
- **Kind** — `create`
- **Shape** — which codification type (skill, agent, hook, etc.)
- **Suggested name** — for skills: `wr-<plugin>:<action>`; for agents: `<plugin>:<name>`; for hooks: `<event>:<trigger>`; for scripts: `scripts/<name>.<ext>`; etc.
- **Scope** — one sentence on what the codification does and when it should fire
- **Triggers** — example user prompts or events that should invoke it
- **Prior uses** — 2-3 observed invocations from this session

When the user chooses any of the **Improvement stub** shapes (skill / agent / hook), record a candidate entry in the Step 5 summary under "Codification Candidates" with:
- **Kind** — `improve`
- **Shape** — which existing codifiable is being edited (skill, agent, hook)
- **Target file** — the existing file path (e.g. `packages/itil/skills/manage-problem/SKILL.md`)
- **Observed flaw** — one-sentence description of the gap, friction, or defect
- **Edit summary** — one-sentence description of the proposed targeted edit
- **Evidence** — 1-3 observations from this session showing the flaw

When the user chooses any of the **Invoke <dedicated skill>** routes (ADR create / JTBD / Guide / Problem) OR the improvement routing options (ADR supersede or amend / Guide improvement edit / Problem edit existing ticket), delegate to the named skill with a context hand-off describing the candidate. Record the routing decision in the Step 5 summary under "Codification Candidates" with Kind (`create` or `improve`), Shape = the routing target, and a `routed to <skill>` marker. For `ADR — supersede or amend`, include the `supersedes ADR-N` hint in the hand-off so create-adr produces the correct MADR header.

When the user chooses **Skip**, record the candidate in the Step 5 summary under "Codification Candidates" with a `skipped` marker so the pattern is still visible in the session audit trail.

**Non-interactive fallback (per ADR-013 Rule 6):** if `AskUserQuestion` is unavailable, record each candidate in the Step 5 summary under "Codification Candidates" with a `flagged — not actioned (non-interactive)` marker, noting the identified Kind alongside Shape (e.g. `Kind: improve, Shape: skill, flagged — not actioned (non-interactive)`). Do not create stubs, route to dedicated skills, or scaffold. The user can review the flags and decide when they return. Improvement candidates flagged this way retain the Target file and Observed flaw fields so the user has enough to act on without re-deriving the context.

**Backward compatibility**: "Skill" is retained as one shape among many so existing P044 muscle memory and `run-retro-skill-candidates.bats` continue to hold. Use the singular shape name in the summary (e.g. `Shape: skill`) so legacy greps still match. Improvement-axis rows use the same singular shape names (`Shape: skill, Kind: improve`) so the Shape column stays consistent across both axes.

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

### Verification Candidates

(Emitted only when Step 4a found `.verifying.md` tickets with specific in-session citations. Omit this section entirely when no candidates were found — or when the interactive path closed them all during Step 4a. Populated in non-interactive / AFK mode per ADR-013 Rule 6 — the user closes on return.)

| Ticket | Fix summary | In-session citations | Decision |
|--------|-------------|----------------------|----------|
| P<NNN> | <one-sentence fix summary> | <specific invocations + observable outcomes> | closed via manage-problem / left Verification Pending / flagged for manual review / flagged (non-interactive) |

### Codification Candidates

| Kind | Shape | Suggested name / Target file | Scope / Flaw | Triggers / Evidence | Decision |
|------|-------|-----------------------------|--------------|----------------------|----------|
| create  | skill | [suggested name] | [scope] | [examples] | created stub / routed to <skill> / skipped / flagged (non-interactive) |
| create  | agent | ... | ... | ... | ... |
| improve | skill | [target file path] | [observed flaw] | [1-3 session observations] | improvement stub / routed to <skill> / skipped / flagged (non-interactive) |
| improve | hook  | ... | ... | ... | ... |

### No Action Needed
- [learnings that were already captured]
```

The `Kind` column takes values `create` or `improve` — the create / improve axis defined in Step 2 and Step 4b. Creation rows use the `Suggested name` / `Scope` / `Triggers` field semantics; improvement rows reuse the same columns with `Target file` / `Observed flaw` / `Evidence` semantics (per the stub-recording guidance in Step 4b). The decision column carries the same vocabulary for both Kinds, with `improvement stub` replacing `created stub` for Kind=improve rows.

If the "Codification Candidates" table has no rows, omit it rather than rendering an empty header. The legacy "Skill Candidates" heading is preserved as a worked-example row in the Shape column so downstream tooling that grepped for "Skill Candidates" continues to find skill-shaped entries within the unified table.

$ARGUMENTS
