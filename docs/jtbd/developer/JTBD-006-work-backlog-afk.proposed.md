---
status: proposed
job-id: work-backlog-afk
persona: developer
date-created: 2026-04-17
human-oversight: confirmed
oversight-date: 2026-08-29
oversight-confirmed-date: "2026-07-27 — re-ratified via the P357 brief AskUserQuestion this session; the ADR-101 lockstep narrowing (bounded AFK-accept carve-out for pure decomposition of already-confirmed substance; verification untouched; opt-in) confirmed in the same batch as ADR-101. SUPERSEDED — see oversight-downgraded below."
oversight-confirmed-date-2026-08-29: "2026-08-29 — re-ratified after the exact current JTBD-006 artefact was opened and presented; the user explicitly responded 'ratified'."
oversight-downgraded: "2026-08-21 — ADR-103 lockstep (material amendment per ADR-068), surfaced by the P508 slice-A JTBD gate. The ADR-101 amendment below conditions unattended acceptance on 'where the project has opted in'; ADR-103 superseded ADR-101 outright on 2026-08-07, dropped that opt-in protection knowingly, and removed the machinery — the config key survives only in a changelog. P508 slice A makes the staleness bind rather than merely sit there: the I13 gate now draws a release row and inherits map approval on every untraced Known Error, at the AFK surface, unconditionally. This is the job a reviewer opens to answer 'may the loop do this unattended?', and it currently answers with a precondition nobody can satisfy. Marker held until re-ratified at the next interactive /wr-jtbd:confirm-jobs-and-personas drain (ADR-066 P348 AFK fallback — no AskUserQuestion was available in the salvage session that wrote this)."
oversight-downgraded-2026-08-24: "2026-08-24 — P519 lockstep (material amendment per ADR-068): the Persona Constraint \"does not trust the agent to verify fixes work\" is NARROWED to \"does not trust the agent to decide a fix works where no evidence is available\". Six shipped skills now cite this job as the authority for agent-authorised Verification Pending -> Closed on cited evidence. The reservation it replaces was corpus residue: ADR-044 (confirmed) already ratified close-on-evidence as a framework-mediated surface, and review-problems Bucket 1 + run-retro Step 4a had worked that way since P135/P186. Driven by a 2026-08-24 user correction — direction, NOT substance ratification per CLAUDE.md P357. Marker held until re-ratified at the next interactive /wr-jtbd:confirm-jobs-and-personas drain."
oversight-downgraded-2026-07-26: "2026-07-26 — ADR-101 lockstep (material amendment per ADR-068): the Desired Outcome 'Problems requiring my judgment are queued for my return, not guessed at' is NARROWED by a bounded AFK-accept carve-out for pure decomposition of already-confirmed substance. Marker held until re-ratified; re-ratification queued with ADR-101's owed post-draft brief (P456 open items)."
---

# JTBD-006: Progress the Backlog While I'm Away

## Job Statement

When I step away from the keyboard, I want the agent to autonomously work through my prioritised problem backlog, so progress continues without me being present.

## Desired Outcomes

- The agent works problems in WSJF priority order without needing interactive input
- Decisions that would normally require my input are resolved using safe defaults (e.g., auto-split multi-concern tickets, ~~skip problems needing verification~~ skip problems needing verification **for which no evidence is available** — amended 2026-08-24 per P519, see the persona-constraint amendment below)
- Scope expansion is handled conservatively — save findings and move to the next problem rather than sinking unbounded effort
- When I return, I can see a clear summary of what was worked, what was skipped, and what remains
- Problems requiring my judgment — contested evidence, a fix that covers only part of the ticket, scope decisions, ambiguous investigation — are queued for my return, not guessed at. A fix whose verification is settled by evidence the agent can cite is not a judgment call: the agent closes it and records the evidence. **Absence of evidence is not evidence** — the agent never closes on inference, so a fix nobody exercised stays open however old it is.
  - **Amendment 2026-07-26 (ADR-101).** One bounded exception, and it is not a licence to guess. ~~Where the project has opted in,~~ the loop may accept and implement a story that only **decomposes substance I already confirmed** — every decision, job, persona and map it draws on carries my confirmation, and each of its acceptance criteria names the confirmed clause it decomposes. Anything introducing a new design choice, persona, job or decision is still queued for my return, and ~~**verification is untouched** — the loop still never decides that a fix works~~ **the loop still never decides that a fix works from anything other than cited evidence** (amended 2026-08-24 per P519 — see the note below). This exists because the gate it relaxes was not slowing the loop down, it was stopping it: ratification had no unattended path at all, so an iteration could author governance artefacts and nothing else. Three witnesses are recorded on P456 and five more in the cross-session briefing, including a three-line fix that could not land.
  - **SUPERSEDED 2026-08-07 by ADR-103 — do not read the opt-in qualifier above as current.** ADR-103 supersedes ADR-101 outright and drops the opt-in gate knowingly: the carve-out applies unconditionally, and the machinery behind the config key was removed with it. What still bounds the loop is unchanged and is the part to read — anything introducing a new design choice, persona, job or decision is queued, and ~~verification is untouched~~ verification closes only on cited evidence (amended 2026-08-24 per P519). The authoritative drift basis is the `SUBSTANCE` tuple in `packages/itil/lib/story-oversight.sh`, not prose here. Struck rather than deleted so the witness survives: this stale precondition is one a reviewer can satisfy nowhere, and P508 records the same stale-text class producing a false blocking objection once already.
- Git commits happen automatically when risk is within appetite; uncommitted work is reported transparently when risk is above appetite
- Between iterations, the loop drains push/release queues when unreleased risk would reach appetite, so risk never silently accumulates across AFK iterations (see ADR-018)
- Before each iteration, the loop reconciles working-tree state with origin per ADR-019's three-branch clean-state preflight: trivial fast-forward divergence pulls non-interactively (Branch 1); prior-session in-flight work is recoverable as a distinct preflight commit when provenance is unambiguous and risk is within appetite (Branch 2 — deferred to a follow-up; current implementation conservatively routes to Branch 3); ambiguously-dirty tree or non-fast-forward divergence halts the loop with a structured Prior-Session State report (Branch 3 — interactive: `AskUserQuestion`; AFK: halt-with-report carve-out from the 2026-06-06 Rule 6 queue-and-continue default). See ADR-019.
- Before opening the work loop, the orchestrator checks whether the upstream inbound-discovery cache is fresh; stale-cache or missing-cache auto-promotes `/wr-itil:review-problems` as a pre-flight pass so upstream-reported problems stay visible to the loop without the maintainer remembering to invoke review-problems first (see ADR-062 § Decision Drivers + work-problems Step 0b)
- Next-ID assignment is verified against `origin/<base>` before any new ticket (problem, ADR, JTBD) is created, preventing collisions with parallel sessions (see ADR-019)
- The loop stops gracefully when nothing actionable remains, or when it hits a blocker like a git conflict

## Persona Constraints

- Trusts the agent to make routine decisions (which problem next, auto-split, commit low-risk changes)
- Does not trust the agent to make judgment calls (resolve ambiguous investigations, commit high-risk changes, ~~verify fixes work~~ decide a fix works where no evidence is available)

  - **Amendment 2026-08-24 (P519).** The original wording read "verify fixes work" without qualification, and four shipped skills implemented it as a hard reservation: the Verification Pending → Closed transition was the maintainer's alone. The result was a queue with no agent-driven exit path — 153 verifying tickets, exactly one carrying a populated evidence cell, and an agent that would find in-session proof a fix worked and still decline to act on it. The constraint that was actually wanted is narrower and is preserved intact: **the agent must not decide a fix works when it cannot point at evidence.** Where it can point at evidence meeting the ticket's own close criterion, closing is a field read, not a judgment call, and it closes — reversibly, citing what it saw. Contested evidence, partial fixes, and any ticket carrying a recorded do-not-close marker stay on my surface. Two shipped surfaces (`review-problems` Bucket 1 and `run-retro` Step 4a) had already worked this way since P135/P186; the reservation in the other four was residue that outlived them.
- Expects an audit trail — every action taken during AFK mode should be traceable via git history and the progress summary
- May be away for minutes or hours; the loop should be safe to run for extended periods

## Current Solutions

- Manually running `/wr-itil:manage-problem work` repeatedly
- Writing a bash script that calls `claude --print` in a loop (fragile, no progress visibility)
## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Take a problem from noticed to resolved | draft |
| STORY-MAP-004 | STORY-MAP-004: Close the loop with someone who reported a problem | draft |
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
| STORY-MAP-001 | STORY-MAP-001: RFC framework Phase 1 + Phase 2 bootstrap | in-progress |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-047 | STORY-047: Gate the correction nudge on prompt authorship | accepted |
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
| STORY-065 | STORY-065: A fix proposal draws a release row, not a document | accepted |
| STORY-066 | STORY-066: A fix I can prove works gets closed without me | accepted |
| STORY-003 | STORY-003: /wr-itil:list-stories read-only display skill | done |
| STORY-005 | STORY-005: Working-the-problem traversal rewrite (manage-problem + work-problem) | done |
| STORY-018 | STORY-018: Capture the problem in seconds, mid-flow | done |
| STORY-026 | STORY-026: Work the RFC's stories one at a time | done |
| STORY-014 | STORY-014: Unattended, the agent works the plan and pauses for real decisions | draft |
| STORY-036 | STORY-036: Write the create-gate marker under every candidate session id | draft |
| STORY-038 | STORY-038: Fix-titled commits surface a lifecycle-drift advisory | draft |
| STORY-040 | STORY-040: AFK loop anchored with the native `/goal` external evaluator | draft |
| STORY-048 | STORY-048: Gate the inbound-discovery pre-flight on the channel list | draft |
| STORY-052 | STORY-052: Surface still-outstanding family members before a close | draft |
| STORY-053 | STORY-053: Test claims against the tree at capture and label the untested ones | draft |
| STORY-059 | STORY-059: See why the loop did not work what I expected | draft |
| STORY-060 | STORY-060: Pick up a captured ticket and know what was observed | draft |
| STORY-064 | STORY-064: A ticket that only names a decision as background stays open | draft |
| STORY-071 | STORY-071: Review the complete commit message once | draft |
| STORY-062 | STORY-062: Keep problem ranking correct after a status transition | in-progress |
| STORY-069 | STORY-069: Drain one Codex ticket through an isolated Codex CLI | in-progress |
| STORY-070 | STORY-070: Leave the Codex backlog draining until no dispatchable work remains | in-progress |
