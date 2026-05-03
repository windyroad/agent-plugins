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
- README content currency tracks code currency — adopters never read prose describing a prior release (per ADR-051: each `@windyroad/*` plugin README cites at least one current JTBD job ID; drift between README narrative and shipped behaviour is detectable via advisory script).

## Persona Constraints

- Works across multiple related projects (monorepo or sibling repos)
- Expects the agent to handle the mechanics after a release
- Does not want to manually track which plugins updated in which project
- Wants transparency — a clear report of before/after versions per project

## Current Solutions

- Manually running `claude plugin uninstall` + `claude plugin install` per plugin per project
- Relying on `claude plugin install` alone, which silently no-ops and leaves old code in place (P106)

## Related decisions

- **ADR-051** — `@windyroad/*` plugin READMEs anchor on JTBD job IDs with declarative drift advisory. Extends this job's currency scope from code-currency (the install pulled the latest code) to README-content-currency (the prose describes the latest behaviour). Both are dimensions of the same persona-level currency concern.
