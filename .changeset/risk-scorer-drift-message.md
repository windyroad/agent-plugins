---
"@windyroad/risk-scorer": patch
---

Fix misleading error messages in release gate: drift now clearly instructs "re-run risk-scorer", score-too-high retains "split/reduce/incident" guidance inline. Remove generic suffix in git-push-gate that conflated the two cases.
