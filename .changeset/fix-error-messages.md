---
"@windyroad/risk-scorer": patch
---

Fix misleading error messages in risk-gate.sh that said the risk-scorer "runs automatically on each prompt". It doesn't — the agent must explicitly delegate to wr-risk-scorer:pipeline.
