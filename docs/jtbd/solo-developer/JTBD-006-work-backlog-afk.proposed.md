---
status: proposed
job-id: work-backlog-afk
persona: solo-developer
date-created: 2026-04-17
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
- The loop stops gracefully when nothing actionable remains, or when it hits a blocker like a git conflict

## Persona Constraints

- Trusts the agent to make routine decisions (which problem next, auto-split, commit low-risk changes)
- Does not trust the agent to make judgment calls (verify fixes work, resolve ambiguous investigations, commit high-risk changes)
- Expects an audit trail — every action taken during AFK mode should be traceable via git history and the progress summary
- May be away for minutes or hours; the loop should be safe to run for extended periods

## Current Solutions

- Manually running `/wr-itil:manage-problem work` repeatedly
- Writing a bash script that calls `claude --print` in a loop (fragile, no progress visibility)
