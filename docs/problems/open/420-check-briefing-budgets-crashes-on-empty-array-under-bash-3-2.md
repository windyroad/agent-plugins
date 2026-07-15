# Problem 420: check-briefing-budgets.sh crashes with `must_split[@]: unbound variable` on empty arrays under macOS default bash 3.2

**Status**: Open
**Reported**: 2026-07-05
**Priority**: 8 (Medium) — Impact: 2 (Minor — retro Tier-3 budget pass degrades to fail-open pointer) × Likelihood: 4 (Likely — deterministic under macOS default bash 3.2 whenever the array is empty; CI bash 5 masks it) — re-rated 2026-07-15 /wr-itil:review-problems
**Origin**: internal
**Effort**: S — `${arr[@]+"${arr[@]}"}` empty-array guard + bats under bash 3.2
**WSJF**: 8.0 — (8 × 1.0) / 1 (S — one-line guard, re-sized from M at 2026-07-15 review)
**JTBD**: JTBD-006
**Persona**: developer

## Description

`packages/retrospective/scripts/check-briefing-budgets.sh` aborts with `line 137: must_split[@]: unbound variable` when the `must_split` array is empty and the script runs under a bash where `set -u` treats empty-array expansion as unset — macOS `/bin/bash` 3.2 and `sh`-invoked runs. Witnessed 2026-07-05 P408 iter retro: `sh packages/retrospective/scripts/check-briefing-budgets.sh docs/briefing` crashed at line 137 while `bash` (homebrew 5.x on PATH) exited 0 cleanly. The run-retro Tier 3 budget pass depends on this script; an adopter whose default bash is 3.2 gets a crashed advisory instead of the OVER/MUST_SPLIT report, and the retro's fail-open contract degrades the pass to a one-line pointer every time. Fix shape: guard empty-array expansions with the portable `${arr[@]+"${arr[@]}"}` idiom (same BSD/GNU-divergence portability class as the P334/P328/P366/P380/P392 awk/find family).

## Symptoms

- `sh packages/retrospective/scripts/check-briefing-budgets.sh docs/briefing` → `line 137: must_split[@]: unbound variable`, non-zero exit.
- Same invocation via homebrew bash 5.x exits 0 with correct output — CI (Linux, bash 5) stays green, masking the defect.

## Workaround

Invoke via a bash ≥ 4.4 (`bash packages/retrospective/scripts/check-briefing-budgets.sh ...`); the run-retro fail-open contract also degrades gracefully (advisory skipped, pointer emitted).

## Impact Assessment

- **Who is affected**: adopters running run-retro on macOS default bash; AFK retro passes
- **Frequency**: every Tier 3 budget pass on affected shells when no file crosses the 2x MUST_SPLIT ceiling (empty array is the common case)
- **Severity**: Low — advisory-only surface; fail-open degrades rather than blocks
- **Analytics**: N/A

## Root Cause Analysis

Empty-array expansion under `set -u` is an error in bash < 4.4; the script expands `${must_split[@]}` (and possibly siblings) unguarded. CI's bash 5 masks it — same masked-portability class as the BSD/GNU awk and `find -P` divergences (P334/P328/P366/P380/P392).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Audit all `packages/*/scripts/*.sh` for unguarded empty-array expansion under `set -u` (the class, not just line 137)
- [ ] Create reproduction test (bats fixture pinning bash 3.2 semantics or a guard-idiom assertion)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: (none)

## Related

- P099 (briefing grows unbounded; verifying) — parent surface that shipped this script.
- P322 (budget pass flags archive-sink files; verifying) — sibling defect on the same script.
- BSD/GNU portability family: P334, P328, P366, P380, P392 (awk `\b`, awk newline-in-string, `find -P` symlink, etc.).
- Hang-off pre-filter surfaced >5 body-signal candidates (all verifying-state budget-policy tickets) — candidate-cap short-circuit; arbitration deferred to the next `/wr-itil:review-problems` cluster pass.
- Witnessed: 2026-07-05 P408 AFK iter retro (Step 3 Tier 3 budget pass).

(captured via /wr-itil:capture-problem; expand at next investigation)
