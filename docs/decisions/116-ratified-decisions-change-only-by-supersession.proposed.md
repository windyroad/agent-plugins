---
status: "proposed"
date: 2026-08-13
human-oversight: confirmed
oversight-date: 2026-08-13
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-11-13
---

# Ratified decisions change only by supersession

## Context and Problem Statement

The decision corpus contains amendment sections and `amends:` links that add new substance after a human-oversight marker was written. That lets later text inherit authority from a ratification event that never covered it. P483 records the maintainer's direction that this mechanism is illegitimate and that the architect reviewer must stop recommending it.

## Decision Drivers

- A ratification must apply only to the substance the decision-maker reviewed.
- Historical decisions must remain an auditable record of what was decided at that time.
- A replacement decision needs its own explicit oversight event.
- Existing amendment debt must not become precedent for creating more of it.

## Considered Options

1. **Make ratified decisions immutable and replace them through supersession (chosen)** - preserve the ratified record and put changed substance in a new decision.
2. **Continue adding amendment sections** - compact, but grants old ratification to new text.
3. **Clear the oversight marker, edit, and re-ratify** - makes the edited document confirmable, but rewrites the historical record in place.

## Decision Outcome

Once a decision carries `human-oversight: confirmed`, its body is immutable. A later choice deprecates or supersedes it with a new decision; it does not edit the ratified body, add an amendment section, add an `amends:` claim, or clear the marker to rewrite history. Before ratification, a proposed decision remains editable.

Existing amendment sections are migration debt tracked by P483. Their presence does not authorize another amendment and does not require unrelated releases to rewrite confirmed records in place.

## Consequences

### Good

- Every new governing statement receives its own reviewable decision and oversight event.
- Ratified files remain reliable historical evidence.
- The architect can reject in-place amendments consistently instead of citing them as precedent.

### Neutral

- Superseded decisions remain in the corpus and compendium as historical records.

### Bad

- Replacing a decision creates another file and requires another ratification.
- The existing amendment corpus needs a deliberate supersession sweep rather than mechanical cleanup.

## Confirmation

- The architect reviewer reports `[Amendment To Ratified Decision]` when a proposed change edits a confirmed decision body, adds an amendment section, or introduces an `amends:` claim.
- The reviewer directs substantive change into a new superseding decision and does not accept clearing the oversight marker as a remedy.
- A change that merely cites a legacy decision containing amendments does not trigger the finding.

## Pros and Cons of the Options

### Immutable after ratification, supersede for change

- Good, because ratification and reviewed substance remain aligned.
- Bad, because the corpus grows when decisions evolve.

### In-place amendment sections

- Good, because related history stays in one file.
- Bad, because later text inherits authority it was never given.

### Clear, edit, and re-ratify

- Good, because the resulting text can receive fresh oversight.
- Bad, because the original ratified record is destroyed.

## Reassessment Criteria

Reassess if the repository adopts an append-only decision format that structurally preserves each separately ratified revision and presents those revisions as distinct decisions.

## More Information

- P483: `docs/problems/open/483-amendment-sections-are-not-a-legitimate-mechanism-a-ratified-decision-is-immutable.md`
- P479 and P480 document the decision-accretion and rider-authority failure modes this rule prevents.
