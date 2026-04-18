---
"@windyroad/risk-scorer": patch
---

Risk scorer refuses to credit monitoring as a control.

- `pipeline.md`, `wip.md`, `plan.md`: Control Discovery now contains an
  explicit "Monitoring is not a control" rule. Monitoring, alerting,
  dashboards, "watch for elevated errors", and "be ready to rollback"
  MUST NOT be credited or reduce residual risk. Post-release detection
  shortens time-to-notice; it does not reduce pre-release risk.
- Doc-lint guard `risk-scorer-monitoring-not-a-control.bats` (6 assertions)
  prevents regression across all three scoring modes.
- Previously, 329-report corpus analysis showed scorers crediting
  monitoring as a control, producing false-confidence residual risk
  scores on releases with genuine pre-release risk gaps.
