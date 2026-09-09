---
"@windyroad/risk-scorer": patch
---

Codex checkout-mismatch recovery no longer depends on an optional runtime environment variable. A valid score is preserved and the gate tells the agent to retry from the assessed checkout instead of rescoring or bypassing.
