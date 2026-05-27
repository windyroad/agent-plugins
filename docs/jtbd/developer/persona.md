---
name: developer
description: Developer using AI coding agents — solo, small-team, or within a larger software development team
human-oversight: confirmed
oversight-date: 2026-05-27
---

# Developer

## Who

Uses AI coding agents (Claude Code) to do hands-on software development — working solo, in a small team, or within a larger software development team. Moves fast, ships often. May be working across multiple repos simultaneously.

The distinguishing axis is **role**, not team size: this is the developer who *does the work*, as opposed to `tech-lead` (the governance / quality-enforcement role). The persona's jobs apply to a developer on a team of any size.

## Context Constraints

- Wants speed without sacrificing quality
- May install only 2-3 plugins relevant to their project
- Owns the work directly; whether a dedicated QA or architecture-review process exists depends on team size, so the plugins must carry the guardrails regardless

## Pain Points

- Agents skip steps (architecture review, TDD, risk assessment)
- Silent config corruption from misbehaving plugins
- Having to manually police AI output
- Plugin-version drift across sibling projects on the same machine: a new plugin release lands on npm but the user's active sessions still run the old code, and catching up every sibling project (`cd ../foo && claude plugin install …`) is manual, repetitive, and easy to forget.
