---
status: proposed
date: 2026-08-09
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — confirmed after a post-change brief that stated the rule in plain terms and disclosed three things: that the same rule had landed as an amendment in two separate ratified documents, that each amendment had recorded itself as ratified on the grounds that it merely tightened a mechanism, and that the gate's cost is not theoretical — it had already silently reverted this session's ratification of one story map before the cause was found. The brief also carried the correction that the sweep is 74 amendments and 21 post-ratification, not the 55 and 10 previously reported; the earlier counts had matched on markup and missed the blockquote form entirely."
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
supersedes: [ADR-066 (in part — the 2026-06-02 marker-write amendment only), ADR-068 (in part — the 2026-06-02 marker-write amendment only)]
jtbd: [JTBD-002, JTBD-006]
persona: developer
secondary-persona: tech-lead
---

# ADR-110: A ratification marker can only be written when someone actually ratified

## Context and Problem Statement

Decisions, jobs and personas each carry a line in their frontmatter saying whether a person has agreed to what the document says. Everything downstream leans on that line. A reviewer refuses work built on an artefact that lacks it. A drain pass exists to work through the ones that do. It is the record that a human was in the loop.

The line was being written by things that had no human in the loop at all.

Work that runs unattended has no way to ask anyone anything. Faced with a document needing a ratification line, the honest answer is "nobody has agreed this". What was happening instead was that the line got written as *agreed*, because that is what the authoring flow does when a person is present and nothing distinguished the two cases. Jobs and personas were being authored overnight and marked as ratified by the same run that wrote them.

The instruction to behave otherwise already existed, in prose, on the authoring surfaces. It said the marker is written only when a confirmation answer comes back. It did not hold. That is the evidence that matters here: the rule was stated clearly, in the right place, and the unattended path wrote `confirmed` anyway.

A marker that can be written without a confirmation is not a record of anything. Every guard that reads it inherits the lie, and the drain pass never sees the artefact because it already looks agreed.

## Decision Drivers

- The marker is load-bearing for two reviewers, a drain pass and a session-start nudge. If it can be self-granted, all four are decorative.
- Unattended work should still produce artefacts. The problem is the claim of approval attached to them, not the artefacts.
- An honest "nobody agreed this yet" is a useful state. It routes the artefact into the queue of things to agree, which is exactly where it belongs.
- Prose instructions on the authoring surface were already tried and did not hold. Whatever replaces them has to be something the writing path cannot simply not do.

## Considered Options

1. **Refuse the write structurally, and give the unattended path an honest value to write instead.** An edit that introduces a ratified marker into one of these documents is denied unless there is evidence, for that specific document and that specific session, that someone confirmed it. Unattended work writes `unconfirmed`.
2. **Keep instructing.** Restate on the authoring surfaces that the marker follows a confirmation. Rejected: this is what was in place, and it is what failed.
3. **Stop unattended work from authoring these artefacts at all.** Rejected: the artefacts are worth having. It is only the approval claim that is not, and refusing the whole activity to prevent one field is disproportionate.
4. **Let it write `confirmed` and sort it out at the drain.** Rejected: the drain finds artefacts by the absence of the marker, so anything wrongly marked is invisible to it. This is the failure, not a fix for it.

## Decision Outcome

**Option 1, on both the decisions surface and the jobs-and-personas surface.**

An edit that introduces a ratified marker into one of these documents is refused unless evidence exists — scoped to that document and that session — that a person confirmed it. The authoring flows produce that evidence at the moment the confirmation answer lands, so a session with a person in it is unaffected. A session without one cannot produce it, which is the point.

Alongside it, `unconfirmed` becomes a value the marker can hold. Unattended work writes it. It reads as unratified to everything that inspects the marker, so it flows into the drain queue without any of those readers needing to change.

Both plugins already implement this separately, each with its own gate. This document states the rule once rather than twice; nothing about the two implementations is coupled by it.

## Consequences

### Good

- The marker means what it says. A guard that refuses work built on unratified substance is now refusing on a fact rather than on a claim.
- Unattended work keeps producing artefacts, and they arrive in the queue of things to agree instead of silently past it.
- The rule cannot be quietly not-followed. It is refused at the point of writing rather than requested at the point of authoring.

### Neutral

- The evidence is scoped to one session and one document, so it cannot be produced once and reused across a batch.

### Bad

- Anything that legitimately writes the marker has to produce the evidence first, and a flow that forgets is refused with no obvious cause. That has already cost time in practice — a marker helper that silently did nothing when its session identity was empty, and a stale copy of another that wrote to the wrong place entirely. The gate is right; discovering *why* it refused is the part that is still hard.
- Two implementations of one rule can drift. This document does not stop that; it only means there is one place to check them against.

## Confirmation

- An edit introducing a ratified marker into a decision, job or persona is refused when no evidence exists for that document in that session.
- The same edit succeeds when the evidence exists.
- Evidence for one document does not permit the marker on another.
- An artefact marked `unconfirmed` is surfaced by the drain pass and by the session-start nudge, exactly as one with no marker at all would be.
- Unattended authoring produces `unconfirmed` and is not refused.

## Related

- **ADR-066** and **ADR-068** — the decisions this supersedes in part. Each carried this rule as a 2026-06-02 amendment, added a week after it was ratified, and each recorded itself as ratified on the grounds that it "tightens the mechanism" rather than changing the decision. That reasoning is the thing this sweep exists to stop: it lets a change grant itself the approval it should have asked for.
- **ADR-109** — the guard that refuses work built on an unratified job. It reads the marker this decision protects.
- **P348** — the ticket that captured unattended runs writing `confirmed`.
- **P340** — the earlier prose-only version of this rule, on the authoring surfaces. Its failure is the argument for Option 1.
- **P368** — a marker helper that silently did nothing when the session identity was empty. The cost recorded in Consequences.
- **P483** — amendment sections are not a legitimate way to change a ratified decision. Third document of that sweep.

## Reassessment Criteria

Revisit if the two implementations diverge in what they accept as evidence, or if flows start being refused often enough that people work around the gate rather than produce the evidence — the second would mean the evidence is too hard to produce, not that the rule is wrong.
