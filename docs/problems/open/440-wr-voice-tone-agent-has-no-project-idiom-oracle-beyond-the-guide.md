# Problem 440: wr-voice-tone:agent has no project-idiom oracle beyond the guide — passes phrases that violate the author's personal voice

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#316)
**Effort**: M. WSJF = (6 × 1.0) / 2 = 3.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`wr-voice-tone:agent` checks against `docs/VOICE-AND-TONE.md`'s abstract principles but has no project-idiom oracle, so it passes phrases that satisfy the abstract guide while failing the author's editorial bar ("came due", "narrative tide turns", abstract-noun stacks).

## Symptoms

- Copy matching the guide's principles but violating the author's actual voice passes the gate; the author must catch it by hand.

## Impact Assessment

- **Who is affected**: the author + adopters wanting voice-tone to reflect a real editorial voice, not just abstract principles.
- **Frequency**: any copy using guide-compliant but off-voice idioms.
- **Severity**: Medium — misses a class of voice violations; generalizable capability gap.

## Root Cause Analysis

### Investigation Tasks

- [ ] Add a project-vocabulary / "phrases the author doesn't use" reference (optionally seeded from a published-corpus pass) and have `wr-voice-tone:agent` consult it — a project-idiom oracle, adopter-portable.

## Dependencies

- **Composes with**: (distinct from P082 commit-message gating / P276 external-comms over-fire).

## Related

- Inbound issue #316.
