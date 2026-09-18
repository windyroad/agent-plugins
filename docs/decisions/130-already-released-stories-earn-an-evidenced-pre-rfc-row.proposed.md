---
status: "proposed"
date: 2026-09-19
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-architect:cog-a11y]
informed: []
reassessment-date: 2026-12-19
supersedes: ["ADR-107 (in part — one sentence only; see 'What this supersedes, and what it does not' below)"]
jtbd: [JTBD-008]
persona: developer
---

# Already-released stories earn an evidenced pre-RFC row

> This record was drafted by the agent that captured the decision, from the discussion in that session. Its sections are the agent's wording, not the maintainer's, and it is not ratified until it is confirmed at the decision review. (Captured via `/wr-architect:capture-adr` per ADR-032, derived-substance amendment 2026-07-06 / RFC-045.)

**In one line:** a story map today can only draw the work being proposed, so it cannot show which stages of a journey already work and which are broken. This lets a map draw a row for stories that have already been released, and it accepts only proof that the release actually happened — never a mention of the work somewhere.

## Context and Problem Statement

A story map is the surface a person approves. Under ADR-103 a release row *is* the request-for-comments identity, and drawing the row is what allocates it.

A map drawn for a fix shows only the fix. The reader cannot tell, from the map, that four stages of the journey already work and one is broken — because the working four were never part of the change being captured, so nothing put them on the board. The maintainer asked for exactly that on 2026-08-21 and had to push for it by hand.

The mechanism to express it already exists and is in use. A row marked `preRfc: true` holds work that shipped before rows carried identities; STORY-MAP-002 carries one named "Before the RFC framework" and STORY-MAP-004 one named "Already shipped". Both are story-backed: every card on those rows names a real story file.

But asking for such a row when a map is captured is not a missing feature — it contradicts a rule that is still in force. ADR-107 states that the pre-RFC set is closed and that no new row can join it. That sentence exists to stop `preRfc` being used to dodge allocating an identity, which is a real hazard: every row is delivered eventually, so "this row is finished" can never be the test.

The two are in direct conflict, and the conflict blocks the symptom this decision addresses: **a captured map cannot show the stages of a journey that already work**. The problem's two other symptoms — a backbone written as a taxonomy of techniques rather than steps a person walks, and a title that restates the change rather than naming the journey — shipped in `@windyroad/itil@2.1.5` and do not depend on this.

ADR-125 already carved a different exception out of that same sentence, for migration: a manifest-bound historical row reconstructed from a retained legacy map, bound to that file's fingerprint, carrying cards that are deliberately *not* story-backed. It scopes this case out explicitly — a newly captured map has no legacy source file to fingerprint, so that mechanism cannot reach it.

## Decision Drivers

- **A map that cannot show what already works cannot show what is broken.** The board's whole value on a fix is the contrast between the healthy stages and the one that is not, and the reader is the person approving the work.
- **The hazard ADR-107 guards is about unshipped work, not shipped work.** The dodge it prevents is skipping an identity for work someone is about to do. Work that has already been released cannot have its proposal skipped — there is nothing left to propose.
- **Delivery must stay unable to earn the marker.** "The stories on this row are all ticked" is exactly the reading ADR-107 rejected, and admitting it here would reopen the whole rule rather than a corner of it.
- **Naming is not shipping.** A card citing a decision, a skill file present on disk, or a ticket closed without a released version behind it is an audit annotation, not evidence a capability exists.
- **Relax one rule, not two.** ADR-125 holds that every ordinary card must name a real story file, and rejected writing story files after the fact because reconstructed records imply evidence that never existed. A capture-time exception that also relaxed the card rule would be overturning two confirmed rules while claiming to overturn one.
- **The supersession chain has to stay readable.** `preRfc` already carries two mechanically distinct forms after ADR-125. A third structure for the same idea would cost more than the rule it buys.
- **Maintainer direction, 2026-09-19**, pinning supersession-with-a-narrow-exception over a new carrier, after the options were queued during an earlier session the maintainer was not present for.

## Considered Options

1. **A narrowly evidenced exception to the closed set, on story-backed cards only (chosen)** — a newly drawn row may carry `preRfc: true` when every card on it names a real story that has already been released, proven by evidence of the release rather than by a mention of it.
2. **The same exception, but admitting cards with no story file** — would let a row name capability that was delivered before story files existed. Rejected for three reasons. First, it would overturn the rule that every ordinary card must name a real story file. Second, it would cover the same ground as the migration mechanism, which already handles rows reconstructed from an old map. Third, the only way left to satisfy it would be to write story files after the fact for work that was never recorded that way, which was rejected when the migration rule was set.
3. **A separate carrier for already-working capability** — leave the historical set closed and add a distinct field or row subtype meaning "this already works". This was the standing recommendation before the maintainer's direction.
4. **Leave the set closed** — the status quo. The symptom stays unfixed and the maintainer keeps correcting maps by hand.
5. **Reuse ADR-125's manifest-bound historical subtype** — extend the migration mechanism to capture.

## Decision Outcome

Chosen option: **"A narrowly evidenced exception to the closed set, on story-backed cards only"**, because the rule being relaxed was written against a hazard that released work cannot pose, and reusing a row shape that already appears on existing maps — with its card rule untouched — costs less than a second way to say the same thing.

### What a newly drawn pre-RFC row must satisfy

A row captured onto a map may carry `preRfc: true` only when **all** of the following hold.

- **Every card on the row names a real story file, exactly as an ordinary card does.** ADR-125's rule is untouched: a card naming no story is still invalid, here as everywhere. This is the whole reason the exception can be stated in one sentence — the row changes, the card does not.
- **Every one of those stories is `done` and its release is recorded.** Both parts matter. A story marked `done` but not released does not qualify; that is the delivery reading this decision refuses.
- **The recorded release is a release, not a mention of one.** Exactly three things count as a recorded release, and nothing outside this list counts:
  1. a released package version that carries the story's change;
  2. the `## Fix Released` section of a problem report that the story closed;
  3. a problem report that the story closed, where the reason recorded for closing it names a released version.

  Every other form of backing is inadmissible. Some examples, and this list is not exhaustive: the existence of a decision record; a skill or hook file present on disk; a ticked acceptance criterion; a ticket mentioned without a version; **a change merged but not yet released**. Naming is not shipping.
- **The row carries no `rfc` and contributes no identity.** Unchanged from ADR-107 — the map's request-for-comments list is still the union of its rows' identities, and a pre-RFC row adds nothing to it.

**Guidance, not a gate:** the row's name should say in plain language that the capability already works — for example, "Before the RFC framework" or "Already shipped". This is how a reader tells at a glance what the row is for. It is deliberately not one of the conditions above, because no check can test it.

### What happens to a row that asks for the marker and does not qualify

It is **not** refused. It becomes an ordinary row, and the ordinary rules apply to it unchanged — so a row with no identity renders with the red "Untraced" badge and is visible as a defect on the board.

Demotion applies to the row, not to its cards. The card rule is still hard: a card naming no story file is invalid whether or not the row asked for the marker, and demotion does not rescue it.

This follows ADR-107's own posture. ADR-107 weighed refusing to render such a map and rejected it as premature, on the grounds that the badge already makes the defect visible. Adding a hard stop here would reverse that call for this one case without the evidence that would justify it.

### What this does to the map's approval

An evidenced pre-RFC row drawn at capture takes ADR-103's ordinary treatment: drawing it does not re-open the map's approval, and it does not join the oversight fingerprint.

This differs from ADR-125's manifest-bound historical rows, which do join the fingerprint, and the difference follows from the card rule above. A manifest-bound row carries reconstructed content that no story file holds, so a human has to approve that content; there is nowhere else it was ever approved. An evidenced row carries nothing a story file does not already say — per ADR-104 its status, value and problems are all read from the story when the map renders — so there is no new substance for a human to approve. It only shows records that were already approved where they live.

### What this supersedes, and what it does not

This supersedes exactly one sentence of ADR-107: that the pre-RFC set is closed and no new row can join it. A new row may join it under the conditions above, and under no other circumstance. ADR-125 already carved a different exception out of that same sentence, for migration; the two exceptions do not overlap.

Everything else in ADR-107 stands verbatim, and **ADR-107 is not renamed to `.superseded.md`** — it remains in force. The map's request-for-comments list is still derived from its rows. A row with neither an identity nor the marker is still a defect and still renders with the red "Untraced" badge. **Finishing a row still earns nothing** — a row whose stories are merely all ticked has not been released and does not qualify. ADR-125's manifest-bound historical subtype is untouched and remains the only path for a row reconstructed from a retained legacy map, and its rule that every ordinary card must name a real story file is untouched here.

Per ADR-116 the superseded body is not edited. This decision supersedes it in part.

### Why this cannot become the dodge ADR-107 prevented

The dodge is drawing a row for work you are about to do and marking it pre-RFC so you never have to propose it. The evidence test forecloses it structurally: the marker requires a release that already happened, and work you have not done has not been released. Work that is written and merged but unreleased is excluded too, which is the case closest to the line. There is no state in which a row escapes its identity by being about to be built.

### Why the other options were rejected

The separate carrier for already-working capability, and leaving the set closed, were rejected by maintainer direction. Admitting cards with no story file was rejected because it overturns a second confirmed rule while claiming to overturn one. Reusing ADR-125's manifest-bound historical subtype was rejected on mechanism: its manifest binds each historical row to a fingerprint of a retained pre-migration file, and a newly captured map has no such file, so there is nothing for the validator to recompute against.

## Consequences

### Good

- A map drawn for a fix can show the whole journey — the stages that work and the one that does not — which is what makes it an approval surface rather than a task list.
- The existing row shape carries it. No new field, no second structure, nothing added to the format a reader has to learn, and no change to what a card is.
- Because the row's substance lives in the story files, approval needs no re-ratification and the record stays derived rather than restated.

### Neutral

- `preRfc: true` can now arrive on a map in three ways: the original closed historical rows, ADR-125's manifest-bound migration subtype, and this evidenced capture form. The first two are story-backed and manifest-backed respectively; this one is story-backed and release-evidenced.
- Capture needs to read release evidence it did not previously read.

### Bad

- **This does not reach capability delivered before story files existed.** A map can therefore show already-working stages when they have story files behind them, and still cannot show capability delivered before story files existed. The alternatives are the after-the-fact story files ADR-125 rejected, or a second supersession this decision deliberately declines; for a retained legacy map ADR-125's migration path already covers it.
- The evidence test is a judgement the capture flow now has to make, and it is exactly the kind of judgement that decays into "the ticket says it is closed, good enough". The rule's whole value is in refusing that reading.
- A rule stated once as closed is now open in two places. A reader has to hold both exceptions to know the shape of the set.
- Nothing yet enforces any of this. Until the capture flow checks it, the rule is prose, which is the failure mode the driving problem records in the first place.

## Confirmation

- A capture that marks a row `preRfc: true` where every card names a released story produces that row, and the map renders it as delivered history — behavioural test.
- A row asking for the marker where any card names a story that is not `done`, or whose release is not recorded, is demoted to an ordinary row rather than refused, and with no identity it renders with the "Untraced" badge — behavioural test.
- A row whose stories are all `done` but unreleased does not qualify, so delivery still earns nothing — behavioural test.
- A row backed only by a change merged but not yet released does not qualify — behavioural test, because this is the case nearest the line.
- A row backed only by a mention — an existing decision record, a skill file on disk, a ticked acceptance criterion — does not qualify, so naming cannot pass for shipping — behavioural test.
- A card on such a row that names no story file is refused by the existing rule for ordinary cards, unchanged by this decision — behavioural test, and ADR-125's existing test covering this must still pass unchanged.
- A newly drawn pre-RFC row contributes no request-for-comments identity to the map's derived list — behavioural test, and the existing ADR-107 test covering this must still pass unchanged.
- Drawing such a row does not invalidate the map's human-oversight marker — behavioural test against the fingerprint.
- An ordinary row with no identity and no marker still renders with the "Untraced" badge — the existing ADR-107 test passes unchanged.
- ADR-125's manifest-bound historical rows behave exactly as before — the existing migration tests pass unchanged.

## Pros and Cons of the Options

### A narrowly evidenced exception on story-backed cards only

- Good, because the map gains the working stages of the journey without the format gaining a concept.
- Good, because exactly one sentence of one decision changes, so the supersession chain stays readable.
- Bad, because it puts a judgement call at capture time that will quietly degrade unless something checks it.
- Bad, because capability older than story files stays undrawable on a newly captured map.

### The same exception, admitting cards with no story file

- Good, because it would reach capability of any age, fixing the symptom outright.
- Bad, because it silently overturns a second confirmed rule, and its content would have nowhere it was ever approved.

### A separate carrier for already-working capability

- Good, because the historical rule stays closed and unambiguous.
- Bad, because it is a second structure for what rows already express, on a format that has repeatedly had duplication removed for that reason.

### Leave the set closed

- Good, because nothing changes and no new rule has to be enforced.
- Bad, because the maintainer keeps hand-correcting every map, and someone new to the framework has no example showing them to do it, so their maps carry the same defect.

### Reuse ADR-125's manifest-bound historical subtype

- Good, because the validation is already built and already strict.
- Bad, because it validates against a fingerprint of a retained legacy file, and a newly captured map does not have one.

## Reassessment Criteria

Reassess no later than 2026-12-19, or sooner if:

- a newly drawn pre-RFC row is found holding a story that had not been released when it was drawn;
- the evidence test is satisfied in practice by a mention rather than a release, which would mean the distinction is not being applied;
- demoting an unqualified row rather than refusing it turns out to let bad rows through unnoticed, which would reopen ADR-107's rejected hard-stop option for this case;
- the pre-story-file gap named under Bad turns out to bite often enough that the second supersession is worth its cost;
- a reader mistakes a pre-RFC row for current in-flight work on an approved map; or
- the three ways a row can carry the marker prove indistinguishable to someone reading a map.

## Related

- **ADR-107** (a story map's request-for-comments list is derived from its release rows) — superseded in part, in one sentence only; otherwise in force.
- **ADR-103** (a release row is the RFC, and the map is the approval surface) — why a mis-shaped map is a governance defect, and the approval treatment this row inherits.
- **ADR-104** (a story map card stores no value a story file already carries) — why an evidenced row adds no substance to approve.
- **ADR-116** (ratified decisions change only by supersession) — why this is a new decision rather than an amendment.
- **ADR-125** (manifest-bound historical pre-RFC rows for story-map migration) — the first partial supersession of ADR-107, for migration; it scopes this case out explicitly, and its ordinary-card rule is untouched here.
- **ADR-129** (only shipped-and-released evidence closes a ticket) — the same reasoning about naming versus shipping, reached independently for ticket closure. This decision states its own admissible and inadmissible lists in full and does not depend on that one.
- **Problem 509** (`docs/problems/known-error/509-story-map-capture-produces-a-work-breakdown-not-the-personas-journey.md`) — the driver; specifically its symptom that a captured map cannot show the stages of a journey that already work.
- **JTBD-008** — a developer decomposing a fix into coordinated changes needs a journey-shaped approval surface.
