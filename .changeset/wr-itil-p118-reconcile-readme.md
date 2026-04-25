---
"@windyroad/itil": patch
---

`docs/problems/README.md` now self-heals from cross-session drift (P118).

A new diagnose-only script `packages/itil/scripts/reconcile-readme.sh` checks
the README's WSJF Rankings, Verification Queue, and Closed sections against
the on-disk ticket files (`docs/problems/<NNN>-*.<status>.md`). Exit codes:
0 = clean, 1 = drift detected (one structured row per drift entry to stdout,
≤150 bytes per ADR-038 progressive-disclosure budget), 2 = parse error.

A new skill `/wr-itil:reconcile-readme` wraps the script with an agent-applied-
edits pattern that preserves the README's narrative content (the "Last reviewed"
prose paragraph at the top and the per-row closure-via free text in the Closed
section). Full README regeneration is forbidden — narrative content is human-
curated session memory.

Two preflight invocation surfaces fire the script before doing anything else:

- `/wr-itil:manage-problem` Step 0 — halt-with-directive on drift before parsing
  the request, so ticket creation / update / transition never proceeds against
  a stale README that would re-encode the lie into the post-operation refresh.
- `/wr-itil:work-problems` Step 0 — auto-apply via `/wr-itil:reconcile-readme`
  in AFK mode (per ADR-013 Rule 6) so the orchestrator's Step 3 ranking reads
  ground truth.

`/wr-itil:transition-problem` deliberately does NOT invoke the script — P062's
existing transition-time refresh inside the same commit already covers that
surface; redundant preflight there would pay the cost on every transition.

This is a robustness layer ON TOP of P094 (refresh-on-create, Closed) and P062
(refresh-on-transition, Closed) — both per-operation contracts remain in force.
The reconciliation contract catches drift introduced by past sessions where the
single-commit-transaction discipline was skipped (bug, partial-progress hand-
off, conflict resolution, etc.) and that no per-operation contract can
retroactively detect or correct.

ADR-014 amended with a "Reconciliation as preflight robustness layer" sub-rule
(P118, 2026-04-25). ADR-022 Confirmation criterion 3 extended with a
reconciliation invariant cross-referencing the new script.
