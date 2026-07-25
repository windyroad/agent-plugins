# Problem 438: Assistant routes free-text collection (URLs/tokens/IDs) through AskUserQuestion instead of per-item copyable blocks

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#324)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**WSJF**: 6 — (6 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

When the assistant needs to collect free-text items (URLs, tokens, IDs), it routes them through `AskUserQuestion`, whose "Other" field cannot capture pasted free-text cleanly. Witnessed on the P091 unresolvable-URL fallback: it took three user corrections before the assistant presented one copyable block per URL.

## Symptoms

- Free-text collection surfaced as AskUserQuestion options; the user cannot paste, leading to repeated corrections. The right shape is one copyable block per item.

## Impact Assessment

- **Who is affected**: the user, on any free-text collection task.
- **Frequency**: whenever free-text (not bounded options) is collected via AskUserQuestion.
- **Severity**: Medium — UX friction + repeated corrections; not incorrect action.

## Root Cause Analysis

### Investigation Tasks

- [ ] Behavioural guidance: present each free-text item as its own copyable block; reserve AskUserQuestion for bounded, mutually-exclusive options.

## Dependencies

- **Composes with**: (distinct from the AskUserQuestion decision-surfacing tickets P340/P350/P302/P283 — this is text collection, not decision surfacing).

## Related

- Inbound issue #324.
