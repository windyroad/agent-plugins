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
- **Test fixture** — regression test for a recurring failure pattern (bats fixture, unit test). Best fit when the observation is "this kept breaking the same way".
- **Memory** — per-user or per-project memory note in `~/.claude/.../memory/`. Best fit for short, user-habit observations that aren't a codifiable sequence (e.g. "I always forget to run `npm run verify` before pushing").

**Note (P075)**: the shape list enumerates **codification outputs** — not ticketing. Every codifiable observation becomes a problem ticket in Step 4b Stage 1 regardless of shape. The shape choice is recorded as the ticket's proposed fix strategy (Stage 2), not as an alternative to ticketing. The legacy `Problem ticket` shape row has been removed; it represented a foregone decision (every observation is ticket-worthy) that is now mechanical in Stage 1.

If no shape fits — the observation is a one-off learning, not a repeating pattern — it belongs in BRIEFING.md (Step 3), not Step 4b.

Counter-examples (what does **not** become a codification candidate):
- "The commit gate rejected my work twice because X was misconfigured" — diagnostic, project-specific. Still flows through Step 4b Stage 1 ticketing; the fix strategy (Stage 2) is captured as free-text under `Other codification shape` (e.g. hook tweak, script adjustment).
- "I always forget to run `npm run verify` before pushing" — short, user-habit rather than codifiable sequence → **memory** shape or **BRIEFING.md** note.

### 2b. Pipeline-instability scan (P074)

Step 2's reflection prompts are framed around the product-code work the session was trying to do. They under-report **pipeline-level instability** — bugs, regressions, or friction in the tools the session itself relied on (hooks, skills, subagent protocols, release scripts, TTL / marker contracts). Agents read the prompts and list "what I was trying to build" instead of "what was in the way of building it". Step 2b is a dedicated evidence-scan step that recovers those observations before Step 4's ticketing flow fires, so pipeline friction reaches the WSJF queue instead of accumulating off-ledger across sessions.

The shape mirrors P068's Step 4a Verification-close housekeeping: glob / evidence-scan / categorise / dedup / prompt. The ownership boundary is the same — run-retro surfaces the detection and delegates ticket creation to `/wr-itil:manage-problem` via the Skill tool; run-retro does not rename, edit, or commit problem-ticket files on its own (per ADR-014).

**Ownership boundary**: run-retro surfaces the detection and its specific citations; `/wr-itil:manage-problem` creates or updates the ticket and commits per ADR-014. run-retro does not write `.open.md` files directly — it delegates through the ticketing skill so the audit trail, WSJF scoring, and concern-boundary analysis all apply consistently. This matches Step 4a's boundary to manage-problem Step 7 and Step 4b Stage 1's boundary to manage-problem creation.

**Signal categories** — each detection is tagged with the primary category. A detection may match multiple categories; pick the one whose fix path is most concrete.

1. **Hook-protocol friction** — gate-marker TTL expiries mid-work (e.g. architect-hook 1800s TTL per ADR-009 expiring while drafting a long file), marker-vs-file deadlocks (a gate demands PASS before a Write; the agent refuses to PASS on a file that doesn't exist yet), hook-exemption scope gaps, hooks firing on paths they shouldn't, hooks silently skipping paths they should.
2. **Skill-contract violations** — skill steps that collide (e.g. ADR-027 Step 0 colliding with ADR-031 auto-migration Step 0), skills that return empty on paths they should handle (e.g. work-problems false-zero-bail on flat-layout adopter repos), skills whose AskUserQuestion options exceed the 4-option cap (per P061), skills that silently swallow error states the contract says should halt.
3. **Release-path instability** — `push:watch` / `release:watch` misbehaviour (P054, P060 class — reporting success on a stale SHA's workflow run), changeset authoring defects (P073), release-PR body issues, npm publish failing on metadata mismatch.
4. **Subagent-delegation friction** — architect / jtbd / risk-scorer / style-guide / voice-tone agents returning `DEFERRED` or `ISSUES FOUND` that block progress, PASS markers failing to write, agent prompts timing out, agent outputs missing the specific citations ADR-026 requires.
5. **Repeat-work friction** — the same workaround applied ≥ 3 times in one session (each application is signal; the third triggers a ticket candidate). Includes: the same `git add` re-stage after `git mv` (P057), the same marker-refresh pattern after an agent returns DEFERRED, the same hook-bypass incantation.
6. **Session-wrap silent drops** — cases where run-retro itself under-reports (the meta case this step fixes). Detect by comparing the set of `## Fix Released` updates in this session against the set of observations in the retro summary; a `.verifying.md` rename without a matching retro entry is suspect.

**Steps:**

1. **Glob / scan**: walk session history for signal matches from each category above. Candidate patterns to search:
   - Hook TTL expiry → log lines containing `review expired (Ns old, TTL Ms)`, `marker refresh`, `PreToolUse hook blocking error`.
   - Marker-vs-file deadlock → sequences where a Write was blocked, an agent was invoked for the marker, and the agent returned `DEFERRED` or similar non-PASS.
   - `push:watch` / `release:watch` failures → non-zero exits on those scripts, or observable SHA-mismatch in `gh run list` output.
   - Subagent DEFERRED / ISSUES FOUND that blocked progress → agent outputs matching those markers.
   - Repeat workaround → the same `Bash` command pattern appearing ≥ 3 times with the same outcome.

2. **Evidence-scan grounding (ADR-026)**: every detected signal MUST carry specific citations — the tool invocation (command or agent call), a session position marker (turn number, timestamp, or commit SHA), and the observable outcome (exit status, error message, marker content). Bare "pipeline was flaky this session" does not qualify. An example acceptable citation: *"architect hook TTL expired at turn N while drafting `docs/decisions/031-…proposed.md` (log line `review expired (1814s old, TTL 1800s)`), forcing a marker-refresh round-trip"*. If no specific citation can be produced, the detection is NOT logged — false positives are worse than silent drops here because each false positive produces a ticket.

3. **Categorise**: tag each detection with its primary category from the six above.

4. **Dedup against existing tickets**: for each detection, search `docs/problems/*.open.md` and `docs/problems/*.known-error.md` for tickets whose description or symptoms match the detection's category + signal pattern. If a matching ticket exists: route the detection through Step 4 as an **update** (append new evidence to the existing ticket's `## Symptoms` or `## Root Cause Analysis` section via the manage-problem update path). If no match: route as a **new ticket** with the detection's category, citations, and a suggested title. The matching heuristic is category + signal-pattern keyword overlap — LLM-based dup classification (as discussed in P070) is not required here; local-ticket dedup runs against a small enough corpus that keyword overlap on the category + primary signal word is acceptable.

5. **Interactive path (ADR-013 Rule 1)**: for each detection, invoke `AskUserQuestion` with the detection summary + specific citations inline so the user can decide without reading session logs. Options (exactly four, per ADR-013 Rule 1 cap):
   1. `Create new ticket` — description: "Delegate to /wr-itil:manage-problem to create a problem ticket with the detection's category, citations, and suggested title."
   2. `Append to P<NNN>` — description: "An existing ticket covers this signal; delegate to /wr-itil:manage-problem to append new evidence to its Root Cause Analysis section."
   3. `Record in retro report only (not ticket-worthy)` — description: "The detection is session-local friction that does not warrant a persistent ticket; record it in the Pipeline Instability section of the retro summary only."
   4. `Skip — false positive` — description: "The evidence-scan matched on a false positive; the observed behaviour was correct. Do not record."

6. **Non-interactive / AFK fallback (ADR-013 Rule 6)**: when `AskUserQuestion` is unavailable (autonomous retro, batch session-wrap), do NOT auto-create tickets — record each detection in the retro summary's new **Pipeline Instability** section with its category, citations, and dedup status (`new` or `matches P<NNN>`). The user reviews on return and runs `/wr-itil:manage-problem` per accepted detection. Same trust-boundary shape as Step 4a's AFK deferral: surface the evidence, defer the decision. This matches the user's documented preference (feedback_verify_from_own_observation.md memory): surface observations from the agent's own in-session activity, but ticket-creation decisions remain user-confirmed.

**Interaction with other surfaces:**

- **Step 4a (Verification-close housekeeping, P068)** — same evidence-scan shape applied to a different surface. Both share the glob / scan / categorise / specific-citation / interactive-or-AFK pattern. Step 4a scans for successful exercise of `.verifying.md` fixes; Step 2b scans for tool-level friction. They fire independently and produce independent retro-summary sections.
- **Step 4 (problem-ticket creation)** — Step 2b feeds Step 4. A detection surfaced in Step 2b that the user accepts becomes a Step 4 creation or update via the manage-problem delegation. Step 4b's Stage 1 two-stage codification flow (P075) applies to pipeline-instability tickets the same way it applies to Step 2 reflection tickets — the detection IS the codify-worthy observation.
- **ADR-027 compatibility note**: when ADR-027's Step-0 auto-delegation lands on run-retro, Step 2b's evidence scan is load-bearing on main-agent session context that a delegated subagent does not automatically inherit. The migration path mirrors Step 4a's: either (a) run Step 2b in the main-agent context BEFORE Step-0 delegation to the subagent, or (b) include an explicit session-activity summary (tool invocations, commits, skill calls observed in main-agent context) in the Step-0 delegation prompt. Option (a) is preferred to keep the evidence scan close to the observed activity.

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

### 4b. Two-stage codification — ticket first, fix strategy second (P075)

Every codification candidate identified in Step 2 flows through a **two-stage flow**. Stage 1 is mechanical — every candidate becomes a problem ticket; ticketing is not a user decision. Stage 2 is a per-ticket `AskUserQuestion` recording the **proposed fix strategy** as the codification shape.

**User rationale (P075)**: the legacy 19-option flat list presented a ticket-this-or-pick-another-shape choice as one option among many, but in practice the ticketing axis has a foregone answer — every codify-worthy observation is also problem-worthy. Re-asking the ticketing question is redundant. Flipping the flow collapses the redundant decision: ticket first (mechanical), fix strategy second (user-interactive).

**Skill candidate / Codification candidate backward compatibility**: the legacy `Skill candidate` and `Codification candidate` AskUserQuestion headers are superseded by Stage 2's `Proposed fix` header. The P044 / P050 / P051 enforcement intents are preserved — they now ride in Stage 2 Options 1–3 on a per-ticket basis rather than as one option among many for a single batch prompt.

#### Stage 1: Ticket every codify-worthy observation (mechanical — no user decision)

For every codifiable observation identified in Step 2:

1. **Apply P016 concern-boundary analysis**: if the observation covers multiple independent concerns, split into N observations before ticketing. One ticket per concern.
2. **Invoke `/wr-itil:manage-problem`** via the Skill tool to create a problem ticket. The observation text becomes the ticket Description; the retro narrative populates the Root Cause Analysis; the `## Related` section cites this retro run. (Once the ADR-032 `capture-*` background sibling ships for manage-problem, Stage 1 can delegate to `/wr-itil:capture-problem` instead so ticketing runs out of the foreground turn; same contract, different invocation mode.)

**ADR-032 note**: Stage 1 is a legitimate **foreground-spawns-N-background fanout** pattern — run-retro's foreground context spawns one background capture invocation per observation (when the background sibling exists). ADR-032's Confirmation section must carry this case; cite `ADR-032` (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) explicitly when the background path lands.

**Ownership boundary** (same as Step 4a): run-retro surfaces the observation and delegates ticket creation to `/wr-itil:manage-problem`. The delegated skill renames, edits, and commits per ADR-014. run-retro does not commit its own work.

**Non-interactive / AFK branch**: Stage 1 fires regardless — ticketing is mechanical and does not require user input. If the delegated skill itself is unavailable (e.g. the Skill tool is gated out of the current context), record the observation in the retro summary's "Tickets Deferred" section so the user can ticket on return. Do NOT skip recording the observation.

#### Stage 2: Record proposed fix strategy on each ticket (user-interactive — per ticket)

For each ticket created in Stage 1, invoke `AskUserQuestion` to record the proposed codification shape as the fix strategy. This is a per-ticket interaction — the fix-shape judgement is ticket-specific, not a single batch decision.

For each ticket:
- `header: "Proposed fix"`
- `multiSelect: false`
- Options (exactly four top-level per ADR-013 Rule 1 cap; architect Q4 lean (b): free-text capture for multi-shape cases, not cascading AskUserQuestion batches — cascading fan-outs are the P061 anti-pattern):
  1. `Skill — create stub` — description: "Record a stub for a new skill (suggested name, scope, triggers, prior uses) on the ticket's `## Fix Strategy` section. Skill scaffolding itself remains out of scope for the retrospective."
  2. `Skill — improvement stub` — description: "Record a targeted edit to an existing skill's SKILL.md (target file, observed flaw, edit summary) on the ticket's `## Fix Strategy` section."
  3. `Other codification shape` — description: "Capture the fix shape as **free-text** on the ticket's `## Fix Strategy` section. Covers agent / hook / settings / script / CI / ADR / JTBD / guide / test fixture / memory / internal code change. Include the shape name, suggested stub details, and routing target where applicable (e.g. `/wr-architect:create-adr` for ADR; `/wr-jtbd:update-guide` for JTBD; `/wr-voice-tone:update-guide` for voice)."
  4. `Self-contained work — no codification stub` — description: "The ticket is a bounded one-shot edit with no recurring-pattern signal. **Rule 6 audit note**: this option is valid only when the observation is a bounded one-shot edit with no recurring-pattern signal. It is NOT a silent-skip escape hatch — if any recurring-pattern signal is present, pick Option 1/2/3 instead so P044's recommend-skills intent is preserved."

**Recording**: append a `## Fix Strategy` section to the ticket (or edit the existing section if present). The section records the chosen Option, the shape, and the stub fields (for Options 1–2 the stub template; for Option 3 the free-text fix shape; for Option 4 the bounded-one-shot reason). The fix strategy lives on the ticket — not in the retro summary — so it travels with the problem through its lifecycle.

**Non-interactive / AFK branch (ADR-013 Rule 6 + ADR-032 deferred-question contract)**: When `AskUserQuestion` is unavailable, Stage 2 defers via the ADR-032 **deferred-question artefact** — each ticket gets a pending-question entry asking for the proposed fix strategy; the main agent surfaces the questions on the next interactive session. Stage 2 does NOT fabricate a fix-strategy choice in AFK mode; the ticket lives without a `## Fix Strategy` section until the user answers. ADR-032's FIFO concurrency handling applies: N pending questions (one per Stage 1 ticket) queue in serial order.

#### Stub templates by Option

When Stage 2 selects Option 1 (`Skill — create stub`), write the following into the ticket's `## Fix Strategy` section:

- **Kind** — `create`
- **Shape** — `skill`
- **Suggested name** — `wr-<plugin>:<verb>-<object>` per ADR-010 amended skill-granularity rule.
- **Scope** — one sentence on what the skill does and when it should fire.
- **Triggers** — 2-3 example user prompts or events.
- **Prior uses** — 2-3 observed invocations from this session.

When Stage 2 selects Option 2 (`Skill — improvement stub`), write:

- **Kind** — `improve`
- **Shape** — `skill`
- **Target file** — existing SKILL.md path (e.g. `packages/itil/skills/manage-problem/SKILL.md`).
- **Observed flaw** — one sentence.
- **Edit summary** — one sentence describing the targeted edit.
- **Evidence** — 1-3 session observations showing the flaw.

When Stage 2 selects Option 3 (`Other codification shape`), write free-text on the ticket's `## Fix Strategy` section including: the codification shape (agent / hook / settings / script / CI / ADR / JTBD / guide / test fixture / memory / internal code), a suggested stub (`Suggested name:` / `Target file:` / `Event + trigger:` as fits the shape), the routing target skill (`/wr-architect:create-adr`, `/wr-jtbd:update-guide`, `/wr-voice-tone:update-guide`, `/wr-style-guide:update-guide`, `/wr-risk-scorer:update-policy`), and 1-3 session observations. Free-text capture keeps the ADR-013 Rule 1 4-option cap intact without cascading follow-up batches (architect Q4 lean (b); P061 anti-pattern avoided).

When Stage 2 selects Option 4 (`Self-contained work — no codification stub`), write a single-line note: "Self-contained work — bounded one-shot edit, no recurring-pattern signal observed this session." The `## Fix Strategy` section records the Option 4 choice so future sessions know codification was considered and deferred with cause.

#### Interaction with P044 / P050 / P051 / P068 / P074

- **P044** (recommend new skills) — Stage 2 Option 1 (`Skill — create stub`) carries P044's enforcement intent. P044's AFK recommend-skills semantics migrate to the deferred-question fallback (Stage 2 defers per ticket in AFK).
- **P050** (recommend other codifiables) — Stage 2 Option 3 (`Other codification shape`) carries P050's shape-generalisation into free-text capture.
- **P051** (improvement axis) — Stage 2 Option 2 (`Skill — improvement stub`) carries P051's improvement axis for skill shape; non-skill improvements ride in Option 3's free-text capture with an explicit `improve` marker.
- **P068** (verification-close housekeeping) — unaffected. Step 4a stays as-is, independent of Step 4b's restructure.
- **P074** (pipeline-instability scan) — when P074 ships its Step 2b, detected instability signals feed Stage 1 as additional ticket sources. The ticket-first flow is the natural common funnel P074's RCA identifies.

#### Coordinating-ticket rule

If a single target output accumulates ≥ 3 improvement observations in one session, Stage 1 should create **one coordinating ticket** scoped as "apply N improvements to <target>" rather than N separate tickets. Stage 2 on that ticket picks Option 2 (for skill-shape targets) or Option 3 with the coordinating-ticket free-text. This reduces ticket churn and keeps the affected output's improvement queue coherent.

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

### Pipeline Instability

(Emitted only when Step 2b detected pipeline-level friction with specific citations. Omit this section entirely when no detections were made — or when the interactive path ticketed or dismissed them all during Step 2b. Populated in non-interactive / AFK mode per ADR-013 Rule 6 — the user reviews on return and tickets via `/wr-itil:manage-problem` per accepted detection.)

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| <one-line signal summary> | Hook-protocol friction / Skill-contract violations / Release-path instability / Subagent-delegation friction / Repeat-work friction / Session-wrap silent drops | <specific invocations + session-position markers + observable outcomes> | new ticket via manage-problem / appended to P<NNN> / recorded in retro only / skipped (false positive) / flagged (non-interactive) |

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
