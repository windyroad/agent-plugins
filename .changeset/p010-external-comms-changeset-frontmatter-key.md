---
"@windyroad/risk-scorer": patch
"@windyroad/voice-tone": patch
---

The external-comms gate now strips the changeset YAML frontmatter and normalizes trailing whitespace before computing the review-marker key, so the key the gate checks at author time matches the key the mark hook writes after the reviewer returns PASS. This fixes the deny-after-PASS loop that blocked changeset authoring even after the external-comms reviewer passed. The gate and the mark hook now share one key function, so the two sides cannot drift apart again. Closes #149 (P010) and P198.
