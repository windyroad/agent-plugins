---
"@windyroad/risk-scorer": patch
---

Recognize Codex 0.153 dotted collaboration hook names and decode results wrapped in `input_text` arrays before persisting risk-scoring completion markers. This prevents valid pipeline scores from being silently discarded after `interrupt_agent`.
