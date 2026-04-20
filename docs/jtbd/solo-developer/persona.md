---
name: solo-developer
description: Developer using AI coding agents for personal or small-team projects
---

# Solo Developer

## Who

Uses AI coding agents (Claude Code) for personal or small-team projects. Moves fast, ships often. May be working across multiple repos simultaneously.

## Context Constraints

- Wants speed without sacrificing quality
- May install only 2-3 plugins relevant to their project
- Works alone or with a small team — no dedicated QA or architecture review process

## Pain Points

- Agents skip steps (architecture review, TDD, risk assessment)
- Silent config corruption from misbehaving plugins
- Having to manually police AI output
- Plugin-version drift across sibling projects on the same machine: a new plugin release lands on npm but the user's active sessions still run the old code, and catching up every sibling project (`cd ../foo && claude plugin install …`) is manual, repetitive, and easy to forget.
