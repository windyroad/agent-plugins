---
"@windyroad/itil": patch
---

work-problems Step 6.75: verify-iter-claims sub-step (P335)

When an iter committed cleanly but the commit message or `ITERATION_SUMMARY.notes` claims ADR Confirmation items are complete while on-disk `[ ]` checkboxes remain unticked, the orchestrator now detects the contradiction via `wr-itil-verify-iter-summary` and halts with `outcome: halted-iter-over-claim` instead of silently proceeding to the next iter.

The verifier (`packages/itil/scripts/verify-iter-summary.sh`, PATH shim `wr-itil-verify-iter-summary`) detects the *emit-but-over-claim* class — distinct from the *stuck-before-emit* class (P147) — by combining the commit message + notes against each cited ADR's `## Confirmation` section. Behavioural coverage in `packages/itil/scripts/test/verify-iter-summary.bats` (11 cases) plus a real-world reproduction against the P335 session 8 iter 1 witness commit (252702a / ADR-077).
