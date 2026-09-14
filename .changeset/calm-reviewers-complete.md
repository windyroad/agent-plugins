---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

Fix Codex reviewer completion handling so dotted collaboration events and `input_text` response arrays reach existing marker writers. JTBD now ships the same completion bridge. Architect and risk-scorer reuse the canonical decoder while keeping their package-specific safeguards.
