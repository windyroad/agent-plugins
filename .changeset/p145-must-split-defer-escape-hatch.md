---
"@windyroad/retrospective": patch
---

retrospective: `check-briefing-budgets.sh` now emits `MUST_SPLIT <basename> reason=ratio-exceeds-2x` for topic files at or above 2× the configured Tier 3 ceiling, in addition to the existing `OVER` line. `run-retro` Step 3 Tier 3 silent-agent rotation gains a Branch A heuristic that narrows the option set to split-by-subtopic / split-by-date (with split-by-date as the safe default) for `MUST_SPLIT` files — the `trim-noise` and `leave-as-is` defer escape hatches are not eligible. Branch B (only `OVER`, no `MUST_SPLIT`) retains the original four-option heuristic with defer permitted inside the reassessment-trigger envelope. This promotes ADR-040's "≥ 2× ceiling for ≥ 2 consecutive retro cycles" reassessment trigger from policy-revisit-time to per-cycle script enforcement, closing the recurring-defer accumulator gap (P145).
