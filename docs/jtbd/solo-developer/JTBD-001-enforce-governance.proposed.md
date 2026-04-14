---
status: proposed
job-id: enforce-governance
persona: solo-developer
date-created: 2026-04-14
---

# JTBD-001: Enforce Governance Without Slowing Down

## Job Statement

When I'm using an AI agent to write code, I want architecture decisions, risk scoring, and TDD to be enforced automatically, so I can get the safety of manual reviews without the overhead.

## Desired Outcomes

- Every edit to a project file is reviewed against relevant policy before it lands
- No manual step is needed to trigger reviews — they happen on every edit
- Reviews complete in under 60 seconds so they don't break flow

## Persona Constraints

- Wants speed without sacrificing quality
- Works alone or with a small team — no dedicated review process

## Current Solutions

Manual code review, PR review checklists, hoping the agent follows CLAUDE.md instructions
