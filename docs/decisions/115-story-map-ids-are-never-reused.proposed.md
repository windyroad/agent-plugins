---
status: proposed
date: 2026-08-12
decision-makers: [Tom Howard]
human-oversight: confirmed
oversight-date: 2026-08-12
oversight-note: "2026-08-12 - ratified by Tom Howard after reviewing the complete ADR-115 document."
consulted: [wr-architect:agent, wr-risk-scorer:pipeline]
informed: []
supersedes: [ADR-060 (in part - STORY-MAP ID allocation only)]
jtbd: [JTBD-008]
persona: developer
reassessment-date: 2026-11-12
---

# ADR-115: Story-map IDs are never reused

## Context and Problem Statement

STORY-MAP-012 and STORY-MAP-013 were deleted because they were empty draft maps with no stories. The existing capture rule allocates `max(local, origin) + 1`. Once those deletions reach `origin/main`, both inputs end at STORY-MAP-011 and the next capture can reuse 012.

A story-map ID is a durable trace identity. Reusing one would make historical commits, prose, and external references ambiguous: the same ID would identify two unrelated journeys at different times. Deleting a map must remove the artefact without making its identity available again.

## Decision Drivers

- One ID must identify one story map for the lifetime of the repository.
- Deleting an empty or invalid map must remain possible without keeping a fake map file.
- The allocator should use an existing source of truth rather than introduce a second retirement registry.
- The rule must remain mechanical and testable in the capture skill.
- Current and origin trees must still protect against uncommitted and concurrent allocations.

## Considered Options

1. **Include Git history in the maximum (chosen)** - allocate one above the largest ID found in the working tree, `origin/main`, or any reachable historical story-map path.
2. **Keep `max(local, origin) + 1`** - accept reuse after a deletion reaches both trees.
3. **Maintain a retired-ID registry or tombstone files** - record deleted IDs in a new live artefact and include it in allocation.

## Decision Outcome

Chosen option: **Include Git history in the maximum**.

`capture-story-map` allocates `max(local, origin, history) + 1`. The history input is the largest `STORY-MAP-NNN` found in paths returned by `git log --all --name-only --format= -- docs/story-maps/`.

This supersedes ADR-060 only where it specifies `max(local, origin) + 1` for STORY-MAP IDs. Its allocation rules for problems, ADRs, RFCs, stories, and other namespaces are unchanged.

## Consequences

### Good

- A deleted map ID cannot silently acquire a second meaning.
- Empty or invalid maps can be deleted rather than retained as artefact-shaped tombstones.
- Git history is already the durable record of the deleted path, so no retirement registry can drift from it.
- Local and origin maxima continue to protect allocations not yet present in shared history.

### Neutral

- Allocation performs one additional local Git query.
- Deleted map files remain recoverable through normal Git history, as they already were.

### Bad

- A shallow clone whose retained history predates neither the deleted path nor an origin copy can miss the retired ID.
- Repositories that rewrite history can erase the reservation along with the historical path.
- The allocation rule differs from the other governance ID namespaces until they demonstrate the same deletion-and-reuse problem.

## Confirmation

- The capture-story-map behavioural test creates and commits STORY-MAP-013, deletes and commits it, then asserts the next ID is 014.
- A Codex Promptfoo case runs the actual skill contract against the repository with STORY-MAP-012 and STORY-MAP-013 deleted and asserts STORY-MAP-014 from working-tree, origin, and history inputs.
- A repository scan after deletion finds no live references to STORY-MAP-012 or STORY-MAP-013 outside explicit historical records.
- `reconcile-story-maps.sh` reports the README and filesystem are aligned after deletion.

## Pros and Cons of the Options

### Include Git history in the maximum

- Good, because it preserves identity without adding a new artefact.
- Good, because the source already records every committed map path.
- Bad, because shallow or rewritten history weakens the guarantee.

### Keep `max(local, origin) + 1`

- Good, because it is the existing and cheapest query.
- Bad, because the approved deletion of maps 012 and 013 makes reuse deterministic after the deletion reaches origin.

### Maintain a retired-ID registry or tombstone files

- Good, because reservations remain visible even in a shallow clone.
- Bad, because a second live source must be updated on every deletion and can drift from repository history.
- Bad, because a tombstone map would make indexes and reverse traces claim an artefact still exists.

## Reassessment Criteria

Reassess if story-map capture must work from shallow clones that do not contain deleted map paths, if history rewriting becomes supported repository practice, or if the history query becomes a measurable capture-time cost. In those cases, replace history-only retirement with a checked-in monotonic next-ID value rather than a list of tombstones.
