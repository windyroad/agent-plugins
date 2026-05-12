---
"@windyroad/itil": patch
---

`work-problems` SKILL.md gains a new Step 0a (Auto-migrate adopter layout) inserted AFTER Step 0 fetch/divergence preflight and BEFORE Step 1 backlog scan. Sources `packages/itil/lib/migrate-problems-layout.sh` and calls `migrate_problems_to_per_state_layout`. Closes the Step 1 false-zero defect — flat-layout adopters without Step 0a would have their Step 1 glob return zero matches at the per-state shape and stop-condition #1 would fire incorrectly, never reaching the inner manage-problem migration. Both `work-problems` and `manage-problem` carry Step 0a per ADR-031 line 126 "Why both skills" rationale.
