# Problem 442: WSJF Rankings render convention differentiates tiers only by ordering + the Origin column — no visual tier separator, so inbound-reported priority is not legible

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Origin**: corrective-feedback (user, 2026-07-06 — "why isn't docs/problems/README.md differentiating between inbound reported items (top priority) and internally reported items?")
**Effort**: M. WSJF = (8 × 1.0) / 2 = 4.0.
**WSJF**: 4 — (8 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The WSJF Rankings render convention (P138 + ADR-076) orders rows tier-first (Tier 0 Critical-bypass → Tier 1 Inbound-reported → Tier 2 Internal) and mandates an `Origin` column "so the Tier 1 partition is visible." But the ONLY differentiation between inbound-reported (top-priority) and internal tickets is (a) the sort order and (b) the per-row `Origin` cell value — there is no visual section header or separator. Once the ranking table is long, the tier boundary is invisible; a reader cannot tell at a glance where the prioritised inbound block ends and internal begins. Surfaced 2026-07-06 when 18 inbound-reported tickets (P424–P441) first populated the Tier-1 block and the maintainer asked why the README wasn't differentiating the tiers.

## Symptoms

- The rendered WSJF Rankings table interleaves inbound and internal rows with no visual break — the tier-first ordering is real but imperceptible; the reader must scan the Origin column row-by-row to infer the boundary.
- Until 2026-07-06 there were zero inbound-reported items in the rankings, so the latent gap never rendered.
- The interim `### Tier 1` / `### Tier 2` sub-headers added to `docs/problems/README.md` this session are NOT emitted by any render site, so the next full re-render (`review-problems` Step 5, a transition re-render) drops them.

## Impact Assessment

- **Who is affected**: the maintainer + anyone reading the backlog; adopter-priority signal is not legible on the primary work-selection surface.
- **Frequency**: every read of a non-trivial rankings table; every full re-render drops any manual separator.
- **Severity**: Medium — ordering already works; this is legibility, but on a load-bearing surface.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add visual tier section headers (`### Tier 1 — Inbound-reported (prioritised)` / `### Tier 2 — Internal`, and Tier 0 when non-empty) to the WSJF Rankings render convention across ALL render sites in lockstep: `review-problems` Step 3 + Step 5 template, `manage-problem` Step 5 P094 + Step 7 P062 + Step 9e template, `transition-problem` / `transition-problems` render, `list-problems`, and the `reconcile-readme` Step 4 insertion logic.
- [ ] Confirm the `reconcile-readme.sh` parser tolerates the sub-headers (verified 2026-07-06: it slices `## WSJF Rankings`..next-`##` and counts only `| P<NNN> |` data rows, so `###` sub-headers are skipped) and add a regression bats fixture asserting tier-header presence + tolerance.
- [ ] Only emit a tier header when that tier is non-empty (avoid empty `### Tier 0` noise).

## Dependencies

- **Composes with**: P138 (tie-break ladder / tier-first ordering — closed; this adds the missing VISUAL layer to that ordering), ADR-076 (reported-first tier partition — the authority; this ticket makes its partition legible), P150 / P186 (sibling render-convention markers across the same render sites).

## Related

- User correction 2026-07-06. Interim fix: `### Tier 1` / `### Tier 2` sub-headers added to `docs/problems/README.md` (non-durable until the render sites adopt the convention).
