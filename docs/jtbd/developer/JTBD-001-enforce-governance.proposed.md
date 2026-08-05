---
status: proposed
job-id: enforce-governance
persona: developer
secondary-persona: tech-lead
date-created: 2026-04-14
human-oversight: confirmed
oversight-date: 2026-05-31
---

# JTBD-001: Enforce Governance Without Slowing Down

## Job Statement

When I'm using an AI agent to write code, I want architecture decisions, risk scoring, and TDD to be enforced automatically, so I can get the safety of manual reviews without the overhead.

## Desired Outcomes

- Every edit to a project file is reviewed against relevant policy before it lands
- No manual step is needed to trigger reviews — they happen on every edit
- Reviews complete in under 60 seconds so they don't break flow
- **Multi-commit coordinated changes (refactors, phased migrations, framework evolutions) are governed at the change-set level, not just per-edit, so coordination decisions ride the same WSJF / lifecycle / audit-trail surface as atomic edits.** (Added 2026-05-05 per ADR-060 RFC framework — JTBD-review finding 2.)

## Persona Constraints

- Wants speed without sacrificing quality
- Works alone or with a small team — no dedicated review process

## Current Solutions

Manual code review, PR review checklists, hoping the agent follows CLAUDE.md instructions

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
| STORY-055 | STORY-055: One definition of what the oversight fingerprint ignores | accepted |
| STORY-002 | STORY-002: /wr-itil:capture-story lightweight aside skill | done |
| STORY-005 | STORY-005: Working-the-problem traversal rewrite (manage-problem + work-problem) | done |
| STORY-006 | STORY-006: /wr-itil:reconcile-stories trio (skill + script + bin shim) | done |
| STORY-007 | STORY-007: /wr-itil:manage-story heavyweight story lifecycle skill | done |
| STORY-013 | STORY-013: Full gate: an RFC exists → I proceed; none → I create it first | draft |
| STORY-023 | STORY-023: Ship → verify → problem closes with a real trace; adopter gets the fix | done |
| STORY-033 | STORY-033: Loud cold-path diagnostic for oversight-marker shims | draft |
| STORY-037 | STORY-037: Commit gate honours the RISK-POLICY stated review cadence for staleness | draft |
| STORY-052 | STORY-052: Surface still-outstanding family members before a close | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Decompose a fix into coordinated changes | draft |
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
| STORY-MAP-012 | STORY-MAP-012: Ship through a scored path | draft |
| STORY-MAP-001 | STORY-MAP-001: RFC framework Phase 1 + Phase 2 bootstrap | in-progress |
