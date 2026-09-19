# Problem 553: The RFC `## Stories` section's recorded contract and its implementation disagree, and nothing checks either

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture per Step 4a. Impact 2: governance-index integrity and a detector's trustworthiness; dev tooling, no shipped-package or adopter harm. Likelihood 4: the divergence is not intermittent — it is the steady state, and the audit found 18 live instances plus 19 pairs a detector was counting as checked.
**Origin**: internal
**Effort**: M — derived at capture per Step 4a. Three separable repairs (reconcile the record to the code or the code to the record; back-fill or strip 10 forbidden `stories:` entries; repair 19 story/map traces) over a corpus of ~95 stories and ~62 RFCs. Grounded on the scope shape of P472, whose single-predicate fix came in at M once the write-path gate and the shared-lib accessor were counted.
**JTBD**: JTBD-006
**Persona**: developer

## Description

ADR-060 line 288 and `update-rfc-references-section.sh`'s own header both state that an
RFC's `## Stories` section is a **forward** trace projecting the RFC's own `stories:`
frontmatter array. The implementation does the opposite: it reverse-indexes
`docs/stories/*/STORY-*.md` on each story's `rfcs:` field. Neither surface validates the
other, so the divergence has survived since P170 Phase 2 Slice 2b.

A corpus audit on 2026-09-19, run while fixing P472, found the consequences already live:

- **8 of 23** approved (story → markdown-RFC) claims sit in an RFC's `## Stories` section
  but are absent from that RFC's `stories:` frontmatter. Projecting `stories:` — the fix the
  record implies — would drop those 8 rows, and the reconciler would then report
  `MISSING_REVERSE_TRACE` on them with no mechanical repair. That is P472 re-created in the
  other direction, which is why P472 gated the helper instead of reconciling the contract.
- **10 unapproved stories are listed in RFC `stories:` frontmatter arrays.** ADR-090 as
  amended by ADR-103 forbids an RFC from referencing a story whose story map is not
  ratified. `check-rfc-stories-ratified.sh` gates that class going forward, so this is
  corpus repair rather than an open enforcement hole — but the corpus is wrong today.
- Separately, the narrowed reconciler now reports **19 of 42** story/RFC pairs as corpus
  defects: 6 stories name no story map at all (ADR-095 requires membership at capture), and
  13 name a map id — STORY-MAP-005 and STORY-MAP-010 among them — that resolves to no file.
  Those 19 were previously counted as *checked*, against a demand they could never satisfy.

Same failure class as P472 and its siblings: a tool exiting zero over output it never
validated, and a record that describes a mechanism nobody implemented. A green result from
either surface is currently evidence of nothing.

## Symptoms

- `update-rfc-references-section.sh <rfc> "Stories"` regenerates the section from story
  frontmatter, not from the RFC's `stories:` array, contradicting its own header and ADR-060.
- `wr-itil-reconcile-stories docs/stories docs/problems docs/rfcs docs/jtbd docs/story-maps`
  reports `checked 23 of 42 story/RFC pairs` with 6 no-map and 13 unresolved-map skips.
- 10 RFC `stories:` arrays name stories whose maps are not ratified.

## Workaround

Read an RFC's `## Stories` section as a reverse index of story `rfcs:` claims, not as a
projection of `stories:`. Do not reconcile the two by hand — the two populations genuinely
differ and hand-reconciling either direction loses rows.

## Impact Assessment

- **Who is affected**: developer reading or repairing RFC ↔ story traces, and any unattended
  loop that treats the reconciler's output as a clean/dirty signal for the story tier.
- **Frequency**: steady state, not intermittent.
- **Severity**: Medium (8) — governance-index integrity plus a detector whose clean result
  cannot be trusted; dev tooling only.
- **Analytics**: 2026-09-19 audit — 8 section-only claims, 10 forbidden `stories:` entries,
  19 of 42 pairs skipped as corpus defects.

## Root Cause Analysis

### Investigation Tasks

- [ ] Decide which direction is the record: amend ADR-060 line 288 and the helper header to
      describe the reverse index, or change the helper to project `stories:` and back-fill the
      8 missing frontmatter entries first so no row is dropped.
- [ ] Strip or ratify the 10 unapproved stories currently listed in RFC `stories:` arrays.
- [ ] Repair the 19 story/map traces: 6 stories naming no map, 13 naming a map id that
      resolves to no file.
- [ ] Add a check that fails when the record and the implementation disagree, so this class
      cannot survive silently a second time.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P472 (the narrowing that surfaced all of this), P417, P409.

## Related

- **P472** — the reverse-trace narrowing whose corpus audit produced every number above. Its
  ticket body records findings 1-4 in full; this ticket is the repair job they name.
- **P417** (`docs/problems/known-error/417-stories-readme-rankings-done-never-reconciled.md`)
  — adjacent: the same script's rankings/Done render never being reconciled. Shares a fix
  surface; a reviewer may prefer to fold this in there.
- **P409** — back-fill legacy RFCs still carrying empty `stories: []`. Overlaps the
  back-fill leg of investigation task 1.
- **ADR-060** line 288 (the forward-trace claim), **ADR-090** / **ADR-103** (an RFC
  references only approved stories; approval reaches a story through its map), **ADR-095**
  (story-map membership at capture).
- Captured via `/wr-itil:capture-problem` during the `/wr-retrospective:run-retro` of the
  P472 iteration (2026-09-19). Duplicate grep matched 3 filenames on
  `reverse-trace|references-section|forward-trace`; the two worth a read are named above
  (P417, P409) and neither absorbs the contract-vs-implementation divergence, which is this
  ticket's core.
