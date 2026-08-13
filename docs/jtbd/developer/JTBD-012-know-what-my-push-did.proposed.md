---
status: proposed
job-id: know-what-my-push-did
persona: developer
secondary-persona: tech-lead
date-created: 2026-08-04
human-oversight: confirmed
oversight-date: 2026-08-12
oversight-note: "2026-08-12 - confirmed after removing the obsolete STORY-MAP-012/STORY-MAP-013 sentence from the Open Question; all other substance retains its 2026-08-04 confirmation."
---

# JTBD-012: Know What My Push Did Without Leaving the Terminal

> Authored 2026-08-04 to ground the half of P435 that had no home in the corpus. The pipeline
> appears in `docs/jtbd/` only as environmental context (the `plugin-developer` persona notes
> "uses changesets for versioning") and as a constraint on JTBD-101 ("Changesets handle
> versioning; the pipeline handles publishing") — never as a job. Yet a shipped risk hook
> enforces it, which is how a workflow convention came to be delivered as a safety control.
> Born `human-oversight: unconfirmed`, and ratified the same day via a post-change brief and
> `AskUserQuestion` — see the `oversight-note` in the frontmatter for what was confirmed.

## Job Statement

When I push work to a repository whose release pipeline runs somewhere else, I want to learn the pipeline's outcome without initiating a second action, so I can keep working instead of polling CI, hunting for a release PR, or discovering a failure an hour later.

## Desired Outcomes

- I learn the pipeline's terminal state without initiating a second action. I do not poll, refresh a browser tab, or re-run a query to find out what my own push did.
- On success, the single next thing I need is put in front of me: the release PR when there is pending release work, or the deployed preview when there is not. I do not go looking for it.
- On failure, I get what broke and where to look — not a status colour and a run identifier to go decode.
- Branches the pipeline owns are not something I have to remember not to touch. Pushing directly to a pipeline-managed branch is prevented by the tooling rather than by my recall.
- Versioning happens in the pipeline, not on my machine. A local versioning command that would leave the two disagreeing is prevented rather than merely discouraged.
- The whole loop is available where I already am. Leaving the terminal to learn the outcome of my own push is the friction this job removes.

## Persona Constraints

- Wants speed without sacrificing quality.
- No dedicated release engineer watching the pipeline on my behalf. (This holds at any team size — per `persona.md`, the distinguishing axis is role, not team size.)
- Must not need to leave the current task context. Losing the terminal is losing the thread.
- **Repo shape varies.** The developer's projects do not share one stack. The pipeline may be changesets on npm, a tag push, a Makefile target, or nothing at all. A tool serving this job must work from what the project actually provides. (Hosted in `persona.md` as a context constraint, because it binds JTBD-002 too — not only this job.)

## Current Solutions

`git push`, then switch to a browser or a second terminal and poll: `gh run list`, `gh run watch`, then hunt the PR list for the release PR. Works, but it costs the context switch this job exists to avoid, and the outcome is easy to walk away from and miss.

## Relationship to Adjacent Jobs

Authored explicitly so this job is not later challenged as redundant with its neighbours, and because the distinction is the reason it was written down.

- **[[JTBD-002]] Ship AI-Assisted Code with Confidence** — the governance job. Its concern is that work *cannot bypass* review, scoring, and TDD. This job's concern is that I find out what happened. The two are not opposites: **both involve denials**, and this job's own desired outcomes include two (protected branches, local versioning). The honest distinction is what a denial is *grounded in* — an assessment of the change under JTBD-002, an invariant of the delivery pipeline here. **Where the line between them falls is an open question, deliberately not settled by this job** (see Open Question below).
- **[[JTBD-005]] Invoke Governance Assessments On Demand** — also one-command, also terminal-resident, but its payload is a *verdict about the work*. This job's payload is a *report about the pipeline*. Neither subsumes the other: an in-appetite risk score says nothing about whether CI went green. Note that both jobs read the same CI signal — JTBD-005's tooling consumes it as a gate precondition, this job's emits it as information. Concern-distinct, machinery-shared.
- **[[JTBD-003]] Compose Only the Guardrails I Need** — the ratified constraint this job must satisfy. Its outcome "installing a subset does not degrade the experience for installed plugins", and its constraint "may install only 2-3 plugins relevant to their project", are what make repo-shape neutrality obligatory rather than nice-to-have: tooling for this job must not degrade a project that installed it for the reporting and has no pipeline to report on. This is the corpus anchor for P435's over-fire half.

## Open Question

Whether the tooling serving this job belongs in `@windyroad/risk-scorer` (where it is implemented today, fused into `git-push-gate.sh`) or in a separate stack-neutral plugin is **undecided as of 2026-08-04**. Two of this job's desired outcomes are denials, so "the risk plugin denies, this one only reports" is not the dividing line. A composition contract for the shared `git push` interception point is a prerequisite of any split — without one, a split converts P435 into the cross-plugin attribution ambiguity the `plugin-user` persona documents as a pain point.

## Related Problem Tickets

- P435 — wr-risk-scorer gates hardcoded to home-repo shape. The over-fire half (inbound #235) is this job's tooling firing in repositories it does not fit.

## Stories

| ID | Title | Status |
|----|-------|--------|
