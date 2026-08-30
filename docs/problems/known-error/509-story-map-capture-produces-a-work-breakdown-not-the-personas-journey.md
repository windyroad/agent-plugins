# Problem 509: Story-map capture produces a work breakdown, not the persona's journey

**Status**: Known Error
**Reported**: 2026-08-21
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — derived at capture. Impact 4: the map is the artefact ADR-103 made the approval surface, so a map that is not journey-shaped degrades the workflow at its most load-bearing point — the human approves a work breakdown believing they approved a journey, and every story on it inherits that approval. It also lands in adopter repos, where it is the first thing a new adopter sees the framework produce. Likelihood 5: all three band triggers hold — known gap, no control (the rules are prose with no derivation step and no check), and observed in the field, where the maintainer had to push three separate times to correct one map.
**Origin**: internal
**Effort**: L — derived at capture. Three coordinated changes to one skill, but two of them are not edits to prose: the title is mechanically derived by construction, and the pre-RFC symptom contradicts a live rule that must first be adjudicated. Sized level with P506 and P508 — a rule has to change, not just a paragraph.
**WSJF**: 10 — (20 × 2.0) / 4 (2026-08-21 review: auto-transitioned Open → Known Error — root cause confirmed + workaround documented; Known Error multiplier 2.0)
**JTBD**: JTBD-008
**Persona**: developer

## Partial release evidence — 2026-08-30

`@windyroad/itil@2.1.5` published from merge/tag commit `959f021b` after implementation commit `69071f8a`. Its changelog records persona-journey title/backbone derivation for capture and manage flows, satisfying symptoms 1 and 3. Symptom 2 remains unresolved: the historical `preRfc` set is still closed, and no replacement carrier or superseding decision has been ratified. P509 therefore remains Known Error at its existing severity and score.

## Description

The story-map capture flow authors the map from **the change being made**, not from **the persona's journey**. The maintainer had to push three separate times, on three separate axes, to get one usable map — reported 2026-08-21:

> The story map it created first was not a true backbone for the user journey for the persona in question. I had to push it to do it properly. I had to push it to include the pre-RFC work. I had to push it to title it correctly. Those are all high priority problems that need to be fixed.

Three symptoms, one root cause. Each is grounded in the emitted artefact and in the SKILL's own mechanics.

### Symptom 1 — the backbone is a technique taxonomy, not a journey

A draft story map emitted in an adopter repo — `docs/story-maps/draft/STORY-MAP-001-convert-source-inspection-pins-to-behavioural-tests.html` — was written with a single backbone column headed **"Conversion technique — backbone ordered by tractability"**. Ordering by tractability is a work-sequencing axis; a journey is what the persona walks through.

`packages/itil/skills/capture-story-map/SKILL.md` line 166 states the rule and gives a worked example:

> **The backbone must be a journey, not a list of invariants.** Activities are steps the persona walks through in sequence. "Finish a change → get it assessed → push it → get through CI → release it" is a backbone.

So the rule is present and correct. Nothing derives the journey from the persona, and nothing checks the result — it is prose the agent can read past, and did.

### Symptom 2 — already-working capability is omitted, and the fix contradicts a live rule

The map showed only the new work, so it could not show which stages of the loop already work and which are broken. The mechanism to express that exists and is in use in this repo: a `preRfc: true` release row, carried by STORY-MAP-002 as "Before the RFC framework" (4 cards) and STORY-MAP-004 as "Already shipped" (1 card).

**But prompting for one at capture is not a gap in an existing affordance — it contradicts the SKILL.** Line 185:

> The only exception is a row holding work that shipped **before rows carried identities**, and such a row says so explicitly with `"preRfc": true`. **That set is closed. Do not add the marker to a new row**: it is a statement about history, not a way to skip allocating an RFC.

That rule exists to stop `preRfc` being used to dodge allocating an RFC identity, which is a real hazard. But it also forecloses the legitimate case the maintainer is asking for: representing capability that genuinely predates this map, so the board shows four healthy stages and one broken one. **This ticket must decide which of the two is wrong** — either the closed-set rule needs an exception for genuinely-pre-existing capability, or already-working work needs a different carrier than `preRfc`. Picking one silently would be the wrong move; they are in direct conflict.

### Symptom 3 — the title is a work description by construction

"Convert source-inspection pins to behavioural tests" names the change. The convention the corpus actually follows is a persona journey — STORY-MAP-002 is "Take a problem from noticed to resolved", STORY-MAP-004 is "Close the loop with someone who reported a problem".

This is not an authoring lapse. The SKILL derives the title mechanically (lines 46 and 73):

> `| Title kebab-slug | Mechanical: first 8-10 non-stopword tokens of description | silent-mechanical |`
> Derive kebab-case title slug from first 8-10 non-stopword tokens of `$description`.

The description is the change being captured. So the title is a restatement of the change **by construction**, and no title convention can hold without changing that derivation. Compare the ADR tier, where P354 established title-as-outcome and `capture-adr` carries an explicit advisory with GOOD/BAD examples plus a question-shape detector (`-vs-`, `should-`, `whether-`, `-or-`). The story-map tier has no equivalent.

## Symptoms

- A map's backbone reads as a work-sequencing or technique axis rather than steps a persona walks.
- A map represents only the delta, so existing working capability is invisible and the board cannot show what is healthy versus broken.
- A map's title restates the change rather than naming the journey.
- All three survive to a ratifiable artefact, and the human is the only check.

## Workaround

Push back, three times, on three axes — which is what happened. Not systematic, and it depends on the maintainer knowing what a story map is supposed to look like. An adopter meeting the framework for the first time has no such prior.

## Impact Assessment

- **Who is affected**: anyone capturing a story map, in this repo and in every adopter repo. Under ADR-103 the map is the approval surface, so the defect sits directly on the governance path.
- **Frequency**: every capture. Three corrections were needed on the single observed instance.
- **Severity**: a human approves a work breakdown believing they approved a journey, and under ADR-119 every story on that map inherits the approval. The artefact is also the framework's shop window in an adopter repo.
- **Analytics**: none. Nothing measures backbone shape, title shape, or whether a map represents existing capability.

## Root Cause Analysis

The capture flow's inputs are the change and its problem trace. The persona appears in the JSON island as a field to fill, not as the thing the backbone is derived **from**. Every downstream defect follows: the title is slugged from the change description, the backbone is authored from the work, and existing capability has no reason to appear because it is not part of the change.

The ADR tier solved the same class on the title axis by adding a stated convention, worked GOOD/BAD examples, and a mechanical shape detector that emits an advisory. That triplet is the shape to copy — but it needs a journey-derivation step ahead of it, because unlike an ADR title, a backbone cannot be checked against a pattern without knowing whose journey it is.

### Investigation Tasks

- [ ] **Adjudicate the `preRfc` conflict first** — it blocks symptom 2. Either the closed-set rule at SKILL line 185 gains an exception for genuinely-pre-existing capability, or already-working work gets a different carrier. Decide, record as an ADR, then implement
- [x] Add a journey-derivation step at capture: read the persona, derive the sequence of steps they walk, and author the backbone from that rather than from the change
- [x] Decide whether the derivation is agent-silent or surfaces the derived journey for confirmation before the map is written — derivation is mechanical from the confirmed persona/JTBD; the existing optional taste prompt may refine the derived title
- [x] Change the title derivation so a map's title names the journey, not the change — the current first-8-10-tokens-of-description slug cannot produce one
- [x] Add a title-shape advisory mirroring `capture-adr`'s (stated convention + GOOD/BAD examples + a detector), using STORY-MAP-002 and STORY-MAP-004 as the GOOD examples
- [x] Add a backbone-shape check — at minimum a detector for the observable failure (a single column, or columns naming techniques/phases rather than persona actions)
- [x] Write behavioural tests: a capture whose description is a change produces a journey-shaped backbone and a journey-shaped title
- [x] Check whether `manage-story-map`'s authoring transition needs the same three rules, since it is the other surface that writes a backbone — it now reuses the capture flow's journey derivation and shape checks before its existing taste prompt

## Iteration 2026-08-30

Symptoms 1 and 3 are implemented through the shared journey-derivation contract and one live behavioural evaluation. Symptom 2 remains deliberately unresolved.

**Outstanding governance decision — symptom 2:** choose either a narrowly evidenced exception to the closed `preRfc` rule for genuinely pre-existing capability, or a different carrier for already-working capability. No choice was made or ratified in this iteration; the existing `preRfc` rule remains verbatim and an ADR is still required before implementation.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the `preRfc` adjudication, for symptom 2 only. Symptoms 1 and 3 are unblocked
- **Composes with**: P457, P354, P508

## Related

Captured via `/wr-itil:capture-problem`. Hang-off arbitration returned `PROCEED_NEW` over four candidates.

- **P457** (`docs/problems/open/457-…md`) — same SKILL, different grain. P457 is about *nothing* having been authored when ratification fires; this is about *what gets authored being the wrong artefact*. The witness map proves they are independent: it had a populated backbone, populated cards and a title, and was still a work breakdown. P457's fix would close P457 and leave all three symptoms here live. They compose — if P457 moves authoring to capture time, that becomes the site these rules attach to.
- **P354** (`docs/problems/verifying/354-…md`) — precedent, not parent. Its scope is the ADR corpus and the architect plugin; its Phase 2 detector is `check-adr-title-shape.sh`. Citing the shape to copy is not hanging off it.
- **P508** (`docs/problems/open/508-…md`) — shares story-map vocabulary; its root cause is the propose-fix gate implementing a superseded lineage. No overlap in tasks.
- **P484** (`docs/problems/open/484-…md`) — "persona" is the shared word, but P484's persona concern is the *reader* (artefacts readable from their own bytes). This one's is the *subject* — whose journey the backbone traces.
- **ADR-103** — makes the map the approval surface, which is why a mis-shaped map is a governance defect rather than a cosmetic one.
- **ADR-119** — a story's approval is inherited from its map, so a mis-shaped map propagates.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-075 | STORY-075: My story map starts from the journey I walk | in-progress |
