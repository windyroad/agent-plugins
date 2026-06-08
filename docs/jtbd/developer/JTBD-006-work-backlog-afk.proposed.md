---
status: proposed
job-id: work-backlog-afk
persona: developer
date-created: 2026-04-17
human-oversight: confirmed
oversight-date: 2026-05-31
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
