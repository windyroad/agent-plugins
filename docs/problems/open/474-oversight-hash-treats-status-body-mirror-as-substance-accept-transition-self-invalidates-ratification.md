# Problem 474: Oversight hash treats the `**Status**:` body mirror as substance, so an accept transition self-invalidates its own ratification

**Status**: Open
**Reported**: 2026-07-29
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-001, JTBD-006
**Persona**: developer

## Description

`oversight_content_hash` in `packages/itil/lib/story-oversight.sh` excludes the frontmatter `status:` key and normalises acceptance-criterion checkbox ticks, but nothing normalises the `**Status**:` body line that every story template mirrors the status in. The grep filter is line-start-anchored on `^status:`, so it cannot match `**Status**: accepted`. `oversight_content_hash_excluding_stories` carries the identical omission.

Consequence: advancing a story from `draft` to `accepted` drifts its own oversight hash, so a story the maintainer genuinely ratified reads as unratified the instant it is accepted — and `itil-no-implement-draft-gate` then denies the implementing commit until someone re-ratifies. The lib's own comment (line 26) and the shipped `@windyroad/itil@0.60.0` changeset prose both promise the opposite: *"ticking an acceptance criterion or advancing its status does not count as a change"*. That guarantee is only half-implemented — the frontmatter half holds, the body-mirror half does not.

Shipped in `@windyroad/itil@0.60.0` on 2026-07-29. Per the capture-time hang-off arbitration, the defect was introduced by P404 Phase 2 (which delivered the lazy-fingerprint machinery on 2026-07-03), and P465 did not cause it — P465 only made a latent defect observable, by making a matching hash a precondition of the implementing commit.

Reproduced 2026-07-29 with two controlled experiments on STORY-047: reverting only an added acceptance criterion still drifted, and reverting only the body `**Status**:` line still drifted. Each drifts independently, so the body mirror is a genuine, sufficient cause. Hit live in the same session — STORY-047 had to be re-ratified after its accept transition purely to clear this, which is why the observation exists at all.

Also affected, and independent of P465's gate: `wr-itil-detect-unratified-stories-maps` and `wr-itil-check-rfc-stories-ratified` both consume the same hash, so both report a falsely-unratified story after any accept transition.

### RESOLVED 2026-07-30 — a third option the capture did not consider

The capture below framed this as a choice between two migration paths for a hash-algorithm change. The maintainer picked neither: on 2026-07-29 they directed **removing the duplicated line instead of teaching the hash to ignore it**, on the grounds that this was the fourth lifecycle mirror in a family of three with a fifth anticipated — normalising costs one rule per mirror indefinitely, removal ends the class.

That reframing dissolved the migration problem the capture treated as blocking. Because no hash function changes, no already-stored fingerprint is invalidated when the fix reaches an adopter; only artefacts still carrying the mirror need migrating at all. The legacy-hash fallback recorded as option (b) below was also **tested and disproved** before being abandoned: an artefact ratified under the shipped algorithm has the mirror inside its stored hash, so after an accept transition the stored value matches neither the old nor the new function — dual-accept leaves the accept transition just as broken.

Fix vehicle: **RFC-059**, story **STORY-054**, both tracing this ticket. Contract recorded in ADR-090's 2026-07-29 amendment. Migration ships as `wr-itil-migrate-story-status-mirror` (PATH-shimmed per ADR-049 so adopter corpora can run it), re-fingerprinting under a validity gate and a mirror-agreement precondition — never re-ratifying.

A separate finding surfaced while recording the contract, and it is arguably the more significant one: ADR-090's Decision Outcome said "**any change** invalidates" and had been false since 2026-07-03, when the narrowing to "any *substance* change" shipped recorded only in a code comment and a changeset. It was never put to the maintainer as a decision. It is now recorded retroactively, ratified 2026-07-30 in isolation, and the Outcome text reconciled.

### The original capture-time framing (superseded — retained for audit)

The one-line fix is to extend the existing `sed` with `s/^\*\*Status\*\*:.*$/**Status**:/`, anchored on the exact `**Status**:` token so prose like `**Status quo**: …` still counts as substance. It was written with three bats cases (body-mirror advance does not drift; frontmatter + body advancing together does not drift; `**Status quo**:` prose still drifts) and went GREEN, then was **deliberately reverted and not shipped**.

Reason for the revert: changing the hash algorithm silently invalidates the stored hash of all 30 currently-confirmed story and story-map artefacts. The two discharge paths are both consequential enough to be the maintainer's call under ADR-044's framework-resolution boundary:

- **(a) Re-mark the corpus** — re-run `mark-story-oversight-confirmed.sh` over the 29 other artefacts. Rejected as written, because it writes `confirmed` markers with no human confirm event behind them, which is exactly the P348 hollow-marker class.
- **(b) Legacy-hash fallback** — have `is_story_map_ratified` accept either the pre-fix or post-fix hash, so existing ratifications survive and only new ratifications use the corrected algorithm. Costs a dual-hash comparison and a documented sunset.

Shipping the fix without choosing converts a *fail-closed* friction defect into a *fail-open* ratification-integrity defect across the whole corpus, which is the worse direction. Hence: captured and queued rather than guessed.

## Symptoms

- A story transitioned `draft` → `accepted` immediately reads as unratified, despite carrying `human-oversight: confirmed`.
- `itil-no-implement-draft-gate` denies a commit whose `Refs: STORY-NNN` trailer names that story.
- `wr-itil-detect-unratified-stories-maps` lists the story as needing ratification straight after it was ratified.
- Re-running the marker shim clears it, so the symptom looks transient and self-healing — which is why it can be mistaken for correct drift-invalidation rather than a defect.

## Workaround

Re-ratify the story after the accept transition (`mark-story-oversight-confirmed.sh <file>`). Legitimate only when a genuine human confirm event covers that story; otherwise it manufactures a hollow marker.

## Impact Assessment

- **Who is affected**: any adopter on `@windyroad/itil@0.60.0`+ who accepts a story and then implements it — the ADR-096 happy path.
- **Frequency**: every accept transition, so once per story.
- **Severity**: fail-closed. Blocks legitimate work and costs a redundant re-ratification per story; does not admit unratified substance.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

Line-start anchoring on `^status:` in the exclusion grep at `packages/itil/lib/story-oversight.sh:28` cannot reach the markdown body mirror `**Status**: <value>`. The adjacent `sed` at line 29 normalises the HTML `data-status="…"` mirror and the checkbox ticks, so the markdown body mirror is the one lifecycle surface with no normalisation. Confirmed by controlled experiment rather than inspection alone.

### Investigation Tasks

- [x] Decide the migration path — resolved 2026-07-29 by a third option neither (a) nor (b): remove the mirror, leaving the hash untouched. See the resolution section above.
- [x] ~~Land the `sed` normalisation in both hash functions~~ — **not done, and correctly so.** Superseded by the removal approach; neither hash function is touched.
- [x] ~~Re-add the three bats cases~~ — superseded. Replaced by 10 behavioural cases over the migration instead.
- [x] Ship the migration PATH-shimmed so adopter corpora can run it, not only this repo's.
- [x] Remove the mirror from BOTH template carriers — the `capture-story` scaffold and `docs/stories/README.md`. The second was missed on the first pass and caught in review; it is the adopter-facing one, since `reconcile-stories.sh` reads the adopter's own stories README.
- [x] Cross-reference P465 so its released "advancing status is progress" promise is not read as already holding.
- [x] Wire the idempotent migration into a self-firing surface — shipped in `@windyroad/itil@0.61.0` as `itil-story-mirror-migration-nudge.sh` on `SessionStart`, with 11 behavioural cases. Nudge-only (never migrates, because reviewing the rewrite before it ships is a ratified JTBD-009 outcome), names the PATH shim rather than a repo-relative path, silent on a clean corpus.
- [x] Audit for any other lifecycle mirror with the same shape. **Done 2026-07-30, and it reframed the defect class.** Findings:
  - Exactly two tiers carry a real oversight fingerprint — `docs/stories` and `docs/story-maps`. Every `oversight-hash` occurrence under `docs/rfcs`, `docs/decisions` and `docs/problems` is prose, not a frontmatter field, so the fingerprinted surface is exactly what ADR-090 scopes.
  - Of the four frontmatter keys the hash excludes (`human-oversight`, `oversight-hash`, `oversight-basis`, `status`), only `status` ever had a body mirror. That was this ticket.
  - **The defect class is asymmetry, not duplication.** Six other body↔frontmatter mirrors exist in stories (`**Estimated effort**`, `**JTBD**`, `**Problems**`, `**RFCs**`, `**Reported**`, `**Story Maps**`) and are all fine, because the hash excludes *neither* copy — editing either correctly drifts, since those genuinely are substance. The hazard is latent rather than live: add an exclusion for any of those keys (tempting for `rfcs:` / `story-maps:`, which the reverse-trace helpers auto-maintain) and its body mirror instantly reproduces this ticket.
  - Therefore the audit is being converted into a permanent invariant rather than left as prose: for every key the hash excludes, assert no body mirror exists. Carried by STORY-055.
- [ ] **Story-map card `href`s encode lifecycle state inside the map's hashed content** — the same asymmetry on the HTML leg, found during the audit. A card links `../../stories/<state>/STORY-NNN-….md`, so the state segment is hashed, while the card's own `data-status` is normalised out. Currently masked by href rot: STORY-047 sits in `accepted/` while STORY-MAP-005 and STORY-MAP-011 both link `draft/`, and STORY-018 is in `draft/` while STORY-MAP-002 renders `data-status="done"`. So exactly one of two defects is live — either those hrefs are broken links, or repairing them re-opens every map's ratification on a pure lifecycle transition. Decision-shaped (drop the state segment from hrefs / normalise the path segment in the map filter / accept the rot), so it needs its own ask rather than a silent pick.
- [ ] Extract the duplicated grep/sed filter shared by `oversight_content_hash` and `oversight_content_hash_excluding_stories`. Out of RFC-059's own scope by its explicit record — carried by STORY-055 under an RFC-059 scope amendment. Note the extraction boundary is the real risk: the two functions' input paths already differ on trailing-newline handling (one pipes the file directly, the other round-trips through `$(cat)` which strips trailing newlines), so extract the FILTER only and leave each input path alone, or the hash silently changes for artefacts with anomalous trailing whitespace and all 19 stored fingerprints break.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the migration-path decision above (maintainer-owned)
- **Composes with**: P465, P404

## Related

Captured via `/wr-itil:capture-problem`. Sub-step 2b hang-off arbitration returned **PROCEED_NEW** against candidates P465, P404, P472, P457, P462 — the fresh-context subagent found that no candidate owns the hash-algorithm locus, and that the queued migration decision sits outside every candidate's scope. Its per-candidate reasoning:

- **P465** (story accepted-gate does not enforce ADR-090 ratification) — closest candidate and the reason this became blocking, but a different problem: its confirmed root cause is that no ratification check existed at any locus, its fix loci are the `manage-story` accept gate and `itil-no-implement-draft-gate`, and all its investigation tasks are closed and released in 0.60.0. It made a latent hash defect observable; it did not create it. P465 should gain a cross-reference so its released guarantee is not read as already holding.
- **P404** (implement ADR-089/090) — the delivery ticket that introduced the machinery on 2026-07-03, so this is where the omission originated. Not absorbed: P404 is in Verifying after two reopens with residual scope on authoring and lineage integrity, and a third reopen for a one-line `sed` plus a corpus-migration decision would make it unclosable.
- **P472** (reconcile-stories false MISSING_REVERSE_TRACE) — shares only the ADR-090 citation and the false-positive-detector shape; its fix is a reverse-trace predicate and never touches the hash. Sibling surface, not parent.
- **P457** (story-map ratify-before-author inversion) — concerns whether ratification should fire at that stage at all; this defect is input normalisation downstream of that question.
- **P462** (amendment-scoped unconfirmed has no detector) — different plugin, different tier, and the opposite failure direction (unratified substance invisible, versus ratified substance falsely invalidated).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-059 | proposed | Lifecycle state is not duplicated inside hashed story content |


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-054 | STORY-054: Lifecycle transitions preserve a story's ratification | accepted |
