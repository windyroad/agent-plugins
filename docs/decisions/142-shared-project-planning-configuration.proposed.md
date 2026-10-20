---
status: proposed
date: 2026-10-21
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2027-01-21
---

# Shared project planning configuration

## Context and Problem Statement

Planning currently remembers a GitHub Issues or local tracking choice with its plan. A new session or independently invoked contribution skill has no durable project preference to reuse. The user requested one project configuration shared by both skills rather than repeated questions.

## Decision Drivers

- Reuse an explicit project choice across sessions and independent skill invocations.
- Preserve optional local planning without a GitHub account or Project.
- Reuse existing project settings without replacing unrelated contributor configuration.
- Keep configuration declarative and separate from authentication and operational authority.

## Considered Options

1. **Shared declarative project configuration**: save and read the selected backend for both skills.
2. **Plan/session-only choice**: retain the existing behavior and require later sessions to rediscover the preference.

## Decision Outcome

Chosen option: **shared declarative project configuration**. Both skills read the project-declared configuration location, defaulting to `.agents/planning.json`. The version 1 object records `version: 1` and `backend: github` or `backend: local`. The optional `github` object can identify the selected repository and Project; existing contributor mappings remain project data, not a requirement for local mode.

When no choice is established, ask one question and wait for its answer. Save and read back the selection; later sessions reuse it. An existing explicit project or user choice need not be asked again before recording it. An explicit request to change the choice updates it. Preserve unrelated fields and other contributor mappings. Read-only use does not rewrite the file. Malformed, unsupported or ambiguous configuration is preserved while the necessary clarification is resolved.

Configuration names a tracking preference and intended mappings. It is parsed as data, never sourced as executable code, and proves neither authentication nor permission. Installers do not create adopter project configuration. Each skill resolves the same project setting during use; local mode has no GitHub prerequisite.

## Consequences

### Good

Users answer once per project and both independently usable skills share the result. Existing configuration and optional local planning remain usable.

### Neutral

The backend is agent-read guidance rather than an automatic tracker integration. The saved choice does not migrate existing plans or authorize issue mutations.

### Bad

A malformed or unsupported existing file needs correction or clarification before dependent tracking decisions; it cannot be silently replaced with a guessed default.

## Confirmation

Actual use in a project demonstrates one explicit choice being saved, then reused by planning and contribution sessions without another backend question. A requested change preserves unrelated settings. Local use needs no GitHub setup, and the saved GitHub preference does not grant additional authority. This proposal remains unconfirmed; synthetic checks, publication or user direction to implement alone do not establish final acceptance.

## Pros and Cons of the Options

### Shared declarative project configuration

Good because the preference survives session and skill boundaries; bad because the project must resolve a genuinely invalid saved configuration.

### Plan/session-only choice

Good because it adds no persistent file; bad because it fails the requested durable project behavior and can repeat a decision already made.

## Reassessment Criteria

Reassess if the two skills diverge on the saved choice, project settings are overwritten, configuration is mistaken for authority, or actual use cannot preserve local tracking without GitHub setup.
