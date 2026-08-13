---
status: proposed
date: 2026-08-08
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-08
oversight-note: "2026-08-08 — confirmed via a P357 post-change brief on the document itself, which the maintainer read in full. Two substantive corrections were made before confirmation, both from the maintainer. First, a Consequences bullet described a state this decision's own model forbids — an RFC a map covers that no row carries — carried forward from an earlier draft without being re-read against the rule that replaced it; it was removed rather than repaired. Second, the delivered exception had been written as an open set, so any row would have qualified once its stories finished; the maintainer's intent was the closed historical set, which is what the document and the implementation now carry. A cognitive-accessibility review was run at the maintainer's request and found the open-set defect independently, along with several passages that could not be parsed on a phone; the document was rewritten for that reading context."
consulted: [wr-architect:agent, wr-jtbd:agent, accessibility-agents:cognitive-accessibility]
informed: []
supersedes: []
jtbd: [JTBD-008, JTBD-002]
persona: developer
secondary-persona: tech-lead
---

# ADR-107: A story map's RFC list is derived from its release rows

**In one line:** a story map keeps a hand-written list of the releases it covers, duplicating what its rows already say. That list has gone wrong on the one map you have approved. This deletes it and computes the list from the rows instead.

## Context and Problem Statement

A story map's rows are its releases. Each row names an RFC, and under ADR-103 the row *is* the RFC — drawing the row is what allocates the identity, and there is no separate RFC document.

The block of data at the top of the map file also carries a hand-written `rfcs` list. Nothing computes that list and nothing checks it against the rows, so it has drifted.

On STORY-MAP-002 the list names RFC-001, RFC-002 and RFC-003 — three of the legacy RFC files that predate ADR-103 — while naming neither of the two RFCs its rows actually carry. RFC-001 and RFC-002 have no stories at all, and RFC-003's stories are on no map. So the list names three releases the map does not represent, and misses the two it does. That is the one map carrying a human's approval.

## Decision Drivers

- Nothing computes this list and nothing checks it, so of course it drifted.
- It duplicates the rows. A second record of the same fact is the thing that drifts, and this project has removed several already.
- Correctness must not depend on someone remembering. Having to manually police AI output is a documented pain point for this persona; a list you have to keep updating by hand is that shape.
- The list sits inside the map's oversight fingerprint — the checksum over the parts of a map a human signs off. So approving a map means approving whatever the list says, including when it is wrong. An audit trail that certifies false content is worse than none, because it invites trust it has not earned.

## Considered Options

- **A. Keep the list hand-written.** Leaves two records of one fact with nothing reconciling them.
- **B. Compute the list from the rows.**
- **C. Compute it, and refuse to render a map naming an RFC no row carries.** As B, plus a hard stop.

The exception for historical rows is not one of the options — it is required by all three, because those rows exist and predate the identity rule.

## Decision Outcome

**Chosen option: B — compute the list from the rows.**

The list is built when the map renders, from the RFCs its rows name, in row order, with blanks and duplicates removed. Nobody writes it by hand. The renderer ignores any hand-written list it finds, and the key is deleted from all seven maps, with a check asserting none comes back.

**Every release row carries an RFC identity.** The one exception is closed: the rows holding work that shipped before rows carried identities. Those are recorded as they happened rather than having identities invented for them after the fact, and each says so explicitly — the row is marked `preRfc`. No new row can join that set.

Finishing a row earns nothing. Delivery cannot be the test, because every row is delivered eventually — that reading would make shipping unproposed work legitimate simply by completing it. So a row with no identity and no `preRfc` mark is a **defect** whether or not its stories are done, and the renderer draws it with a red warning badge reading "Untraced" so it cannot sit quietly on the map.

Dropping blanks matters: a map whose only row is a pre-RFC one would otherwise emit a list containing just a comma, and the tooling that keeps the legacy RFC files in step reads that as "this map has RFCs".

Option A was rejected because the drift is demonstrated rather than hypothetical. Option C was rejected as premature: the map already flags a row with no identity, so refusing to render adds a hard stop for something you can already see.

## Consequences

- Good: one place holds an RFC identity — the row. There is no second list to keep in step, and none to drift.
- Good: no upkeep. The list is right whether or not anyone remembers it.
- Good: the fingerprint no longer covers a hand-written list, so approving a map no longer means approving a stale one.
- Bad: if someone forgets to draw a row, nothing notices. The release simply does not exist, and no check can tell "this was never planned" from "this map has fewer releases than you thought".
- Bad: the legacy RFC files follow the rows too. Each one keeps a section listing the maps that cover it, built from the map's computed list — so an RFC no row carries loses its map association there as well.

## Confirmation

- A map's rendered RFC list equals the RFCs its rows name, and a hand-written list in the file is ignored in favour of it — behavioural test.
- A row carrying no identity contributes nothing to the list — behavioural test.
- A row marked `preRfc` whose stories have all shipped renders as delivered. An **unmarked** row whose stories have all shipped renders as a defect, so finishing work does not earn the exception — behavioural test.
- Renaming a row's RFC does not invalidate the map's approval, because the RFC list is no longer part of what a human signs off — behavioural test.
- No map carries a hand-written RFC list — a check across all seven maps, guarded so an unmatched search cannot pass without asserting anything.

## Related

- **ADR-103** (a release row is the RFC, and the map is the approval surface) — establishes that the row holds the identity. This decision is what follows once that is true.
- **ADR-104** (a story map card stores no value a story file already carries) — the same rule one tier down.
- **ADR-090** (story maps carry a drift-invalidated oversight marker) — defines the fingerprint. Unaffected in mechanism: only the content it covers changes.
- **P481** — cleanup this leaves behind: two ratified decisions still describe a map format that no longer exists.
- **P484** — this persona reads governance artefacts on devices with no access to the repository, so an artefact has to be self-evidently true rather than checkable against the corpus. That constraint is real and load-bearing here, and it is written down nowhere; P484 is to document it.

## Reassessment Criteria

Reassess toward option C if a map names an RFC that no row carries — that would mean the one-place-holds-the-identity property is not holding on its own and needs enforcing.
