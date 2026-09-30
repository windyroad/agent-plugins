---
"@windyroad/risk-scorer": patch
"@windyroad/architect": patch
---

Respect an explicit leading `cd` when a governed Codex command also carries a conflicting tool workdir. This keeps risk and decision gates bound to the checkout the command actually uses.
