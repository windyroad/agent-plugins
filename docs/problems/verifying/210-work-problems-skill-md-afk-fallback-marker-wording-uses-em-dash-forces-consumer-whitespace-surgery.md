# Problem 210: work-problems SKILL.md AFK-fallback marker wording uses em-dash, forces consumer-side whitespace surgery

**Status**: Verification Pending
**Reported**: 2026-05-15
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The fallback-marker pattern in `packages/itil/skills/work-problems/SKILL.md` prose uses an em-dash (U+2014) in its canonical wording. Consumers parsing the marker (grep / awk / sed) need to handle the unicode character specifically — ASCII-only consumer scripts treat the em-dash differently from ASCII hyphen-minus, breaking the match.

## Workaround

Consumer-side scripts handle both em-dash and hyphen-minus variants (extra branch), or normalize unicode to ASCII before matching.

## Impact Assessment

- **Who is affected**: any consumer script that parses the AFK-fallback marker pattern from work-problems' iter output.
- **Frequency**: every parse.
- **Severity**: Low — consumer-side workaround is straightforward but the friction is repeated across every consumer.

## Root Cause Analysis

### Root cause

The canonical AFK-fallback marker `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` carried a U+2014 em-dash as the title→explanation separator. The marker is the documented detection substrate for the "already-noted check" run by every consumer of the upstream-report flow (`manage-problem` Step 6 / `transition-problem` Step 5 / `transition-problems` Step 2d / `work-problems` Step 4 upstream-blocked skip path). Consumers that grep / awk / sed the marker without unicode normalisation have to special-case the em-dash or normalise upstream — friction repeats per consumer.

### Fix

Switched the canonical write form to ASCII two-hyphen separator (` -- `) across the four SKILL surfaces that author the marker:

- `packages/itil/skills/work-problems/SKILL.md` — 3 occurrences in narrative prose describing the detection substrate.
- `packages/itil/skills/manage-problem/SKILL.md` — 4 occurrences (3 in the "Defer and note" / "Not actually upstream" / legacy reference, 1 in the Already-noted check description).
- `packages/itil/skills/transition-problem/SKILL.md` — 3 occurrences (Already-noted check, AFK fallback default body, false-positive recovery).
- `packages/itil/skills/transition-problems/SKILL.md` — 2 occurrences (Already-noted check, AFK fallback).

The legacy em-dash variant remains matched by the already-noted check across all four SKILLs for backward compatibility with prior-session ticket bodies — only the **canonical write form** changes; the **detection substrate** accepts both. The convention `"ASCII-only in machine-parseable identifiers; em-dash permitted in pure narrative prose"` is documented inline at the marker-write sites in `manage-problem/SKILL.md` (line ~705) and `transition-problem/SKILL.md` (under the marker code block) per the P210 Investigation Task line "Document the convention".

Bats fixtures updated to assert the canonical ASCII form (manage-problem-external-root-cause-detection.bats lines 5, 6, 15) plus a new assertion that the legacy em-dash variant remains documented for backward compatibility (new line 6 test).

### Investigation Tasks

- [x] Switch the em-dash to ASCII hyphen-minus in `packages/itil/skills/work-problems/SKILL.md` AFK-fallback marker wording.
- [x] Audit other SKILL.md prose for em-dash usage in machine-parseable identifiers / markers; switch to ASCII where consumer-parsing is implied. (Scope completed: the four upstream-report-flow SKILLs. Em-dashes in pure narrative prose elsewhere retained per the documented convention.)
- [x] Document the convention: ASCII-only in machine-parseable identifiers; em-dash permitted in pure narrative prose. (Inlined at the marker-write sites; no separate ADR — would fail the 2+ viable-options trigger for a `[Needs Direction]` ADR.)
- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems (carry forward — the deferred-placeholder line stays until review-problems re-rates).

## Fix Released

Released in @windyroad/itil@<TBD> via the standard release cadence. Verification: run `npx bats packages/itil/skills/manage-problem/test/manage-problem-external-root-cause-detection.bats` — 15 tests pass including the new P210 canonical-ASCII assertion and the backward-compatibility assertion for the legacy em-dash variant.

## Related

- **Reported Upstream**: https://github.com/windyroad/agent-plugins/issues/84
- **Pipeline classification**: JTBD-aligned; safe-low-fix-risk; route=safe-and-valid.
- **Affected plugin**: @windyroad/itil.
