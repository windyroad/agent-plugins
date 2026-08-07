---
status: "proposed"
date: 2026-07-07
human-oversight: confirmed
oversight-date: 2026-07-07
oversight-confirmed-date: "2026-07-07 — post-draft brief-and-confirm via AskUserQuestion (P357): maintainer confirmed the drafted ADR-095 faithfully captures intent. Decision substance was picked pre-draft; this marker records the SEPARATE post-draft confirmation of the drafted content."
oversight-note: "I8 (story-map membership) enforced at capture with refuse-and-route + the story-content INVEST subset (Valuable + Testable) at capture as a born-well-formed bar (deliberate documented ADR-032 deviation). Sibling ADR-096 carries no-implement-while-draft. Architect re-review 2026-07-07 conditions applied."
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-07
amends: [ADR-060]
---

# Story-map membership and story-content completeness are enforced at capture

## Context and Problem Statement

ADR-060's story-trace invariants I8 (trace-to-story-map) and I10 (INVEST shape) hard-block only at `/wr-itil:manage-story <NNN> accepted`. `capture-story` scaffolds a skeleton with `story-maps: []` and placeholder `## User value` / `## Acceptance criteria` sections. On 2026-07-05 the maintainer observed the AFK flow authoring mapless, placeholder-content stories that sit in `draft` — the accepted-transition gates never fire because the flow never promotes them (same self-firing-cadence failure as P251). Maintainer directive (AskUserQuestion 2026-07-07): a story must be **born on a map** and **born with real content** (user value + acceptance criteria), not a skeleton acquired later.

The complementary half — a `draft` story must never be implementable — is a separate lifecycle axis carried by sibling **ADR-096** (no-implement-while-draft). This ADR covers only the capture-time gates.

## Decision Drivers

- The map + content gates must fire on the path that authors stories (capture), not only on a promotion the AFK flow skips.
- A story's organising home (its map) is a foundational *trace*; its user value + acceptance criteria are its authored *content*.
- Avoid auto-minting governance artefacts (ADR-089 rejected the auto-derived singleton).

## Considered Options

- **A. I8 at capture (refuse-and-route) + the story-content INVEST subset (Valuable + Testable) at capture.** Maintainer-directed.
- **B. I8 at capture only; keep all of INVEST at accepted.** Rejected by the maintainer — they want stories born content-complete, not skeletons.
- **C. Status quo (both at accepted).** Rejected: the observed failure.

## Decision Outcome

Chosen option: **A.** Amends ADR-060:

1. **I8 (story-map membership) at capture — refuse-and-route.** `capture-story` rejects `story-maps: []`. When no suitable map exists it **refuses and routes** to `/wr-itil:capture-story-map` first (no silent auto-create), then re-capture onto the map — parity with the I6 (problem) / I9 (JTBD) capture-time refuse-and-route gates. I8 is a *trace*, so moving it to capture is fully ADR-032-consistent (capture already mandates the foundational traces). Under AFK the orchestrator authors the map first (born `unconfirmed` per ADR-090, drained later); nothing halts.

2. **Story-content INVEST subset at capture.** `capture-story` requires the **Valuable** facet (a real `## User value` statement, value-first per the story shape) and the **Testable** facet (>= 1 real acceptance criterion) — NO placeholder sections. The other INVEST facets stay at `accepted`: **Estimable** depends on `estimated-effort`, which ADR-060 sets at the accepted transition; **Small** is assessed at accepted. So this is explicitly the *content-completeness subset*, not full INVEST — named precisely so the gate is enforceable and the behavioural bats can target it.

   **Documented deviation from ADR-032.** INVEST is a *shape gate*, the class ADR-032 defers from capture. Enforcing its content subset at capture is a deliberate, scoped deviation for the story tier: the maintainer values born-well-formed stories over minimal-capture, accepting the heavier capture. Full INVEST (incl. Estimable/Small) is re-verified at `accepted`.

3. **Draft semantics redefined (lockstep ADR-060 lifecycle-table edit).** `draft` no longer means "acceptance criteria not yet INVEST-shaped." It now means: **content-complete (map + user value + >= 1 acceptance criterion) but not yet accepted** — i.e. `estimated-effort`/Small unset, I7 RFC trace absent, ADR-090 ratification pending. `accepted` re-verifies full INVEST, adds the effort estimate, enforces I7, and carries ratification. **Amended by ADR-103 (2026-08-07), superseding the ADR-101 amendment:** `accepted` carries approval, and approval is the story MAP's — a story carries no oversight field at all and is approved when every map in its `story-maps:` field is ratified. Story-level markers were stripped from the corpus rather than drained. ADR-101's machine-written `oversight-basis: pure-decomposition` basis is retired and never fired on any story.

**Bootstrap exemption preserved.** The ADR-060 A4 bootstrap-exempt marker is honored at the new capture-time gates; the "marker permitted ONLY on bootstrap migrations" behavioural test moves/duplicates to the capture surface.

### Consequences

- Good: mapless / placeholder-content stories can no longer be captured; stories are born well-formed.
- Bad / cost: `capture-story` is heavier (a map must exist; real content required) — a documented ADR-032 deviation.
- Neutral: existing mapless survivors (STORY-037/038) need back-filling (P404 Phase 3).

### Confirmation

Capture-time checks in `capture-story`: reject empty `story-maps:` -> refuse-and-route; reject placeholder/empty `## User value` or `## Acceptance criteria`; honor the bootstrap-exempt marker. Behavioural bats: mapless capture rejected with a route directive; placeholder-content capture rejected; content-complete + mapped capture accepted; bootstrap-exempt capture permitted; non-bootstrap capture carrying the marker rejected. ADR-060 I8 + the draft-state lifecycle cell amended in lockstep.

## Pros and Cons of the Options

- **A** — Good: stories born mapped + content-complete; gate fires on the real path. Bad: heavier capture (ADR-032 deviation, documented).
- **B** — Good: lightweight capture. Bad: skeleton stories persist (maintainer rejected).
- **C** — Good: zero change. Bad: the observed failure.

## More Information

Amends ADR-060 (I8 enforcement point; I10 content subset at capture; draft-state definition). Composes ADR-089 / ADR-090 / **ADR-096** (no-implement-while-draft — the complementary lifecycle gate). Driving problem: P404 Phase 3. Architect re-review 2026-07-07: ISSUES-FOUND conditions (facet-subset naming, ADR-032 deviation, draft redefinition) applied.
