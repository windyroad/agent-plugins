---
"@windyroad/itil": patch
---

work-problems: document Step 0b/0c/0d pre-flight subprocess failure handling (P358)

A pre-flight subprocess (`/wr-itil:review-problems` or `/wr-itil:check-upstream-responses` dispatched by Step 0b/0c/0d) that exits non-zero or returns `is_error: true` is now contractually NON-BLOCKING: the orchestrator reverts any dirty partial cache/audit/README write (per-path tolerant so an absent `docs/audits/` on a fresh adopter repo does not block the revert), unstages any staged residue (ADR-009), logs a one-line annotation, and proceeds to Step 1 with the existing README. Previously the "same shape as Step 5" prose left the failure semantics implicit, so a literal reading of Step 5's "non-zero → halt the loop" would halt the whole AFK loop on a non-load-bearing cache-refresh hiccup. This is orthogonal to the Step 5 iter SALVAGE/HALT taxonomy (P261/P214), which classifies an iter's `is_error: true` — the new contract classifies the pre-flight role, which never salvages and never halts the loop. ADR-032 amended; behavioural fixture added.
