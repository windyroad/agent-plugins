---
status: "proposed"
date: 2026-07-02
human-oversight: confirmed
oversight-date: 2026-07-30
oversight-confirmed-date: "2026-07-02 — batched ratification via AskUserQuestion: user ratified drift-invalidated marker for story maps AND stories, RFC references only ratified stories; user explicitly confirmed stories are ratified as first-class, not just maps. 2026-07-30 — second ratification, of a different clause: the substance-only invalidation trigger (excluding frontmatter status:, acceptance-criterion ticks, slice data-status) that shipped unrecorded on 2026-07-03. Put in isolation with both members of {substance-only, literal any-change} in view; answer verbatim: 'I agree with the narrowing'. The Decision Outcome text was reconciled in the same commit."
oversight-note: "substance (a story map / story carries a drift-invalidated human-oversight marker — re-ratify on any change; RFCs reference only ratified stories) user-picked via AskUserQuestion 2026-07-02 (marker semantics = drift-invalidated, not write-once); born unconfirmed pending the batched ratification pass this session (P348)"
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-02
amends: [ADR-060]
---

# Story maps and stories carry a drift-invalidated human-oversight marker

## Context and Problem Statement

The framework already ratifies auto-made or drift-prone governance artefacts before dependent work relies on them: ADR-066 gives decisions a write-once `human-oversight:` marker + a `/wr-architect:review-decisions` drain; ADR-068 mirrors it for JTBDs + personas (P283/P288 — auto-made artefacts drift poorly, so lift them to human confirmation). ADR-074 generalises it: confirm substance before building dependent work.

The **story-map / story tier has no such axis.** ADR-060 gives a story map a `draft → accepted → in-progress → completed → archived` lifecycle, but `accepted` is a *lifecycle* state, orthogonal to whether a human ratified the map's *content* — exactly the `status:` ≠ `human-oversight:` orthogonality ADR-066 draws. So a story map can be edited (stories added, re-sliced, reused) with no gate ensuring a human re-affirmed it before an RFC leans on its stories.

User direction (2026-07-02): **"we should have a USM ratification step, needed whenever we make a change to the USM. We should not be allowed to reference USM stories in the RFC if the USM is not ratified."** The decision: does the story-map marker follow ADR-066's **write-once** shape (ratify once; re-open only via explicit reassessment), or a **drift-invalidated** shape (any change auto-invalidates ratification, forcing re-ratify)?

## Decision Drivers

- **"After any change"** — the user's wording implies the ratification must not survive an edit; a silent change to a ratified map must force re-ratification.
- **Consistency with the oversight family** (ADR-066/068) — a new tier's marker should be recognisable to the same detector/drain family.
- **The reference gate** — an RFC (which, per the sibling decision, always has ≥1 story) must not list an unratified story; this couples the two decisions.
- **Not re-inventing write-once** — ADR-066's marker is deliberately write-once (a decision, once ratified, stays ratified until reassessed). A story map is a *living* artefact edited across many fixes, so its ratification semantics genuinely differ.

## Considered Options

1. **Drift-invalidated marker** — any edit to a story map (or a story on it) auto-invalidates its `human-oversight: confirmed` marker, forcing re-ratification before the map is relied on again. Marker lifecycle closer to ADR-009's TTL/drift gate-marker than to ADR-066's permanent marker.
2. **Write-once marker (ADR-066 parity)** — ratify once; the marker persists until someone explicitly re-opens the map for reassessment. Consistent with the existing marker family, but a silent edit would not force re-ratification.

## Decision Outcome

Chosen option: **"Drift-invalidated marker"** (Option 1), because it is what the user's "ratify after **any** change" literally requires and what the stated purpose demands — you must not rely on a story map that changed since it was ratified. A story map is a living artefact (edited across many fixes), unlike an ADR (a settled decision), so write-once parity would leave the exact gap the requirement targets: a ratified-then-silently-edited map still reading as ratified.

**The rule:**

- A story map and each story on it carry a `human-oversight:` marker (`unconfirmed` / `confirmed`), orthogonal to the `status:` lifecycle — mirroring ADR-066/068 as a third sibling in the oversight family.
- **Any SUBSTANCE change** to a story map or a story (add / edit / re-slice / reuse / retitle) **invalidates** its `confirmed` marker back to `unconfirmed` — a drift-invalidated marker, not a write-once one. Re-ratification (human confirm) is required before the map is relied upon again. Lifecycle progress is **not** a substance change: advancing `status:`, ticking an acceptance criterion, and advancing a slice's `data-status` all leave ratification intact, because none of them revises what the human ratified. *(This bullet read "Any change" until 2026-07-30. The narrowing shipped 2026-07-03 and is recorded retroactively in the Amendments section, where it was ratified 2026-07-30; the Outcome text is reconciled here so the rule of record and the rule in force finally agree.)*
- **An RFC may reference only ratified (`confirmed`) USM stories.** `capture-rfc` / `manage-rfc` gate the `stories:` list on story-ratification: an RFC cannot list an unratified story. This composes with the sibling decision (every RFC has ≥1 story): the atomic fix's single story must itself be ratified before its RFC references it.
- Unratified story maps surface for ratification the same way unoversighted decisions/JTBDs do (a detector + a review/drain surface, mirroring `wr-architect-detect-unoversighted`).

This lands as a new ADR (sibling of ADR-066/068 — a cross-cutting oversight primitive, not framework-ADR-internal) and drives lockstep in-place edits to ADR-060's story-map/story lifecycle, schemas, and invariants.

## Consequences

### Good

- Fills a real governance gap — the story-map tier joins the ratified-before-relied-on discipline the decision + JTBD tiers already have.
- The drift-invalidated shape makes ratification meaningful for a *living* artefact: a changed map is never silently trusted.
- The RFC reference-gate closes the loop with the sibling ≥1-story decision — every RFC's stories are real, ratified stories.

### Neutral

- A third oversight sibling (decisions / JTBDs+personas / story-maps+stories) — consistent family, one more detector + drain surface.

### Bad

- **A drift-invalidated marker is a genuinely new marker mechanism** — different from ADR-066/068's write-once markers. It needs its own re-open-on-edit trigger (hook or skill-side), which is more moving parts than parity would be. Accepted because write-once cannot satisfy "re-ratify after any change."
- More ratification friction: every map edit re-opens ratification. Mitigated by batching (ratify a map once after a coherent set of edits, not per-line).

## Confirmation

- A story map / story with an edit newer than its `oversight-date` reads as `unconfirmed` (drift-invalidation fires) — asserted by a behavioural test.
- `capture-rfc` / `manage-rfc` refuse to list an unratified story in an RFC's `stories:` — asserted by a behavioural test.
- A detector surfaces unratified story maps (mirroring `wr-architect-detect-unoversighted` for decisions).

## Pros and Cons of the Options

### Option 1 — drift-invalidated (chosen)

- Good: matches "re-ratify after any change" literally; a living artefact is never silently trusted after an edit.
- Bad: new marker mechanism (re-open-on-edit trigger); more moving parts than parity.

### Option 2 — write-once (ADR-066 parity)

- Good: reuses the existing marker family unchanged.
- Bad: a silently-edited ratified map still reads as ratified — the exact gap the requirement targets.

## Reassessment Criteria

Revisit if the re-ratify-on-every-edit friction proves heavier than the drift risk it prevents (e.g. maps churn so often that ratification becomes rubber-stamping). The remedy would be to coarsen the drift trigger (ratify per coherent edit-set) — not to drop to write-once, which reintroduces the silent-drift gap.

**Exercised twice — 2026-07-03 and 2026-07-26.** The first exercise went unrecorded here for three weeks and is corrected in the 2026-07-29 amendment below; the "once" this sentence previously claimed was wrong. That first exercise has since been **absorbed into the Decision Outcome itself** (reconciled 2026-07-30, ratified the same day), so it is no longer a coarsening *of* the rule — it is the rule. It is retained here for history. The 2026-07-26 exercise (ADR-101) remains a genuine coarsening and was narrow: ADR-095 compels every new story to add a card to its map, so "any change" made the AFK-accept carve-out unsatisfiable by construction — capturing the story broke the condition the story had to satisfy. ADR-101's map leg therefore hashes the map with the accepted story's OWN card excluded, which coarsens the trigger to a coherent edit-set exactly as anticipated here. It is not a drop to write-once: any map edit other than adding that one card still drifts the hash and still re-opens ratification.

## Related

- **ADR-066** — human-oversight marker + review-decisions drain (the write-once precedent this diverges from, deliberately, for a living artefact).
- **ADR-068** — JTBD + persona oversight sibling (the "mirror ADR-066 for a new tier" precedent this follows).
- **ADR-060** — Problem-RFC-Story framework (its story-map/story lifecycle, schemas, and invariants gain the ratified axis — lockstep edits).
- **ADR-074** — confirm substance before building dependent work (the general principle).
- **ADR-009** — gate-marker TTL/drift lineage (the drift-invalidated marker's mechanism precedent).
- **Sibling ADR — "Every RFC has at least one story"** — composes with this: every RFC has ≥1 story AND those stories must be ratified before the RFC references them.
- **P283 / P288** — auto-made artefacts drift; lift to human ratification. **JTBD-008** — the decompose job whose story-map artefacts this governs.
- **Implementation ticket** (to be logged) — the marker field + write path in the story-map/story skills, the drift-invalidation trigger, the RFC reference-gate in capture-rfc/manage-rfc, the unratified-map detector, and behavioural bats.

## Amendments

### 2026-07-03 — Substance-only fingerprint (recorded retroactively 2026-07-29)

The Decision Outcome above says **"any change"** invalidates the marker. That is not what has been shipping since 2026-07-03. Commit `35b07f6` narrowed the trigger to **any SUBSTANCE change**, excluding lifecycle-progress state from the fingerprint: the frontmatter `status:` key, acceptance-criterion checkbox ticks, and slice `data-status`. The rationale is sound — ticking a criterion or advancing status is progress, not a revision of what the human ratified, and invalidating on those made ratification expire on every routine transition.

It was recorded only in a code comment, a changeset, and RFC-037's Confirmation. It was never recorded here, so for three weeks the authoritative decision record described a stricter rule than the one in force. Per ADR-066's own test this narrowing changes the Decision Outcome (it loosens it) rather than tightening a mechanism, so it required an amendment and did not get one. Recorded now, retroactively, because the record being wrong about its own contract is what allowed the defect below to be built and shipped without anyone noticing the contract had moved.

**Ratification status: RATIFIED 2026-07-30.** The record distinguishes two events, and the distinction is load-bearing — collapsing them would retro-launder a non-selection into consent.

**2026-07-29 — evidence, not ratification.** The maintainer was offered, as one of three options for fixing the P474 defect below, "honour *any change* literally and accept re-ratification on every transition" — i.e. reverting this narrowing — with its cost stated, and declined it in favour of removing the mirror. That is evidence the narrowing is wanted. It was **not** ratification of it: the set presented was a fix-mechanism set in which the revert appeared only as collateral of one branch, not this narrowing's own option set of {substance-only, literal any-change}, so selecting a fix mechanism did not select from it. This amendment recorded that gap as OPEN rather than closing it by its own assertion, which would have been the P348 hollow-marker shape.

**2026-07-30 — the ratifying event.** The narrowing was then put to the maintainer in isolation, with both members of its own option set in view: they were told plainly that the rule of record is "any change invalidates" while the rule in force since 2026-07-03 is "any *substance* change", and that the latter had never been recorded or put to them. Their answer, verbatim: *"I agree with the narrowing."* That is a direct, informed selection from {substance-only, literal any-change} — the standing recorded rule was named as the live alternative, not buried as a side effect of a fix choice — so it satisfies the option-set requirement this paragraph was written to enforce. The Decision Outcome text above is reconciled in the same commit; the rule of record and the rule in force now agree.

### 2026-07-29 — Lifecycle state is not duplicated inside hashed content (P474)

**The defect.** Every story template mirrored the frontmatter `status:` in a `**Status**:` body line. The 2026-07-03 narrowing excluded the frontmatter key — the grep is anchored `^status:` — but nothing excluded the body copy, and no normaliser covered it. So advancing a story from `draft` to `accepted` changed hashed content: a story the maintainer had ratified minutes earlier read as unratified, and `itil-no-implement-draft-gate` then denied that story's own implementing commit. `oversight_content_hash_excluding_stories` carried the identical omission. Shipped in `@windyroad/itil@0.60.0`; hit live on 2026-07-29 when STORY-047 had to be re-ratified purely to clear it. The guarantee the 2026-07-03 amendment and the released changeset both stated was therefore only half-implemented from the day it shipped.

**The decision — remove the mirror, do not normalise it.** Adding a fourth normaliser rule would have worked, but this was the fourth lifecycle mirror in a family of three and a fifth was already anticipated, i.e. one rule per mirror indefinitely. Put to the maintainer on 2026-07-29 against both alternatives (normalise it out; or revert to the literal "any change" and accept re-ratification on every transition), the direction was to **kill the class**: lifecycle state lives in frontmatter `status:` only and is never duplicated inside content-hashed body prose. The `**Status**:` line is removed from the story template and from the corpus; the hash function itself is **unchanged**.

That choice has a property the normalise option lacked: because no hash function changes, no already-stored fingerprint is invalidated by the fix reaching an adopter. Only artefacts that still carry the mirror need migrating.

**The migration — re-fingerprint, never re-ratify.** `wr-itil-migrate-story-status-mirror` removes the mirror and carries existing ratification forward. The distinction it rests on: `human-oversight: confirmed` asserts that a human confirmed something and the migration never writes it; `oversight-hash` asserts no event, only identifying WHICH content the confirmation covered. Recomputing that pointer over content whose sole delta is a mechanical mirror of an already-excluded field removes zero ratified substance from coverage. That argument is not a general licence for hash changes — it holds here because the delta is provably information-free, and only under two guards:

1. **Per-artefact validity gate** — re-fingerprint only where the stored hash still matches current content. An artefact already drifted stays drifted; nothing is revived. Without this the migration is a blanket re-bless, which is the P348 hollow-marker class.
2. **Mirror-agreement precondition** — where the body line disagrees with the frontmatter it is carrying independent information, so the information-free argument fails for that artefact. Those are skipped and reported for a human, never rewritten. Three fired on the real corpus: two stories carrying provenance (`superseded (was: draft)`) or a transition date, and `README.md`, which documents the template. Both stories were resolved by hand after confirming the extra text was recoverable from context (a `draft/` path plus `status: superseded`; a date identical to the story's own `reported:`); the scan was narrowed to `STORY-*.md` so it no longer reads the README at all.

The migration is idempotent and reports every artefact it touches, so the re-fingerprint set is auditable from the commit that ran it. It ships as a PATH-shimmed script per ADR-049 rather than a repo-local one, because adopter corpora carry the mirror too and source-repo-only migration is the P151/P317 dogfooding blind spot.

**Corpus result (2026-07-29).** 31 mirrors removed, 7 re-fingerprinted with ratification preserved, 3 skipped and hand-resolved. The 12 confirmed-but-drifted stories were verified drifted at `HEAD` **before** the migration ran, so the gate demonstrably did not revive them. `oversight-basis:` is untouched, so ADR-101's post-hoc drain still surfaces AFK-accepted stories.

**Residual, recorded rather than fixed.** Normalisation of criterion ticks and `data-status` remains line-shape-based, so a lifecycle token inside a fenced block or quoted template example in a story body would still be treated as substance. No corpus artefact has that shape today. If a fifth mirror appears, the reassessment trigger is to stop hashing hand-maintained body prose for lifecycle state at all rather than to add another rule.

**Confirmation.** Behavioural bats over the migration cover: mirror removed on agreement; skip-and-report on disagreement; a currently-ratified story still ratified afterwards; an accept transition no longer drifting; an already-drifted story not revived; `human-oversight` never written; `oversight-basis` preserved; idempotence; `README.md` untouched. Verified end-to-end on a real ratified story — accept transition and criterion ticks both preserve ratification, while a genuine substance edit still drifts.

**Why the marker is bumped rather than cleared** (ADR-066 self-attestation). An earlier draft of this paragraph argued for leaving the marker untouched, on two grounds that this same commit falsifies: that no Decision Outcome changed, and that bumping would imply currency over a gap left open. Both are now false — the Outcome text IS reconciled here, and the 2026-07-03 gap IS closed by the 2026-07-30 ratification above. Recording that honestly matters in both directions: under-recording a genuine confirmation event is as much a defect as asserting an absent one, and leaving `oversight-date` at 2026-07-02 against an Outcome edited 2026-07-30 would send `/wr-architect:review-decisions` to re-open the very question the maintainer just answered.

So the marker stays `confirmed` and its date advances to 2026-07-30, with `oversight-confirmed-date` narrating **both** events — the 2026-07-02 batched ratification that chose drift-invalidation over write-once, and the 2026-07-30 ratification of the substance-only narrowing. Neither supersedes the other; they ratify different clauses.

This 2026-07-29 amendment on its own would not have warranted a bump: it tightens the mechanism implementing an Outcome the 2026-07-02 event already ratified (that Outcome asserts the oversight marker is orthogonal to the `status:` lifecycle; storing lifecycle state inside hashed body prose violated that orthogonality, and removing it restores it), and the hash function is unchanged. The bump is warranted by the Outcome reconciliation and the narrowing's ratification, which ride in the same commit.
