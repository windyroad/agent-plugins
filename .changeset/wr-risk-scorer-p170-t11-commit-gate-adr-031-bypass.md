---
"@windyroad/risk-scorer": patch
---

`risk-score-commit-gate.sh` recognises commit-message-embedded `RISK_BYPASS: adr-031-migration` token as a self-attestation bypass for adopter `docs/problems/` auto-migration commits (P170 / RFC-002 / ADR-031 T11 / Open-Execution Q3 lean (b)). Pure-rename + pure-mkdir migration commits emitted by `migrate_problems_to_per_state_layout` (shipped in `@windyroad/itil` T7/T8/T9) skip the full risk-score overhead while preserving the audit trail. Case-sensitive token match; `adr-031-MIGRATION` and unrelated tokens (e.g. `reducing`, `incident`) do NOT match this path. Future commit-message-embedded bypass markers MUST be added explicitly here and to ADR-014's commit-message convention table.
