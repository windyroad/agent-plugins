---
status: "proposed"
date: 2026-07-02
human-oversight: confirmed
oversight-date: 2026-07-02
oversight-confirmed-date: "2026-07-02 — batched ratification via AskUserQuestion: user ratified drift-invalidated marker for story maps AND stories (re-ratify on any change), RFC references only ratified stories; user explicitly confirmed stories are ratified as first-class, not just maps"
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
- **Any change** to a story map or a story (add / edit / re-slice / reuse / retitle) **invalidates** its `confirmed` marker back to `unconfirmed` — a drift-invalidated marker, not a write-once one. Re-ratification (human confirm) is required before the map is relied upon again.
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

## Related

- **ADR-066** — human-oversight marker + review-decisions drain (the write-once precedent this diverges from, deliberately, for a living artefact).
- **ADR-068** — JTBD + persona oversight sibling (the "mirror ADR-066 for a new tier" precedent this follows).
- **ADR-060** — Problem-RFC-Story framework (its story-map/story lifecycle, schemas, and invariants gain the ratified axis — lockstep edits).
- **ADR-074** — confirm substance before building dependent work (the general principle).
- **ADR-009** — gate-marker TTL/drift lineage (the drift-invalidated marker's mechanism precedent).
- **Sibling ADR — "Every RFC has at least one story"** — composes with this: every RFC has ≥1 story AND those stories must be ratified before the RFC references them.
- **P283 / P288** — auto-made artefacts drift; lift to human ratification. **JTBD-008** — the decompose job whose story-map artefacts this governs.
- **Implementation ticket** (to be logged) — the marker field + write path in the story-map/story skills, the drift-invalidation trigger, the RFC reference-gate in capture-rfc/manage-rfc, the unratified-map detector, and behavioural bats.
