---
"@windyroad/risk-scorer": patch
---

Tighten `RISK_BYPASS: reducing` criteria to restore discriminating power.

- `pipeline.md`: reducing bypass now requires one of (1) ticket closure,
  (2) remediation of a previously-flagged risk, or (3) removal of a
  documented risk. Ordinary docs-only edits, test-only additions without
  a remediation link, and routine refactors are now risk-neutral and do
  NOT earn the bypass label.
- Added companion `RISK_BYPASS_REASON:` line — every reducing bypass must
  cite the ticket closed, prior report remediated, or removed risk. This
  makes the bypass auditable.
- Doc-lint guard `risk-scorer-reducing-bypass-criteria.bats` prevents
  regression.
- Background: 329-report retrospective across 6 projects showed the
  previous loose criteria applied `reducing` to 97.9% of commits in this
  repo and 79.6% across consumer projects, rendering the label
  meaningless. Only 2 of 96 reports omitted it.
