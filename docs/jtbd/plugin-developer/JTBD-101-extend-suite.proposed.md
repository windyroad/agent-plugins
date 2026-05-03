---
status: proposed
job-id: extend-suite
persona: plugin-developer
date-created: 2026-04-14
---

# JTBD-101: Extend the Suite with New Plugins

## Job Statement

When I'm building a new plugin, I want to follow a clear template and have CI validate my package structure, so I know it will install correctly for users.

## Desired Outcomes

- Every plugin follows the same structure (package.json, plugin.json, hooks.json, install.mjs, BATS tests)
- CI validates required files, package fields, installer dry-runs, and hook tests
- Changesets handle versioning; the pipeline handles publishing
- ADRs document structural decisions so contributors understand the "why"
- Plugins that expose assessment agents also expose corresponding user-invocable assessment skills — the capability is discoverable via `/` autocomplete, not just accessible via hooks or manual Task-tool invocations
- I can see which of my plugin's surfaces (skills, agents, hooks) are most and least exercised in real-world use, so I know where to invest hardening effort versus where the surface is so well-trodden that the marginal-test ROI is low (P087 / ADR-053 / ADR-058 — surfaces this signal via the maturity-band taxonomy and the `wr-itil-skill-invocations` + `wr-itil-plugin-exercise-index` measurement scripts)

## Persona Constraints

- Must not break existing plugins when adding new ones
- Needs clear patterns, not reverse-engineering

## Current Solutions

Copy an existing plugin and modify it, read ADRs and BRIEFING.md
