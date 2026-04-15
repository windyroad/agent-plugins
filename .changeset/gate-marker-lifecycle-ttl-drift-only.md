---
"@windyroad/architect": minor
"@windyroad/jtbd": minor
"@windyroad/voice-tone": minor
"@windyroad/style-guide": minor
"@windyroad/risk-scorer": minor
---

Gate markers now persist across prompts (ADR-009). Removed Stop-hook reset scripts from all 5 review plugins. Marker lifecycle is now governed entirely by TTL (30 min default, configurable via `*_TTL` env vars) + drift detection of policy files. Resolves P001 — reviews no longer need to re-run on every prompt. Note: this is a behaviour change; users who relied on fresh-review-every-prompt should set a shorter TTL.
