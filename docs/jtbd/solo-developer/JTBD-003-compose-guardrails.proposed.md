---
status: proposed
job-id: compose-guardrails
persona: solo-developer
date-created: 2026-04-14
---

# JTBD-003: Compose Only the Guardrails I Need

## Job Statement

When I only need architecture and TDD enforcement, I want to install just those two plugins, so my session isn't cluttered with hooks that don't apply to my project.

## Desired Outcomes

- Each plugin is independently installable via `npx @windyroad/<name>`
- Installing a subset does not degrade the experience for installed plugins
- The meta-installer supports selective install via `--plugin` flag

## Persona Constraints

- May install only 2-3 plugins relevant to their project

## Current Solutions

Install everything and ignore irrelevant hooks, or don't install at all
