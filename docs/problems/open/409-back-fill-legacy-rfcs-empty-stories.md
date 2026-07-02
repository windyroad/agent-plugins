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
- [ ] Enumerate all on-disk RFCs with empty `stories: []` (not just RFC-036/RFC-003) via `wr-itil-check-rfc-has-stories`
- [ ] Per legacy RFC: author one value-first INVEST story on the relevant story map, ratify it (born-unconfirmed → confirmed), then add it to the RFC's `stories:` array

## Fix Strategy

Author one value-first INVEST story per legacy RFC on the relevant story map, ratify it (`/wr-itil:manage-story-map <NNN> ratify`), then add it to the RFC's `stories:` array. **Shape:** self-contained data-conformance work (no new codification — the enforcement + tooling already shipped with RFC-037). Verify each back-filled RFC passes `wr-itil-check-rfc-has-stories` + `wr-itil-check-rfc-stories-ratified`.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none — the ADR-089/090 enforcement + tooling already shipped via RFC-037)
- **Composes with**: P404 (ADR-089/090 implementation — this is its deferred legacy-data follow-up)

## Related

- **P404** / **RFC-037** — the ADR-089/090 implementation this was deferred from (P404 → verifying 2026-07-03). Captured as a STANDALONE ticket rather than hung off P404 deliberately: P404 is closing, and the back-fill must remain actionable in the WSJF queue after P404 closes. Surfaced by `/wr-retrospective:run-retro` (2026-07-03 RFC-037 session).
- **ADR-089** (every RFC has ≥1 story) — the invariant these legacy RFCs pre-date.
