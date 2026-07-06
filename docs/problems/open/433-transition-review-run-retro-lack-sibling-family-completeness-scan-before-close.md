# Problem 433: transition-problem / review-problems / run-retro Step 4a lack a sibling-family completeness scan before close

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4
**Origin**: inbound-reported (#187)
**Effort**: M. WSJF = (12 × 1.0) / 2 = 6.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The close paths (`transition-problem`, `review-problems`, `run-retro` Step 4a) do not scan for open / known-error sibling tickets in the same friction-class / Composes-with family before allowing a close. A ticket closes while related siblings that should close (or be re-linked) with it are left stranded, and vice-versa.

## Symptoms

- A ticket is closed on evidence, but sibling tickets covering the same class remain open with no prompt, or a close proceeds without noticing an overlapping sibling that changes the picture.

## Impact Assessment

- **Who is affected**: maintainer; backlog drifts as sibling families fall out of sync at close time.
- **Frequency**: any close with an open sibling family (common in this corpus).
- **Severity**: High — silent family drift; the highest-priority of the newly-triaged set.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a sibling-family completeness scan (friction-class keyword + Composes-with overlap) at the close gate across the three skills; surface siblings before allowing close.

## Dependencies

- **Composes with**: P076 (transitive-dependency WSJF — related graph mechanism, different action: close-gate scan vs effort propagation).

## Related

- Inbound issue #187.
