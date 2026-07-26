---
status: proposed
job-id: work-backlog-afk
persona: developer
date-created: 2026-04-17
human-oversight: confirmed
oversight-date: 2026-05-31
oversight-confirmed-date: "2026-07-27 — re-ratified via the P357 brief AskUserQuestion this session; the ADR-101 lockstep narrowing (bounded AFK-accept carve-out for pure decomposition of already-confirmed substance; verification untouched; opt-in) confirmed in the same batch as ADR-101."
oversight-downgraded: "2026-07-26 — ADR-101 lockstep (material amendment per ADR-068): the Desired Outcome 'Problems requiring my judgment are queued for my return, not guessed at' is NARROWED by a bounded AFK-accept carve-out for pure decomposition of already-confirmed substance. Marker held until re-ratified; re-ratification queued with ADR-101's owed post-draft brief (P456 open items)."
---

# JTBD-006: Progress the Backlog While I'm Away

## Job Statement

When I step away from the keyboard, I want the agent to autonomously work through my prioritised problem backlog, so progress continues without me being present.

## Desired Outcomes

- The agent works problems in WSJF priority order without needing interactive input
- Decisions that would normally require my input are resolved using safe defaults (e.g., auto-split multi-concern tickets, skip problems needing verification)
- Scope expansion is handled conservatively — save findings and move to the next problem rather than sinking unbounded effort
- When I return, I can see a clear summary of what was worked, what was skipped, and what remains
- Problems requiring my judgment (verification, scope decisions, ambiguous investigation) are queued for my return, not guessed at
  - **Amendment 2026-07-26 (ADR-101).** One bounded exception, and it is not a licence to guess. Where the project has opted in, the loop may accept and implement a story that only **decomposes substance I already confirmed** — every decision, job, persona and map it draws on carries my confirmation, and each of its acceptance criteria names the confirmed clause it decomposes. Anything introducing a new design choice, persona, job or decision is still queued for my return, and **verification is untouched** — the loop still never decides that a fix works. This exists because the gate it relaxes was not slowing the loop down, it was stopping it: ratification had no unattended path at all, so an iteration could author governance artefacts and nothing else. Three witnesses are recorded on P456 and five more in the cross-session briefing, including a three-line fix that could not land.
- Git commits happen automatically when risk is within appetite; uncommitted work is reported transparently when risk is above appetite
- Between iterations, the loop drains push/release queues when unreleased risk would reach appetite, so risk never silently accumulates across AFK iterations (see ADR-018)
- Before each iteration, the loop reconciles working-tree state with origin per ADR-019's three-branch clean-state preflight: trivial fast-forward divergence pulls non-interactively (Branch 1); prior-session in-flight work is recoverable as a distinct preflight commit when provenance is unambiguous and risk is within appetite (Branch 2 — deferred to a follow-up; current implementation conservatively routes to Branch 3); ambiguously-dirty tree or non-fast-forward divergence halts the loop with a structured Prior-Session State report (Branch 3 — interactive: `AskUserQuestion`; AFK: halt-with-report carve-out from the 2026-06-06 Rule 6 queue-and-continue default). See ADR-019.
- Before opening the work loop, the orchestrator checks whether the upstream inbound-discovery cache is fresh; stale-cache or missing-cache auto-promotes `/wr-itil:review-problems` as a pre-flight pass so upstream-reported problems stay visible to the loop without the maintainer remembering to invoke review-problems first (see ADR-062 § Decision Drivers + work-problems Step 0b)
- Next-ID assignment is verified against `origin/<base>` before any new ticket (problem, ADR, JTBD) is created, preventing collisions with parallel sessions (see ADR-019)
- The loop stops gracefully when nothing actionable remains, or when it hits a blocker like a git conflict

## Persona Constraints

- Trusts the agent to make routine decisions (which problem next, auto-split, commit low-risk changes)
- Does not trust the agent to make judgment calls (verify fixes work, resolve ambiguous investigations, commit high-risk changes)
- Expects an audit trail — every action taken during AFK mode should be traceable via git history and the progress summary
- May be away for minutes or hours; the loop should be safe to run for extended periods

## Current Solutions

- Manually running `/wr-itil:manage-problem work` repeatedly
- Writing a bash script that calls `claude --print` in a loop (fragile, no progress visibility)
## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Decompose a Fix Into Coordinated Changes | draft |
| STORY-MAP-005 | STORY-MAP-005: Trust the capture-on-correction signal | draft |
| STORY-MAP-006 | STORY-MAP-006: Decline upstream discovery once and stay declined | draft |
| STORY-MAP-009 | STORY-MAP-009: Trust that a close does not strand the sibling family | draft |
| STORY-MAP-001 | STORY-MAP-001: RFC Framework Phase 1 + Phase 2 Bootstrap | in-progress |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-003 | STORY-003: /wr-itil:list-stories read-only display skill | done |
| STORY-005 | STORY-005: Working-the-problem traversal rewrite (manage-problem + work-problem) | done |
| STORY-014 | STORY-014: Unattended, the agent works the plan and pauses for real decisions | draft |
| STORY-018 | STORY-018: Capture the problem in seconds, mid-flow | done |
| STORY-026 | STORY-026: Work the RFC's stories one at a time | done |
| STORY-036 | STORY-036: Write the create-gate marker under every candidate session id | draft |
| STORY-038 | STORY-038: Fix-titled commits surface a lifecycle-drift advisory | draft |
| STORY-040 | STORY-040: AFK loop anchored with the native `/goal` external evaluator | draft |
| STORY-047 | STORY-047: Gate the correction nudge on prompt authorship | draft |
| STORY-048 | STORY-048: Gate the inbound-discovery pre-flight on the channel list | draft |
| STORY-052 | STORY-052: Surface still-outstanding family members before a close | draft |
| STORY-053 | STORY-053: Test claims against the tree at capture and label the untested ones | draft |
