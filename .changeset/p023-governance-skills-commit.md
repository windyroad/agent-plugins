---
"@windyroad/itil": patch
---

Governance skills now commit their own completed work (P023, ADR-014).

**@windyroad/itil**: `manage-problem` and `manage-incident` skills no longer end with "Do not commit — the user will commit when ready." They now instruct the agent to stage files, delegate to `wr-risk-scorer:pipeline` for a risk assessment, and commit automatically using a conventional commit message referencing the problem or incident ID. If risk is above appetite, an `AskUserQuestion` prompt is presented before committing. Non-interactive fail-safe per ADR-013 Rule 6.

New ADR-014 documents the cross-skill commit pattern, commit message convention, and risk-gate delegation sequence.
