---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed after a post-change brief that stated the decision in plain terms, named the option chosen and the option rejected, and said that the predicate had been running unagreed since 2026-06-28. The maintainer had directed this flow explicitly for the P483 sweep: draft, summarise in prose, send the file, ask. The rejected narrowing (nudge only where a reports directory shows the scorer in use) was put in front of them as a live option rather than left in the document as a queued question."
consulted: [wr-architect:agent]
informed: [Windy Road plugin users]
supersedes: [ADR-047 (in part — the 2026-06-28 policy-absent predicate only; the rest of ADR-047 stands)]
jtbd: [JTBD-001, JTBD-202]
persona: developer
secondary-persona: tech-lead
---

# ADR-108: The risk scorer nudges a project that has no risk policy at all

## Context and Problem Statement

The risk-scorer plugin ships a session-start hook that says one line and writes nothing. Its original job was narrow: if a project has a risk policy but no register directory to hold the standing risks that policy implies, say so once per session and point at the skill that creates it.

That hook deliberately said nothing to a project with no policy file. The reasoning was that the policy file is what creates the expectation of a register, so with no policy there is no gap to report.

Sound for the register. It leaves a different gap uncovered. Someone installs the plugin, never writes a policy, and works for weeks. Every scored action silently uses the built-in default appetite. Nothing ever tells them a policy can be written, what it would change, or that they are running on a default somebody else picked. The capability is present, dormant and undiscoverable, and staying quiet about it is a choice the hook makes on their behalf every session.

A second predicate was added to the hook to close that: with no policy file present, emit one line pointing at the skill that interviews you and writes one. It shipped on 2026-06-28, eighteen days after this project's decision on that hook had been ratified, and it was recorded as an amendment inside the ratified document rather than as a decision of its own. It has been running ever since and has never been agreed to.

## Decision Drivers

- Enforcing governance without slowing anyone down. A capability nobody can discover enforces nothing, and the survey that started this work found the register missing on four of six projects that had a policy — discoverability is the failure mode here, not capability.
- A default that nobody chose is still a decision. Running on the built-in appetite is defensible; running on it without knowing you are is not.
- One line of stderr, once per session, is close to the cheapest surface available — but it is not free, and it fires against every project the plugin is installed in, including ones that will never want a policy.
- The existing suppression variable already silences every nudge of this class at once, so anyone who wants quiet has one switch rather than a per-plugin collection.

## Considered Options

1. **Nudge whenever there is no policy file.** One line per session in any project without one, pointing at the skill that writes it.
2. **Nudge only where there is evidence the scorer is being used** — a reports directory present but no policy. Silent in a project that has the plugin installed and is not scoring anything.
3. **Say nothing, as before.** The capability stays undiscoverable; the default appetite stays invisible.

## Decision Outcome

**Option 1.** With no policy file present, the hook emits one line pointing at the policy-authoring skill, and stops — the register and curation checks never run, because without a policy neither has anything to say.

Option 2 is the narrower and more considerate reading, and it was raised in review at the time. It is rejected here for one reason: it can only fire after the scorer has already run without a policy, which means the first several scored actions still happen silently on a default the person never saw. The point of the nudge is to reach them before that, not after. The cost of being wrong in Option 1's direction is one line of text in a project that did not want it; the cost of being wrong in Option 2's direction is scoring work against an appetite nobody chose.

The line is read-only. Nothing is written, nothing is scaffolded, and the skill it points at is where any writing happens, with the person present.

## Consequences

### Good

- Someone who installs the plugin and never writes a policy finds out that they can, and that they are currently running on a default.
- The hook's three arms now have one rule between them — policy absent, register absent, curation pending — each surfaced once per session and each silent when there is nothing to say.
- The behaviour that has been shipping since June is finally written down as something agreed rather than something that accumulated.

### Neutral

- The existing suppression variable covers this arm along with every other nudge of its class.

### Bad

- A project that has deliberately chosen to run policy-free gets a line every session suggesting otherwise, and the only way to stop it is to suppress every nudge of that class or write a policy. Option 2 would have spared them. If that turns out to be more than a theoretical annoyance, it is the first thing to revisit.

## Confirmation

- The hook emits on a project with no policy file, naming the policy-authoring skill, and exits without running the register or curation checks.
- It stays silent when the suppression variable is set, on every arm.
- It stays silent when the project directory does not exist.
- A project with no policy file but with a register directory present still gets the policy line — policy absence wins over register presence.
- Behavioural coverage sits with the hook's existing test file rather than in a new one.

## Related

- **ADR-047** — the decision this supersedes in part. Its ratified substance is the register-absent arm and the session-start nudge shape; its 2026-06-28 amendment is the policy-absent predicate, replaced by this document. Everything else in ADR-047 stands.
- **ADR-086** — the built-in appetite this nudge exists to make visible.
- **ADR-056** — owns the curation marker the hook's third arm counts. That arm documents behaviour already shipped and is not part of this decision.
- **P379** — the ticket that produced the predicate.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. This document is the first of that sweep.
- **P480** — a ratification is document-scoped, so a rider that was never weighed inherits the document's authority. That is how this predicate came to be running unagreed.

## Reassessment Criteria

Revisit if a project that deliberately runs without a policy reports the line as noise, or if the suppression variable starts being set for this reason alone — either would be the evidence Option 2 was waiting for.
