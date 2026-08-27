---
status: proposed
job-id: ship-with-confidence
persona: developer
secondary-persona: tech-lead
date-created: 2026-04-14
human-oversight: unconfirmed
oversight-date: 2026-05-31
oversight-confirmed-date: "2026-07-27 — re-ratified via the P357 brief AskUserQuestion this session; the ADR-101 lockstep two-axis amendment (governance-bypass strengthened for everyone per P465, narrowed on the machine-accept axis only where a project opts in) confirmed in the same batch as ADR-101. SUPERSEDED — see oversight-downgraded below."
oversight-downgraded: "2026-08-21 — ADR-103 lockstep (material amendment per ADR-068), surfaced by the P508 slice-A JTBD gate. The machine-accept axis below is stated as narrowing 'only where the project has explicitly opted in', and claims that under the shipped default nothing is loosened at all. ADR-103 superseded ADR-101 outright on 2026-08-07 and dropped the opt-in, so the shipped default IS the narrowed behaviour. Marker held until re-ratified at the next interactive /wr-jtbd:confirm-jobs-and-personas drain (ADR-066 P348 AFK fallback)."
oversight-downgraded-2026-07-26: "2026-07-26 — ADR-101 lockstep (material amendment per ADR-068): the Desired Outcome 'The agent cannot bypass governance — hooks block edits until reviews pass' is QUALIFIED on two axes — strengthened on the ratification axis for everyone (P465), narrowed on the machine-accept axis only where a project opts in. Marker held until re-ratified; re-ratification queued with ADR-101's owed post-draft brief (P456 open items)."
---

# JTBD-002: Ship AI-Assisted Code with Confidence

## Job Statement

When I delegate coding to an AI agent, I want to know it followed the full TDD cycle (red-green-refactor) and passed architecture review, so I can trust the code is BOTH well-tested AND well-factored — not just passing tests.

## Desired Outcomes

- Every commit has been through architecture review, risk scoring, and TDD enforcement
- The agent cannot bypass governance — hooks block edits until reviews pass
  - **Amendment 2026-07-26 (ADR-101), stated on two axes because the net effect differs by project.** On the **ratification axis** the guarantee gets stronger for everyone: the commit gate now blocks an implementing commit against a story I have not ratified, which it never did before — the check ADR-095 and ADR-096 both named was enforced nowhere in code (P465). On the **machine-accept axis** it narrows: ~~but only where the project has explicitly opted in: there,~~ an unattended run may write the ratification itself for a story that decomposes nothing but already-confirmed substance. ~~Under the shipped default nothing is loosened at all, so for an adopter who changes nothing, the hooks block strictly more than before.~~
  - **SUPERSEDED 2026-08-07 by ADR-103 — do not read the opt-in qualifier above as current.** ADR-103 supersedes ADR-101 outright and drops the opt-in knowingly, so the narrowed machine-accept behaviour IS the shipped default; an adopter who changes nothing gets it. The ratification-axis half above is unaffected and still holds: the commit gate blocks an implementing commit against an unratified story (P465). Struck rather than deleted so the witness survives.
- The refactor step is enforced and not skipped at green — structural quality lands with the tests, so the code is well-factored and not just test-passing
- Audit trail exists (markers, scores, review records) showing governance was followed

## Persona Constraints

- Wants speed without sacrificing quality
- No dedicated QA or architecture review process

## Current Solutions

Pair programming with the AI, manual review of every diff, restricting agent permissions
## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-055 | STORY-055: One definition of what the oversight fingerprint ignores | accepted |
| STORY-061 | STORY-061: See why a SubagentStop risk receipt was not written | accepted |
| STORY-067 | STORY-067: Publish packages without expiring secrets | accepted |
| STORY-053 | STORY-053: Test claims against the tree at capture and label the untested ones | draft |
| STORY-059 | STORY-059: See why the loop did not work what I expected | draft |
| STORY-046 | STORY-046: Red-CI denial explains the recovery path | in-progress |
