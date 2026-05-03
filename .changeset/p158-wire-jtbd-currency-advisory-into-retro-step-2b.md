---
"@windyroad/retrospective": minor
---

P158: wire ADR-051 Phase 1 JTBD currency advisory into `/wr-retrospective:run-retro` Step 2b

`/wr-retrospective:run-retro` Step 2b now invokes `wr-retrospective-check-readme-jtbd-currency` (the ADR-051 Phase 1 detector shipped under P152) on every retro and surfaces drift findings in the retro summary's Pipeline Instability section. Wiring was originally deferred per ADR-051 Confirmation criterion 5 ("wiring into `/wr-retrospective:run-retro` Step 2b is deferred to a follow-on iter once the detector is empirically validated against current READMEs"); the validation precondition was met by the retroactive 12-plugin README refresh that landed alongside this change (commit 8df1692).

Adds:

- New "JTBD currency advisory (ADR-051 Phase 1, P158)" sub-section in run-retro Step 2b. Runs the detector advisory; emits one-line clean signal when `drift_instances == 0`, full per-package code block when `drift_instances ≥ 1`, fail-open inline log when the detector exits non-zero. Same fail-open contract as Step 3's `check-briefing-budgets.sh` defensive trip.
- `packages/retrospective/README.md` documents the wiring + lists every shipped advisory shim under a new `## Advisory scripts` section. Closes the residual `skill-inventory-drift` finding the detector was producing pre-wiring.

The change is advisory-only — `drift_instances` is signal-as-data, not a gate. Phase 2 escalation criterion (load-bearing hook iff `drift_instances ≥ 2` across 3 consecutive `chore: version packages` releases without correction) is captured inline so future contributors know the bar.

JTBD-302 (Trust That the README Describes the Plugin I Just Installed) is now serviced at retro-time rather than only at audit-prep time. JTBD-007 (Keep Plugins Current Across Projects) currency dimension extended from code-currency to README-content-currency per ADR-051.
