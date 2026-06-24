---
"@windyroad/itil": minor
"@windyroad/risk-scorer": minor
---

Risk gates apply your RISK-POLICY appetite faithfully — no above-appetite commit prompt, no hidden overrides.

RISK-POLICY says: above appetite, reduce the risk or stop — never "ask permission to proceed anyway." That rule already governed releases, but the commit step contradicted it: skills asked you to confirm an above-appetite commit. They no longer do. Above appetite at any stage (commit, push, release) now auto-remediates to within appetite or halts — never a consent prompt.

- The commit/transition/incident skills drop the "commit anyway?" question; they follow the same auto-remediate-or-halt path the release step already used.
- Incidents are not an exception. An active incident is a risk already being realised, so an incident-response change is scored against that live baseline — a change that reduces net risk proceeds as risk-reducing (no prompt, no mid-outage gate), and one that doesn't is held like anything else.
- The pipeline and WIP scoring agents now read the appetite from your RISK-POLICY.md instead of assuming a fixed value, so a project that sets a different threshold is honoured.
- The unauthorised `BYPASS_RISK_GATE` environment override and the `ci-bypass` marker are removed. The sanctioned risk-reducing and incident paths remain.
- The risk-policy authoring skill now records which bypass scenarios are permitted, so the policy itself is the single source of truth.

Substance recorded under RFC-029 and amendments to ADR-013 / ADR-042 / ADR-044; driver P377.
