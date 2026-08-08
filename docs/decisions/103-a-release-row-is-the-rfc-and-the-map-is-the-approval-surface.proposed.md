---
status: proposed
date: 2026-08-07
decision-makers: Tom Howard
human-oversight: confirmed
oversight-date: 2026-08-07
oversight-confirmed-date: "2026-08-07 — P357 post-change brief surfaced via AskUserQuestion after the implementation landed, then re-briefed after a second architect pass corrected residual passages in this body. Two substantive choices were surfaced separately and pinned by the maintainer rather than inherited: (1) map membership is write-once and ADR-101's opt-in adopter protection is deliberately dropped, chosen over keeping story membership inside the fingerprint or splitting opt-in per adopter; (2) the removal ships as a major bump because published shims and a config key are gone. The no-story-oversight-field model came from a direct mid-session correction — 'stories shouldn't have a human-oversight flag' — and its implementation was confirmed in the same turn: oversight fields stripped from 32 stories, the marker writer refuses any non-map file, a leftover confirmed marker approves nothing, and the cutover is hard rather than a lazy drain."
amends: ADR-060, ADR-090, ADR-095, ADR-096, ADR-102
supersedes: ADR-101
consulted: [wr-architect:agent]
informed: []
---

# ADR-103: A release row is the RFC, and the map is the approval surface

## Context and Problem Statement

Two questions were asked in the same session, and they turned out to have one answer.

**First: what is an RFC, in terms of a story map?** The framework said an RFC's story list is an "ordered execution sequence" which "may be a subset of the map's stories, or span across maps", with every relationship many-to-many. In practice that produced RFCs scoped by *theme* rather than by what ships together. RFC-005 owned seven stories on one map; six shipped and one did not, so it was never a release. Its own body already described "Release 1" and "Release 2" in prose — the RFC was describing release rows narratively while the map drew different rows structurally, and the two disagreed.

**Second: what does a human approve?** ADR-090 fingerprints stories *and* maps, so 36 of 50 stories carry their own oversight marker, seven scripts gate on story-level ratification, and eight skills offer a per-story ratify. Every story capture reopened its map's ratification as well, which is why ADR-101 needed an AFK carve-out. The reviewer is approving the same substance repeatedly at two grains.

Underneath both: the RFC tier and the release row were describing the same thing, and the story tier and the map tier were being approved for the same thing.

## Decision Drivers

- A release row already means "everything that ships together". An RFC already means "the controlled, scoped change that fixes a problem". If those are the same set, one of the two artefacts is redundant.
- Duplication had already been removed twice in the same session on the same grounds — a card's `storyStatus` duplicated the story file, and a card's title duplicated the story's title. An RFC's story list duplicates the row's membership. Same shape, third instance.
- Approval should happen where substance is decided, not once per artefact that mentions it.
- Migration cost must be avoidable. Fifty-nine RFC files exist and their IDs are cited from problems, ADRs, stories, commits and changelogs.

## Considered Options

- **A. Leave it.** Keep RFC files and per-story ratification; accept that rows and RFCs describe overlapping sets and that a reviewer approves twice.
- **B. Align RFCs to rows by convention.** Keep both artefacts, add a rule that an RFC's stories must be exactly one row's stories.
- **C. A release row *is* the RFC, and the map is the only approval surface.**

## Decision Outcome

**Chosen option: C.**

**A release row is an RFC.** A row is the set of stories that ship together to fix a problem. It carries an `rfc` identity once a problem proposes it, and `problems` naming what it fixes. A row with neither is drawn but unproposed — a legitimate state, and the one speculative work sits in.

Option B was rejected because a convention between two artefacts is a sync obligation, which is what the previous two de-duplications removed. If a row and an RFC must always agree, one of them is derived.

**Working a problem** now runs: reach Known Error with a root cause and a workaround, then propose the fix as one or more release rows on new or existing maps, recorded on the problem ticket. Implementation is **queued** when the proposal needs a new map, a new activity column, or a new ADR — those are new substance and need a human. It **proceeds** when the proposal uses only maps, columns and decisions already ratified.

**The map is the approval surface; stories are not separately ratified.** A human approves a journey and the releases drawn on it, and every story on that map is approved with it. A story carries **no oversight field at all** — not a marker, and not a declaration that it inherits one. Approval is derived: a story is approved when every map in its `story-maps:` field is ratified. A story naming no map is not approved, so dropping the field cannot self-approve. The marker writer refuses a story outright.

**Row status is derived, never authored** — `delivered` when every story in the row is done or archived, `proposed` when a problem or an RFC names it, `unproposed` otherwise. A stored `status` on a row is ignored, so a pre-migration island cannot outvote the corpus.

### Amendment to ADR-060 (Problem-RFC-Story framework)

The hierarchy clause said story maps and stories are orthogonal to the Problem→RFC chain, that RFCs reference specific stories by ID, and that all three pairs are many-to-many. That is superseded for the RFC↔story edge: **an RFC is a release row on a map**, so an RFC's stories are exactly the stories in that row. Problems↔RFCs stays many-to-many — one fix may need several rows, across several maps. Stories↔maps stays many-to-many; maps remain organisational lenses.

### Amendment to ADR-090 (drift-invalidated human-oversight marker)

Scope narrows to story maps. Stories carry no marker at all. The drift trigger narrows to the map's own substance: what ADR-090 defines as substance *(Enumerated as seven field names until 2026-08-08. Six sites restated the same tuple; by that morning the ADRs still named `lead` and `traceProse`, dead the previous day, while a SKILL had lost live keys. The rule stays here; the list moved to code.)* *(Read “… lead, traces, trace prose and caption” until 2026-08-08. `lead` and `traceProse` left the map format on 2026-08-07. Because the basis includes only keys PRESENT in the island and no map carries either, removing them moved no stored hash and re-opened no ratification — STORY-MAP-002 stayed ratified across the change. Reconciled in place; leaving the enumeration stale would have made this decision the re-introduction vector the code change closes.)* — plus, at the framework tier, a new map or a new ADR. Everything else is outside the basis. Drawing a release row, adding a story to a row, editing a story's body, and restyling the shared template all leave approval intact.

For the **membership** dimension specifically this is write-once, which ADR-090's Reassessment Criteria otherwise forbid: a ratified map absorbs new stories indefinitely without re-ratification. That is the intended reading, not an oversight. ADR-090's no-write-once line protects against *silent substance drift*, and the narrowed basis is what makes membership not-substance: a human approves a journey and the steps in it, and a story that fits an approved step introduces nothing they did not see. Every dimension ADR-090 was defending — the columns, the prose, the traces — still drifts.

### Supersession of ADR-101 (AFK-accept carve-out)

**ADR-101 is superseded and its machinery removed in this change.** The carve-out existed because capturing a story onto its map drifted the map's fingerprint, making the accept condition unsatisfiable by construction. Under the narrowed drift trigger that no longer happens, so there is nothing left to carve out. It answered the question "may a machine accept a *story* without human ratification"; under this decision stories are not separately ratified, so the question does not arise.

The retirement did not wait for the narrowed trigger to be exercised on a real fix, which an earlier draft of this ADR named as the precondition. It proceeded instead on stronger evidence available immediately: a behavioural test showing the card-exclusion is a no-op against the narrowed basis, and a corpus scan showing **no story ever declared `afk-accept: pure-decomposition`** — the carve-out never fired, so its removal changes no observed behaviour.

**ADR-101's opt-in adopter protection is deliberately dropped.** ADR-101 split its change in two: an unconditional tightening, and a *loosening* held behind `afk_accept_pure_decomposition` defaulting to `false`, on the reasoning that "ratifying an ADR is artefact consent; it is not consent to a self-accepting loop." Map inheritance is a strictly wider loosening — a machine may author a story, drop a card on a ratified map, and the story is approved with no opt-in, no whitelist and no parent check — and it ships unconditionally. That was surfaced as its own choice and taken knowingly: the alternative (keeping story membership inside the fingerprint) re-opens the deadlock this decision exists to close, and a per-adopter split would mean two approval paths to keep tested for a distinction few adopters would tune.


### Amendment to ADR-095, ADR-096 and ADR-102

ADR-095 and ADR-096 each carry a back-reference asserting that `accepted` may rest on a machine-written `oversight-basis: pure-decomposition`. That basis no longer exists; both now rest on map inheritance. ADR-102 named `check-afk-accept-eligible.sh` as a load-bearing consumer that must survive (it is deleted), and grounded its single-line `data-story-id` rule in ADR-101's whole-line card filter. That rule is retained — a one-card-per-line island stays far easier to diff and review — but its stated reason is void, and it is now a readability convention rather than a correctness constraint.

## Consequences

- Good: one artefact instead of two for the same concept, and one approval instead of two for the same substance.
- Good: the ratification boundary becomes legible — new journey, new step, or new decision needs a human; scheduling does not. That is a sharper rule than "any content edit reopens approval".
- Good: no migration of the 59 existing RFC files. They stay as legacy records of delivered work. Only **open** problems need updating, and only as they are worked.
- Bad: a row becomes an artefact with an identity and a trace, which is a larger change to the map format than it sounds. Rows previously carried only display fields.
- Bad: this is a hard cutover, not a lazy drain. The oversight fields were stripped from all 32 stories that carried them and the four gating scripts route through one `story_is_approved` predicate, so **every story is unapproved until its map is ratified** — including the 26 whose own `confirmed` marker previously satisfied the gate. A lazy drain was considered and rejected: a story-level marker that could still approve a story on an unratified map keeps the second approval surface alive, and the drain never finishes. The cost is a ratification pass over the seven maps before implementing work can resume.
- Bad: map membership becomes write-once (see the ADR-090 amendment). A ratified map is a standing approval for stories not yet written.
- Neutral: **a fix spanning two journeys is one RFC drawn on several maps.** The row is the RFC, and a row identity is not map-local — stories that must ship together are represented as the SAME RFC row across every map they touch, which is what keeps the maps in step. The problem ticket lists the RFC release rows it needs, in order, and that ordered list is the fix's release plan.
- Neutral: STORY-015 was rewritten rather than closed. Its original ask — that `capture-rfc` author an RFC document shaped like a story map — dissolved, because there is no RFC document to shape. What survived is the ordering it protected, the retirement of the held `--fix-time` byproduct path, and an end-to-end dogfood.

## Confirmation

- A row with all stories done reads `delivered`; a row named by a problem or an RFC reads `proposed`; a row named by neither reads `unproposed`. A `status` stored in the island is ignored — behavioural test.
- Proposing a fix records release rows against the problem ticket, and implementation is refused when the proposal introduces a new map, a new activity column, or a new ADR that is not yet ratified.
- Adding a story to an existing row on a ratified map does not drift that map's oversight fingerprint.
- A story file carries no independent oversight marker; its approval is the map's.
- STORY-MAP-002 renders five rows, two delivered, and RFC-005 appears on exactly one of them.

## Pros and Cons of the Options

**A. Leave it.** Good: no change, no migration, no risk. Bad: a reviewer keeps approving the same substance at two grains, rows and RFCs keep describing overlapping sets, and the ADR-101 carve-out stays load-bearing to work around a self-inflicted deadlock. Rejected because the duplication is the problem, and leaving it does not address it.

**B. Align RFCs to rows by convention.** Good: keeps both artefacts, so nothing is renamed and no ID is disturbed; the rule is easy to state. Bad: a convention between two artefacts is a sync obligation, and a sync obligation between two representations of one fact is exactly what the previous two de-duplications in this area removed. If a row and an RFC must always agree, one of them is derived — and pretending otherwise just moves the drift somewhere quieter. Rejected.

**C. A release row is the RFC, and the map is the only approval surface.** Good: one artefact and one approval for one piece of substance; the ratification boundary becomes statable in a sentence; no migration of the 59 existing RFC files; cross-map coordination falls out of shared row identity rather than needing a mechanism. Bad: a row gains an identity and a trace, which is a bigger change to the map format than it sounds; map membership becomes write-once; and removing the second approval surface is a hard cutover rather than a drain, so every story in the corpus is unapproved until its map is ratified and work stops until that pass is done. Chosen.

## Reassessment Criteria

Reassess if map membership being write-once turns out to hide real substance — the signal is a story landing on a ratified map that a reviewer, shown it, would not have approved. Reassess if the map tier proves too coarse to approve at, the signal being maps re-ratified so often that ratification becomes rubber-stamping — the failure ADR-090's own Reassessment Criteria names. Reassess if shared row identity across maps proves too weak to keep a multi-journey fix in step in practice.
