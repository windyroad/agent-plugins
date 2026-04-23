---
status: proposed
job-id: keep-plugins-current
persona: solo-developer
date-created: 2026-04-23
---

# JTBD-007: Keep Plugins Current Across Projects

## Job Statement

When I ship a new version of a plugin I depend on, I want every active project to pick up the latest code reliably, so I don't waste time debugging behaviour that was already fixed in the latest release.

## Desired Outcomes

- One command refreshes all enabled plugins in the current project and its siblings
- Plugin updates land reliably without silent no-ops — the refresh mechanism actually fetches the latest marketplace version
- No manual per-project reinstall is required
- The refresh is gated by consent when side effects touch sibling projects
- The process reports what changed, what stayed the same, and what failed
- Restarting Claude Code is surfaced as the final step so the new code is loaded

## Persona Constraints

- Works across multiple related projects (monorepo or sibling repos)
- Expects the agent to handle the mechanics after a release
- Does not want to manually track which plugins updated in which project
- Wants transparency — a clear report of before/after versions per project

## Current Solutions

- Manually running `claude plugin uninstall` + `claude plugin install` per plugin per project
- Relying on `claude plugin install` alone, which silently no-ops and leaves old code in place (P106)
