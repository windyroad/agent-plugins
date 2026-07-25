# Problem 436: Issue templates declare labels ('problem', 'needs-triage') that don't exist; scaffold-intake should provision declared labels

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#170)
**Effort**: S. WSJF = (6 × 1.0) / 1 = 6.0.
**WSJF**: 6 — (6 × 1.0) / 1 (added 2026-07-26 review)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`.github/ISSUE_TEMPLATE/problem-report.yml` declares labels (`problem`, `needs-triage`) that don't exist in the repo. The web form silently drops them, and `gh issue create --label problem` hard-fails. Two-part fix: create the labels in the repo, and have `/wr-itil:scaffold-intake` provision declared labels downstream.

## Symptoms

- A reporter using the issue template gets the label dropped (web) or a hard failure (`gh --label`). New adopters scaffolding intake inherit the same gap.

## Impact Assessment

- **Who is affected**: reporters + adopters using the scaffolded intake.
- **Frequency**: every template-driven issue in a repo without the labels.
- **Severity**: Medium — degrades triage; `gh --label` path fails outright.

## Root Cause Analysis

### Investigation Tasks

- [ ] Create the declared labels in `windyroad/agent-plugins` (repo-admin; immediately actionable).
- [ ] Have `/wr-itil:scaffold-intake` provision labels declared by the templates it writes downstream.

## Dependencies

- **Composes with**: P065 (scaffold-intake — the natural home for the downstream provisioning), P207 (removed `--label` from the report-upstream example — the workaround for this root cause, not a fix).

## Related

- Inbound issue #170.
