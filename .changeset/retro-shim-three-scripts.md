---
"@windyroad/retrospective": patch
---

Fix adopter exit-127 on three retrospective diagnostics. `run-retro` and `analyze-context` instructed the agent to invoke `check-ask-hygiene.sh`, `check-briefing-budgets.sh`, and `check-tickets-deferred-cause.sh` by their repo-relative paths, which do not exist in an installed adopter tree — so the skill hard-failed the moment it reached those steps. Each script now has a `bin/`-on-`PATH` shim (per ADR-049) and the skills invoke the shim name. The repo-relative-path lint is extended to catch the imperative "invoke `packages/…`" prose form that let this ship past the previous `bash packages/…`-only check.
