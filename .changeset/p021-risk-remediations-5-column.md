---
"@windyroad/risk-scorer": patch
---

fix(risk-scorer): expand RISK_REMEDIATIONS to 5-column format (closes P021)

- Adds `effort S/M/L` and `risk_delta -N` columns to RISK_REMEDIATIONS format
- Updated in pipeline.md, wip.md, and plan.md agents
- Structural BATS tests added to enforce format
