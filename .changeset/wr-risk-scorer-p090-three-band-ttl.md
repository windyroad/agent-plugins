---
"@windyroad/risk-scorer": patch
---

Three-band TTL policy in `check_risk_gate` eliminates the manual rescore round-trip when the working tree is unchanged but the clock has moved past the half-life of the marker (P090).

- **Band A** (age < TTL/2) → pass silently (unchanged).
- **Band B** (TTL/2 ≤ age < TTL) → if the pipeline state-hash is invariant since the scorer ran, pass and slide the marker forward; if the hash drifted, halt as before. Bounded by a 2×TTL hard-cap from a new `<action>-born` sibling so an unchanged-but-idle tree cannot ride a single score indefinitely.
- **Band C** (age ≥ TTL) → halt with the existing expired message (unchanged).

`git-push-gate.sh` push-gate now routes through `check_risk_gate "push"` and inherits the band logic (previously carried its own inline binary TTL check). Push-specific threshold guidance preserved via a new `RISK_GATE_CATEGORY` export.

Backward-compatible: markers written before this release have no `-born` sibling and retain the pre-P090 binary TTL behaviour until the next scorer run writes both files.

ADR-009 amended with a three-band refinement footnote.
