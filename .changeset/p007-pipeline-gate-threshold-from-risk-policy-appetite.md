---
"@windyroad/risk-scorer": minor
---

The pipeline risk gate now reads its block threshold from the project's RISK-POLICY.md risk appetite instead of a hardcoded 5. It blocks when the assessed score exceeds the appetite parsed from the Risk Appetite section (tolerant of "Threshold: N", "exceeds N", and "N/Low appetite"), with an optional RISK_APPETITE environment override. When RISK-POLICY.md is absent or states no appetite number it defaults to 4, which reproduces the previous score >= 5 behaviour exactly for integer scores, so existing installs see no change. Adopters whose policy sets a higher appetite no longer have within-appetite changes rejected, and the deny message now names the actual appetite applied. Fixes #149 (P007). See ADR-065.
