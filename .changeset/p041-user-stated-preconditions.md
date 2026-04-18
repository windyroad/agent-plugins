---
"@windyroad/risk-scorer": patch
---

Risk scorer now honours user-stated preconditions.

- `pipeline.md`, `wip.md`, and `plan.md`: new **User-Stated Preconditions Check** section requires the scorer to inspect recent conversation, problem tickets, commits, and changesets for user-stated conditional-delivery warnings ("A is only safe if B ships alongside")
- Unmet preconditions surface as standalone Risk items with inherent risk >= Medium (>= 5), routing into the existing above-appetite `RISK_REMEDIATIONS:` flow rather than being buried in prose or ignored because the diff's technical risk scored Low
- Doc-lint guard test `risk-scorer-user-stated-preconditions.bats` prevents regression across all three scoring modes
