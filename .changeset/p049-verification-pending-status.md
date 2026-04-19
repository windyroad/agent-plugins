---
"@windyroad/itil": minor
---

Add Verification Pending `.verifying.md` problem-lifecycle status per ADR-022
(P049 — the SKILL.md contract half; existing-file migration follows in a
separate commit per ADR-022 Scope).

- **manage-problem SKILL.md**: lifecycle table gains Verification Pending
  status and `.verifying.md` suffix; WSJF multiplier table documents
  Verification Pending = 0 (excluded from dev ranking); Known Error →
  Verification Pending transition documented (git mv + Status field +
  `## Fix Released` in one commit per ADR-014); step 9b skips
  `.verifying.md` files; step 9c gains a Verification Queue section; step
  9d targets `*.verifying.md` via glob; step 9e README template gains the
  Verification Queue section; closing workflow and commit-convention
  prose updated.
- **work-problems SKILL.md**: step 1 scan excludes `.verifying.md`; step 4
  classifier row `Known Error with ## Fix Released` → `.verifying.md`
  (suffix-based, no file-body scan).
- **manage-incident SKILL.md**: step 9 linked-problem close gating accepts
  `.verifying.md` alongside `.known-error.md` and `.closed.md`.
- **docs/problems/README.md**: "Known Errors (Fix Released — pending
  verification)" shadow table replaced with "Verification Queue" citing
  ADR-022.
- 11 new structural bats assertions in
  `manage-problem-verification-pending.bats`; full project suite
  264/264 green (+11).
