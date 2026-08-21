---
status: accepted
story-id: a-fix-proposal-draws-a-release-row-not-a-document
reported: 2026-08-21
decision-makers: [Tom Howard]
problems: [P508]
jtbd: [JTBD-008, JTBD-001, JTBD-006]
rfcs: [RFC-071]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-065: A fix proposal draws a release row, not a document

**Reported**: 2026-08-21
**Problems**: P508
**JTBD**: JTBD-008 (Decompose a Fix Into Coordinated Changes), JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I'm Away)
**RFCs**: RFC-071 (release row on STORY-MAP-002 — a fix proposal draws a release row, not a document)
**Story Maps**: STORY-MAP-002 (Take a problem from noticed to resolved), activity `decompose`
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to have every fix I propose land on the map where I actually approve work, as a developer working a known error, I want the framework to draw a release row instead of writing a separate document nobody approves.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] The propose-fix check answers "something already proposes a fix for this problem" from a release row, not only from a legacy document — a problem named by a row's cards reads as traced.
- [x] The same check keeps answering from the legacy documents already on disk, so no problem that read as traced yesterday reads as untraced today.
- [x] A release row carrying no card that names the problem does not read as traced, so a bare row cannot stand in for a proposal.
- [x] A speculative row — one carrying no RFC identity — is not counted as a fix vehicle.
- [x] When nothing proposes a fix, the check tells the caller to draw a release row and does not name any command that creates a file under `docs/rfcs/`.
- [x] The identity the check hands out is held by no document and no row, in the working tree or anywhere in git history.
- [x] A story map that was edited without being re-rendered is reported as unable to answer, distinguishably from a map that answered "no row names this problem", so a second row is never drawn over one that already exists.
- [x] A repository with no story maps at all gets one item recorded for a person and the loop carries on, rather than every known error refusing.
- [ ] The skill that writes a fix proposal draws the row itself instead of creating a document, and the create gate refuses a new file under `docs/rfcs/` while still allowing the lifecycle renames of the documents already there.

## Driving problem trace (required — I6 invariant)

P508 — the shipped propose-fix gate ran the superseded path: on a known error with no traced vehicle it delegated to a skill that allocated an identity and wrote a new document, and nothing in that path drew a row on any map. Two contradictory mechanisms were live at once and the one the framework reached for automatically was the retired one. Witnessed in anger 2026-08-21 while working P463: the check emitted its create-a-document directive against a known error that had a genuine vehicle available, and only a synchronous architect review caught it.

## JTBD trace (required — I9 invariant)

- **JTBD-008** (primary) — the job's whole premise is that a fix decomposes onto a coordination surface that traces back to the problem. A proposal written as its own document sits outside that surface, so the trace it carries points at nothing anyone approves.
- **JTBD-001** (secondary) — two approval surfaces means the automatic one bypasses the human one. That is a governance hole rather than redundancy, and closing it is what the job asks for.
- **JTBD-006** (secondary) — a material part of what shipped is about how the unattended loop conducts itself, not about the vehicle. The check refuses rather than guesses in two cases, and the two refusals are handled differently: a map that was edited without being re-rendered is mechanical and asks nobody, while a repository with no maps at all records one item for a person and the loop carries on to the next problem instead of stopping. That is this job's "problems requiring my judgment are queued for my return, not guessed at" and its "the loop stops gracefully when nothing actionable remains", read against a new refusal.

## Implementation notes (optional)

Sequenced readers-before-writers. The check is the reader every writer depends on: repoint the writer first and every known error reads "no vehicle" and the loop stops on everything. Reading the union of both tiers is a strict widening — nothing that read as traced before reads as untraced after — so it is safe to land ahead of the writer, which is why the last criterion is left for the following slice.

The identity allocator is a prerequisite rather than a consequence: the old rule read the document directory alone, and rows already held identities above the highest document, so it was already handing back an identity a row owned.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- The row this story sits under was drawn while the gate that draws rows was itself being repointed, so it could not be drawn *through* that gate. That ordering is a one-off of bootstrapping and is recorded rather than hidden; every later fix proposal on this ticket goes through the repointed gate.
- Sibling on the same map activity: STORY-013 (the propose-fix gate) and STORY-015 (releases are proposed against the problem before any code is written), which this story brings into line with the row model.
