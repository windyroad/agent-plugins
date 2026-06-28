---
"@windyroad/risk-scorer": minor
---

SessionStart nudge now fires when RISK-POLICY.md is absent entirely (P379). The scaffold-nudge hook previously stayed silent unless a policy file existed and `docs/risks/` was missing; an adopter who installed the plugin but never authored a policy got the gate's default appetite with no surfacing that a policy could be authored. The hook now emits a one-line advisory pointing at `/wr-risk-scorer:update-policy` when no `RISK-POLICY.md` is present. Read-only, respects the `WR_SUPPRESS_OVERSIGHT_NUDGE=1` AFK guard, and stays silent when the project directory itself does not exist.
