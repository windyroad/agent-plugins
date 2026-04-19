---
"@windyroad/itil": patch
---

manage-problem: add XL effort bucket and effort re-rate pre-flight (P047)

- Effort table in `manage-problem` SKILL.md gains an **XL** bucket (divisor 8) for multi-day or cross-package work, with a new sub-example showing how WSJF flattens at XL and a live-estimate note pointing to steps 7 and 9b.
- **Step 7** Open → Known Error pre-flight gains a checklist item requiring the effort bucket to be re-rated against the now-documented fix strategy, with the reason captured in the problem file.
- **Step 9b** step 7 reworded from "Estimate Effort" to "Re-estimate Effort (S / M / L / XL) ... note the reason in a short parenthetical" so the review re-rate is unmissable.
- `work-problems` SKILL.md example paragraphs updated non-normatively to reference "S to L or XL" for consistency.
- New doc-lint test `manage-problem-effort-buckets.bats` (4 assertions) guards the new contract.
