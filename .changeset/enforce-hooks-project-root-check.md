---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/voice-tone": patch
"@windyroad/style-guide": patch
"@windyroad/risk-scorer": patch
"@windyroad/tdd": patch
---

Add project-root check to all enforce hooks (P004). Absolute file paths outside the current project (e.g., ~/.claude/channels/discord/access.json) are no longer gated — gates now only fire on files within the project root.
