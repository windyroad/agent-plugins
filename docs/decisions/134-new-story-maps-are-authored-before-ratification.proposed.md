---
status: "proposed"
date: 2026-09-24
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
supersedes: ["ADR-103 (in part — the pre-creation human gate for a new map)", "ADR-119 (in part — the pre-creation human gate when a fix needs its first map)"]
reassessment-date: 2026-12-24
---

# New story maps are authored before ratification

> Captured via /wr-architect:capture-adr. Section content was derived from the maintainer's correction; human-oversight remains unconfirmed until the completed decision is presented for ratification.

## Context and Problem Statement

The problem workflow asked the maintainer to authorize creation of a story map before the map existed. That makes the user approve an agent action rather than review the governance substance the map contains. A person cannot meaningfully ratify an unseen story map. The review must show the user journey, the backbone of top-level activities, and the links that trace the map to its problem, personas, and ratified jobs.

The framework already distinguishes creation from ratification: a captured map is born unconfirmed, and dependent implementation is blocked until the map is ratified. Requiring permission before creation duplicates the human gate without improving oversight. It blocks progress both when a person is available to respond and when no person is available. It also leaves ratification as a second request.

## Decision Drivers

- Human review must cover the completed map content that the existing oversight rules define as ratifiable. It must not cover permission to create the draft.
- The agent must perform routine map authoring without asking the user to authorize that authoring step.
- A newly authored map must remain unconfirmed until an explicit ratification event.
- No dependent implementation may proceed on an unratified map.
- Interactive and unattended workflows should share the same create-then-ratify sequence.

## Considered Options

1. **Author the map proposal, then ask for ratification (chosen)** — the agent derives and writes the map and proposal artefacts without permission, leaves the map unconfirmed, presents the completed proposal, and waits for ratification before dependent implementation.
2. **Ask permission before creating the map** — preserve the current gate, then ask again after creation for ratification.

## Decision Outcome

Chosen option: **"Author the map proposal, then ask for ratification"**, because ratification is meaningful only after the user can review the substance being ratified.

For this decision, a "complete map" means complete enough to present for ratification; it does not mean lifecycle status `completed`.

When a fix needs a map and no suitable map exists, the agent creates the map without first asking permission. It adds the initial backbone activities, which are the map's top-level steps. It also creates the proposal material needed to explain the fix. This material may include a release row that groups the proposed delivery work, cards describing that work, and any story files required by the existing release-row rules. The agent must not use `AskUserQuestion` or any other permission prompt for this authoring step. The new map starts with `human-oversight: unconfirmed`.

The proposal shows the initial release row and cards so that the user can understand the proposed work. Under the existing oversight rules, these items are not part of the map content recorded by the ratification marker, sometimes called the oversight fingerprint. Ratification covers only the map content already defined by those rules. Therefore, later edits to release rows or cards do not reopen map ratification.

After creation, the agent presents a self-contained account of the completed map proposal and asks the user to ratify or request changes. No human approval is required before authoring the new map. Ratification is the only human approval in the new-map workflow, and it is required before dependent implementation begins. Any requested change is applied before the map is presented again.

Dependent implementation—source changes and commits that implement the proposed stories—remains blocked until ratification. The agent does not auto-ratify, forge a confirmation marker, or treat the instruction to create the map as ratification of the authored substance.

Existing human gates remain unchanged for new architecture decisions and for substantive edits to already-ratified maps, including adding a new activity column. Initial backbone activities on a newly created, born-unconfirmed map are agent-authored before ratification.

In unattended operation, meaning a run without a person available to respond, the agent still authors the complete map proposal. It records one request for later human ratification. It may continue independent work, but it must not implement stories that depend on the unratified map. It must not ratify the map itself.

## Consequences

### Good

- The user reviews the actual map once instead of authorizing a draft and later ratifying it.
- Attended and unattended workflows can make safe progress through proposal authoring.
- The existing unconfirmed marker and implementation gate carry the safety boundary.

### Neutral

- Creating a map remains an agent judgment grounded in the problem, persona, and ratified job traces; ratification can require revisions.
- Initial release rows and cards make the proposal understandable, but they remain outside the map content recorded by the ratification marker.

### Bad

- The agent may author a map proposal the user later rejects or substantially changes, creating bounded rework before implementation.
- Unattended runs may accumulate completed but unratified map proposals awaiting review.

## Confirmation

Requested action: Review this decision and either ratify it or request changes. Ratifying this decision confirms the create-then-ratify workflow; it does not ratify any individual story map.

- When a repository has no suitable story map, the problem workflow authors a complete unconfirmed map proposal without `AskUserQuestion` or a permission prompt.
- The proposal includes any initial release row, cards, and story files required to present a valid fix proposal.
- The completed map proposal is presented for ratification, and only that ratification writes the confirmed oversight marker.
- Source changes and story-implementation commits depending on the map are refused while it remains unratified.
- Initial release rows and cards remain outside the oversight fingerprint, and later row/card edits do not reopen ratification.
- In unattended mode, map proposal creation completes, exactly one ratification item for the completed map is queued, and the loop continues with independent work.
- Behavioural evaluations reject responses that ask permission to create a map, skip map authoring, auto-ratify, or implement against the unratified map.

## Pros and Cons of the Options

### Author the map proposal, then ask for ratification

- Good, because the human decision is informed by the complete artefact.
- Good, because mechanical authoring proceeds without an invented permission gate.
- Bad, because rejected drafts consume some agent effort.

### Ask permission before creating the map

- Good, because no draft is authored before user contact.
- Bad, because the user cannot inspect the substance they are being asked to authorize.
- Bad, because it creates two human gates for one map and blocks unattended progress before the completed proposal can be presented for ratification.

## Reassessment Criteria

Reassess if map authoring repeatedly produces proposals that users reject outright, or if the unratified-map implementation gate fails to prevent dependent implementation before ratification.
