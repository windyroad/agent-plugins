---
status: proposed
job-id: enforce-governance
persona: developer
secondary-persona: tech-lead
date-created: 2026-04-14
human-oversight: confirmed
oversight-date: 2026-09-22
oversight-downgraded: "2026-09-19 — material amendment per ADR-068, in lockstep with ADR-131. The first Desired Outcome read, unqualified, that every edit to a project file is reviewed before it lands. That is observably false: the five edit gates bind the Edit|Write tool matcher, and the classifier shipped on 2026-08-31 resolves only a published subset of Bash write shapes, so a shell loop, a wildcard target, or a write performed inside sed or node reaches disk unreviewed. A field instance on 2026-09-19 hand-wrote a ratification marker into five decision records through exactly that route. The outcome is NARROWED in prose to say where review actually fires. Grounded on ADR-110 and ADR-068, both ratified — not on the unratified ADR-131, so this withdrawal presumes no unratified decision. Withdrawing a ratification claim needs no confirm event; asserting one would. Expect the jobs reviewer to return a failing verdict naming this job on work that cites it while it is unratified (ADR-109) — that fire is known and accepted here, not a defect, and must not be cleared by dropping the citation. Re-ratification is owed at the next interactive /wr-jtbd:confirm-jobs-and-personas drain, and per ADR-111 it is discharged by a structured question carrying the summary AND this file, not by a prose ask."
---

# JTBD-001: Enforce Governance Without Slowing Down

## Job Statement

When I'm using an AI agent to write code, I want architecture decisions, risk scoring, and TDD to be enforced automatically, so I can get the safety of manual reviews without the overhead.

## Desired Outcomes

- Every edit to a project file made through the agent's edit and write tools is reviewed against relevant policy before it lands. A file write routed through a shell command is reviewed only where the target can be read straight off the command text — a literal redirection, a heredoc, a `tee` operand. A shell loop, a wildcard or variable target, or a write performed inside another program such as `sed -i` or a node script is **not** reviewed. That gap is deliberate: guessing which file such a command touches would put a wrong filename in the audit trail, and denying every command that cannot be read would deny ordinary read-only shell work. (Narrowed 2026-09-19 — see the oversight note in this file's front matter.)
- No manual step is needed to trigger reviews — they happen on every edit
- Reviews complete in under 60 seconds so they don't break flow
- **Multi-commit coordinated changes (refactors, phased migrations, framework evolutions) are governed at the change-set level, not just per-edit, so coordination decisions ride the same WSJF / lifecycle / audit-trail surface as atomic edits.** (Added 2026-05-05 per ADR-060 RFC framework — JTBD-review finding 2.)

## Persona Constraints

- Wants speed without sacrificing quality
- Works alone or with a small team — no dedicated review process

## Current Solutions

Manual code review, PR review checklists, hoping the agent follows CLAUDE.md instructions
## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-002 | STORY-MAP-002: Take a problem from noticed to resolved | draft |
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
| STORY-055 | STORY-055: One definition of what the oversight fingerprint ignores | accepted |
| STORY-061 | STORY-061: See why a SubagentStop risk receipt was not written | accepted |
| STORY-065 | STORY-065: A fix proposal draws a release row, not a document | accepted |
| STORY-066 | STORY-066: A fix I can prove works gets closed without me | accepted |
| STORY-072 | STORY-072: Record oversight evidence only for the confirming session | accepted |
| STORY-080 | STORY-080: Record a completed native review without manual marker recovery | accepted |
| STORY-081 | STORY-081: Trust plan reviews when no risk policy is present | accepted |
| STORY-002 | STORY-002: /wr-itil:capture-story lightweight aside skill | done |
| STORY-005 | STORY-005: Working-the-problem traversal rewrite (manage-problem + work-problem) | done |
| STORY-006 | STORY-006: /wr-itil:reconcile-stories trio (skill + script + bin shim) | done |
| STORY-007 | STORY-007: /wr-itil:manage-story heavyweight story lifecycle skill | done |
| STORY-023 | STORY-023: Ship → verify → problem closes with a real trace; adopter gets the fix | done |
| STORY-063 | STORY-063: Check ADR pairing in the checkout being committed | done |
| STORY-077 | STORY-077: Move a captured fix straight to verification and keep a reopened problem in the work queue | done |
| STORY-088 | STORY-088: Capture a problem when its index is missing | done |
| STORY-013 | STORY-013: Full gate: an RFC exists → I proceed; none → I create it first | draft |
| STORY-033 | STORY-033: Loud cold-path diagnostic for oversight-marker shims | draft |
| STORY-037 | STORY-037: Commit gate honours the RISK-POLICY stated review cadence for staleness | draft |
| STORY-052 | STORY-052: Surface still-outstanding family members before a close | draft |
| STORY-060 | STORY-060: Pick up a captured ticket and know what was observed | draft |
| STORY-064 | STORY-064: A ticket that only names a decision as background stays open | draft |
| STORY-062 | STORY-062: Keep problem ranking correct after a status transition | in-progress |
| STORY-078 | STORY-078: A reviewer catches first-match binding when the key is not unique | in-progress |
| STORY-079 | STORY-079: Review only options consistent with documented desired outcomes | in-progress |
| STORY-082 | STORY-082: Gate Bash writes without blocking read-only commands | in-progress |
| STORY-083 | STORY-083: A canonical architect PASS unlocks the guarded edit | in-progress |
| STORY-086 | STORY-086: Complete an external-comms review without repeating it | in-progress |
| STORY-087 | STORY-087: Inspect a package without triggering publication review | in-progress |
| STORY-089 | STORY-089: I can continue after a reviewer passes, without plugin-specific recovery | in-progress |
