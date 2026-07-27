# Problem 473: Story maps are authored as per-fix 1-card stubs, not user journeys — below the STORY-MAP-003 quality bar

**Status**: Open
**Reported**: 2026-07-27
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture per Step 4a. Impact 3: the story-map tier is a core governance artefact (ratification gate, JTBD-008 deliverable); stub maps make ratification hollow and mislead adopters about what a map is. Likelihood 4: every AFK-authored fix vehicle this session (STORY-MAP-005/006/007/008/009) produced a stub; the framework guidance actively encourages it.
**Origin**: corrective-feedback (user, 2026-07-27)
**Effort**: L — reshape the map model (consolidate fixes onto real journey maps), retire the "one-rib floor" guidance, re-author the session's stubs, update ADR-089/095 + manage-story-map authoring contract.
**WSJF**: 4 — (12 × 1.0) / 3
**JTBD**: JTBD-008, JTBD-001
**Persona**: developer

## Description

Story maps authored by the AFK loop (and encouraged by framework guidance) are **per-fix 1-card stubs**, not user journeys. A single small fix (e.g. P430's 3-line correction-nudge hook guard) gets its own story map with one rib and one story card — and the map's own prose rationalises this ("Single-story map: ADR-089 (every RFC has a story) and ADR-095 (map membership at capture) make one-rib maps the floor shape for a single-surface fix").

User correction (2026-07-27): the reference bar is `../voder-mcp-hub/docs/story-maps/accepted/STORY-MAP-003-self-serve-data-rights-and-trust.html` — *"That is the bar I expect ALL maps to meet."* A real story map is a **user journey**: a backbone of user activities across the top (See what you hold → Get a copy → Manage sign-in → Remove things → Leave), release slices as horizontal bands (Live → R1 → R2 → R3), each grid cell a **user-valued outcome card** written in the user's voice with a Value line + trace ref, a Traces section, and full light/dark + accessible styling (focus-visible, scope, aria, badges/legend).

The session's stubs have: one rib, one dev-task card ("Gate the correction nudge on prompt authorship" — a task, not a user value), no journey backbone, no release slices, light-only styling. The gap is structural, not cosmetic.

**Direction (user, 2026-07-27):** consolidate — author a few REAL journey maps at the STORY-MAP-003 bar, place the session's fix-stories as cards on them, and retire the per-fix stubs. The honest unit is a user journey, not a fix. This implies a fix should be able to JOIN an existing journey map rather than mint a stub.

## Symptoms

- STORY-MAP-005/006/007/008/009 (this session) are each 1-rib / 1-card / light-only stubs, ~60 lines vs the ~169-line STORY-MAP-003 bar.
- Map cards carry dev-task titles, not user-valued outcomes.
- No backbone of user activities; no release slices; no Traces section at the reference's depth.
- Framework guidance ("one-rib maps are the floor shape") encodes the stub as correct.

## Workaround

Author real journey maps by hand to the STORY-MAP-003 template; consolidate related fix-stories as cards; retire the stubs. Manual.

## Impact Assessment

- **Who is affected**: maintainer (ratifying hollow skeletons); adopters (misled about the map artefact); JTBD-008 (the coordination surface is not really authored).
- **Frequency**: every AFK-authored fix vehicle.
- **Severity**: High (12) — hollow ratification + core-artefact quality gap.
- **Analytics**: 2026-07-27 — 5 session maps all stubs; STORY-MAP-003 (voder-mcp-hub) is the stated bar.

## Root Cause Analysis

### Investigation Tasks

- [ ] Establish the STORY-MAP-003 authoring bar as the manage-story-map / capture-story-map contract (backbone × release slices × user-value cards × light/dark + a11y); make it the review target.
- [ ] Reshape the map model so a fix can JOIN an existing journey map (retire the one-map-per-RFC / one-rib-floor default); amend ADR-089 / ADR-095 accordingly.
- [ ] Re-author the session's stub maps into consolidated journey maps; re-point the fix-stories' `story-maps:` traces; retire the stubs.
- [ ] Behavioural/lint check for map quality floor (has a backbone, release slices, user-value cards, dark mode, focus-visible) — distinct from a mere presence check.

## Dependencies

- **Composes with**: P457 (story-map ratification surfaces an unauthored skeleton — the timing sibling; this is the quality/structure sibling), P466 (story-map HTML template ships a11y defects — the template this replaces), ADR-101 (the carve-out that made landing depend on confirmed maps, surfacing this), P456 (throughput).
- **Blocked by**: (none) — the fix is authoring + framework-model change.

## Related

- Reference bar: `../voder-mcp-hub/docs/story-maps/accepted/STORY-MAP-003-self-serve-data-rights-and-trust.html` (user-named 2026-07-27 as the bar ALL maps must meet).
- Captured via `/wr-itil:capture-problem` during a `/wr-itil:work-problems` session (2026-07-27) after the user corrected the story-map quality bar while proving the ADR-101 carve-out end-to-end on P430.
- The one-map-per-fix framework guidance: ADR-089 (every RFC has ≥1 story), ADR-095 (map membership at capture), and the "one-rib maps are the floor shape" note in the authored stubs.
