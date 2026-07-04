# Problem 409: Back-fill legacy RFCs still carrying empty `stories: []`

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

Back-fill legacy RFCs still carrying empty `stories: []` (RFC-036, RFC-003) with one INVEST story each, for ADR-089 consistency (every RFC has ≥1 story). Low-urgency: these RFCs are already accepted, so the transition-time accept gate (`wr-itil-check-rfc-has-stories`) never re-fires on them, and `wr-itil-detect-unratified-stories-maps` / the accept gate would only catch them at a future `manage-rfc accepted` transition. Deferred from P404 / RFC-037 (ADR-089/090 implementation, 2026-07-03) as a tracked follow-up — it was explicitly NOT a Confirmation criterion of RFC-037, so it did not gate that RFC's completion.

## Symptoms

(deferred to investigation)

## Workaround

None needed — legacy `stories: []` RFCs are already `accepted`; the ADR-089 accept gate only fires on the `proposed → accepted` transition, which these RFCs will not re-run. The inconsistency is cosmetic (data does not match the new invariant) until one is re-worked.

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause:** ADR-089 (every RFC has ≥1 story) shipped 2026-07-03 via RFC-037, but only *new* proposed→accepted transitions are gated. RFCs accepted before ADR-089 (RFC-036, RFC-003) retain their pre-ADR-089 empty `stories: []` frontmatter — the enforcement is transition-time, not a retroactive sweep.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Enumerate all on-disk RFCs with empty `stories: []` (not just RFC-036/RFC-003) — see `## Progress (2026-07-04)` below
- [~] Per legacy RFC: author one value-first INVEST story, ratify it (born-unconfirmed → confirmed), then add it to the RFC's `stories:` array — **authoring done for the 3 past-accept RFCs (STORY-034/035/036, born unconfirmed); ratify-then-wire deferred to the interactive drain per ADR-090 (see Progress below)**

## Progress (2026-07-04)

**Enumeration (all on-disk RFCs with empty/missing `stories:`).** The ticket's named examples were partly stale: RFC-003 already has 7 stories; RFC-036 is still `stories: []`. Classified the full set by lifecycle state, because ADR-089's `wr-itil-check-rfc-has-stories` gate only fires at the `proposed → accepted` transition:

- **Genuine back-fill targets — past the accept gate, literal `stories: []`** (these passed accept before ADR-089 existed): **RFC-006** (`verifying`), **RFC-007** (`verifying`), **RFC-036** (`accepted`).
- **Not back-fill targets — `proposed` RFCs with `stories: []`** (RFC-008/009/010/011/012/013/014/015/016/017/018/019/020/021/022/023/024/025/026/027/028/029/030/031/032/033/034/035/039/040/041/042): legitimately pre-accept — ADR-089 gates them at their future `manage-rfc accepted` transition, so they are NOT a legacy inconsistency. Left untouched by design.
- **Distinct defect — past-accept RFCs with NO `stories:` field at all** (not the same as empty `stories: []`): **RFC-001** (`verifying`), **RFC-002** (`verifying`), **RFC-004** (`verifying`). These predate the `stories:` frontmatter entirely. Recorded here as a separate follow-up rather than scope-crept into this ticket (which targets literal `stories: []`).

**Back-fill authored (mechanically-derivable half).** One umbrella value-first INVEST story per past-accept `stories: []` RFC, derived from each RFC's existing `## Scope` / `## Tasks`, born `human-oversight: unconfirmed` (draft) per ADR-090:

- `docs/stories/draft/STORY-034-plugin-staleness-surfacer-warns-once-per-new-version.md` → RFC-036 (JTBD-007)
- `docs/stories/draft/STORY-035-rfc-decisions-homed-in-adrs-rfc-first-unconditional.md` → RFC-006 (JTBD-008)
- `docs/stories/draft/STORY-036-create-gate-marker-survives-concurrent-sessions.md` → RFC-007 (JTBD-006)

Each carries the story→RFC forward trace (`rfcs:` / I7), which is NOT gated by ADR-090 (architect-confirmed). Both gate reviews PASS (architect + JTBD).

**Deferred to the interactive drain (human-only, cannot land AFK).** The architect review established that ADR-090 ("an RFC may reference only ratified stories") is a **state invariant**, not merely a transition-time gate — so wiring an unratified story into an RFC's `stories:` array is forbidden even by off-skill hand-edit. The remaining half is therefore:

1. **Ratify** STORY-034/035/036 (born-unconfirmed → `human-oversight: confirmed`) — requires human `AskUserQuestion`, unavailable AFK.
2. **Then wire** each RFC's `stories: []` → `stories: [STORY-NNN]` (ratify-then-wire order).

Until step 2 lands, RFC-006/007/036 still fail `wr-itil-check-rfc-has-stories` — the ADR-089 invariant is **not yet satisfied** for them. This is expected and correct sequencing, not a regression.

**I8 story-map decision (architect-flagged).** These umbrella backfill stories carry no `story-maps:` trace (I8). Draft state is fine, but they cannot reach `accepted` without an I8 story-map. Recorded decision: they stay `draft` until the interactive ratify session decides whether to give them a story-map trace or keep them as permanently-draft backfill artefacts — an explicit recorded choice, not a silent deferral.

**Scope note.** `docs/stories/README.md`'s "Story Rankings" and "Done" sections are still the bootstrap placeholder ("Empty — no stories captured yet") — stale for the entire ~30-story corpus, a pre-existing scaffold gap unrelated to this ticket. Not reconciled here; belongs to `/wr-itil:reconcile-stories` as its own unit of work.

## Fix Strategy

Author one value-first INVEST story per legacy RFC on the relevant story map, ratify it (`/wr-itil:manage-story-map <NNN> ratify`), then add it to the RFC's `stories:` array. **Shape:** self-contained data-conformance work (no new codification — the enforcement + tooling already shipped with RFC-037). Verify each back-filled RFC passes `wr-itil-check-rfc-has-stories` + `wr-itil-check-rfc-stories-ratified`.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — the ADR-089/090 enforcement + tooling already shipped via RFC-037)
- **Composes with**: P404 (ADR-089/090 implementation — this is its deferred legacy-data follow-up)

## Related

- **P404** / **RFC-037** — the ADR-089/090 implementation this was deferred from (P404 → verifying 2026-07-03). Captured as a STANDALONE ticket rather than hung off P404 deliberately: P404 is closing, and the back-fill must remain actionable in the WSJF queue after P404 closes. Surfaced by `/wr-retrospective:run-retro` (2026-07-03 RFC-037 session).
- **ADR-089** (every RFC has ≥1 story) — the invariant these legacy RFCs pre-date.
