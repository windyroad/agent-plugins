---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

Guide Codex agents to start a fresh typed reviewer after remediation or review expiry. Completed-agent follow-ups do not produce a new bound marker, so the gates now explain the safe recovery path. Risk scorer also verifies that a fresh lower score replaces the earlier result while an opaque follow-up leaves the earlier score unchanged.
