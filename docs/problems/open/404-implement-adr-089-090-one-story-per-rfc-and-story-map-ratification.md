# Problem 404: Implement ADR-089 + ADR-090 in the skills and tests (≥1-story-per-RFC + story-map/story ratification)

**Status**: Open
**Reported**: 2026-07-02
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 = 12. Rated at review 2026-07-02: implement ADR-089+090 in skills+tests.
**Origin**: internal
**Effort**: L. WSJF = (12 × 1.0) / 4 = 1.5.
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

The deferred implementation ripple from the 2026-07-02 ratification of **ADR-089** (every RFC has ≥1 story) and **ADR-090** (story maps and stories carry a drift-invalidated human-oversight marker). Both ADRs are `human-oversight: confirmed`; this ticket makes the behaviour real in the skills + tests. Two coupled phases sharing the `capture-rfc` / `manage-rfc` surface.

### Phase 1 — ADR-089 (every RFC has ≥1 story)

- Remove the empty-stories fallback branch in the `work-problem` / `manage-problem` Known-Error traversal + the `Refs: RFC-NNN` atomic trailer path.
- Update `capture-rfc` + `manage-rfc` to **require ≥1 story** — an RFC cannot reach `accepted` with an empty `stories: []`; drop the lazy-empty `## Stories`-omission-on-`[]` logic.
- **Flip the four currently-GREEN bats** that assert the empty-stories fallback is legal to assert it is **rejected**: `rfc-stories-extension.bats`, `working-the-problem-traversal.bats`, `check-rfc-rejected-alternatives.bats`, `list-stories-contract.bats`. These are the highest-signal item — they are green now and **must flip in the same slice** that ships the behaviour, or CI goes red the moment the doc change is consumed.
- Legacy-data question: do existing on-disk RFCs with `stories: []` (e.g. RFC-003 frontmatter) need back-filling one story each?

### Phase 2 — ADR-090 (story-map/story drift-invalidated human-oversight)

- Add the `human-oversight:` marker field + write path to the story-map/story skills (`capture-story-map`, `manage-story-map`, `capture-story`, `manage-story`).
- Add the **drift-invalidation trigger**: any edit to a map or story re-opens its marker to `unconfirmed` (hook- or skill-side; ADR-009 TTL/drift lineage, NOT ADR-066 write-once).
- Add the **RFC-references-only-ratified-stories gate** to `capture-rfc` / `manage-rfc` (composes with Phase 1: the atomic fix's single story must itself be ratified before its RFC lists it).
- Add an unratified-story-map detector mirroring `wr-architect-detect-unoversighted`.
- Behavioural bats for the marker + drift-reopen + the reference gate.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Decide the implementation vehicle: hang off RFC-005 / STORY-MAP-002 as new stories, or a standalone RFC per ADR-071
- [ ] Phase 1: remove empty-stories fallback + require ≥1 story + flip the 4 bats (same slice)
- [ ] Phase 1: resolve the legacy `stories: []` back-fill question
- [ ] Phase 2: marker field + drift-invalidation trigger + reference gate + detector + bats
- [ ] **Use STORY-MAP-002 as the golden exemplar**: its hand-authored, fully-ratified map + 16 stories (built + ratified end-to-end this session) are the worked example of the *output* the implemented map/story-authoring tooling must produce — same shape, INVEST value-first statements, per-beat/release structure, and drift-invalidated oversight. Assert the tooling can (re)produce an artefact of this quality.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — ADR-089/090 are ratified; this is their implementation)
- **Composes with**: RFC-005 / STORY-MAP-002 (the RFC-first work this may land within)

## RFCs

- **RFC-037** — the RFC-first fix for this problem (authored 2026-07-02). Implements ADR-089/090 in two phases; its `stories:` are STORY-MAP-002's A3 tooling stories (020/021/022/024/025). This is the RFC we should have created *before* decomposing — dogfood gap closed.

## Related

- **ADR-089** (every RFC has ≥1 story) + **ADR-090** (story-map/story drift-invalidated oversight) — the authorities, both confirmed 2026-07-02.
- **STORY-MAP-002** / **RFC-005** — the RFC-first vehicle this may land within as new stories (per the ADRs' "consider hanging off" note); the A3 ratify/create/add/reuse stories on the map are the natural home. **STORY-MAP-002 is also the hand-authored exemplar** — the golden reference for what a good, ratified USM + its INVEST stories look like (see the Investigation Task above).
- Hang-off pre-filter (skipped subagent, >5 candidates) surfaced the RFC-first cluster for review-time consolidation: **P399** (author full RFC not skeleton), **P314** (I13 gate rework), **P310** (RFCs carry independent decisions), **P315**, **P312**. A reviewer should decide whether Phase 1/2 fold into RFC-005's implementation or that cluster rather than standing alone.
