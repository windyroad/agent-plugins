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

## Persona Constraints

- Must not break existing plugins when adding new ones
- Needs clear patterns, not reverse-engineering

## Current Solutions

Copy an existing plugin and modify it, read ADRs and BRIEFING.md
