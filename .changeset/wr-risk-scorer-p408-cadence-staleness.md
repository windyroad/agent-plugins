---
"@windyroad/risk-scorer": patch
---

The commit gate now derives its RISK-POLICY.md staleness threshold from the policy's stated review cadence (the `> Reviewed <cadence>` line): weekly=7, fortnightly/biweekly=14, monthly=30, quarterly=90, annually/yearly=365 days. When the cadence line is absent or the word is unrecognised, the previous 14-day threshold still applies. The deny message now names the derived threshold and cadence word. Fixes spurious "policy is stale" commit blocks for adopters whose stated review cadence exceeds 14 days (P408, ADR-091).
