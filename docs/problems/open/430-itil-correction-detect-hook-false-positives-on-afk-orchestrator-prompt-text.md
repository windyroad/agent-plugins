# Problem 430: itil-correction-detect UserPromptSubmit hook false-positives on orchestrator / AFK prompt text

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Origin**: inbound-reported (#257)
**Effort**: S. WSJF = (8 × 1.0) / 1 = 8.0.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`itil-correction-detect.sh`'s `CORRECTION_SIGNAL_PATTERNS` (DO NOT / NEVER / MUST NOT / all-caps) has no provenance check: it fires on orchestrator- and AFK-generated prompt text that legitimately contains those tokens, mis-classifying framework prose as a user correction and nudging a capture-problem offer on nearly every AFK iter.

## Symptoms

- An AFK iter prompt or orchestrator instruction containing "MUST NOT"/"NEVER" trips the correction detector → spurious capture-on-correction nudge with no real user correction.

## Impact Assessment

- **Who is affected**: AFK loops; noise + spurious ticket-capture offers.
- **Frequency**: most AFK iters (orchestrator prompts routinely carry imperative tokens).
- **Severity**: Medium — noise, not incorrect action, but erodes the signal.

## Root Cause Analysis

### Investigation Tasks

- [ ] Skip prompts carrying AFK/orchestrator markers, or add an AFK branch to the injected instruction; require a user-authored provenance signal before the correction nudge fires.

## Dependencies

- **Composes with**: (distinct from the P268 / P272–275 "substring-matches git commit" hook-detector family — same over-fire class, different hook).

## Related

- Inbound issue #257. Pattern vocabulary: `packages/itil/hooks/lib/detectors.sh::CORRECTION_SIGNAL_PATTERNS`.
