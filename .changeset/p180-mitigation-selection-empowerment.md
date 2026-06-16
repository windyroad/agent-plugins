---
"@windyroad/itil": patch
---

P180: empower agent-driven mitigation selection during active incidents. The `mitigate-incident` "Reversible preference" and `manage-incident` "Mitigation preference" sections now carry an explicit ADR-044 framework-mediated / category-4-silent-family annotation: selecting *which* mitigation to attempt — within the reversible-preference ladder, with cited evidence, within risk appetite — is agent-owned and must not be deferred to the user via `AskUserQuestion` or a prose-ask ("I'll wait for your direction on which mitigation to attempt"). The genuine user-authority surfaces are unchanged: the evidence-gate bypass (category-2 deviation-approval) and the risk-above-appetite commit (category-3 one-time-override). Closes the inverse-P078 over-ask (P132 class) on the mitigation-selection surface.
