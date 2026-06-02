---
'@windyroad/itil': patch
---

P312 (Open→Verifying, S, WSJF 3.0) — make `reconcile-rfcs` reverse-trace pass dual-tolerant of `docs/problems/` per-state subdir layout.

**Bug.** `wr-itil-reconcile-rfcs` (script `packages/itil/scripts/reconcile-rfcs.sh`) reported spurious `MISSING_REVERSE_TRACE` for every problem ticket that lived under `docs/problems/<state>/<NNN>-*.md` (the ADR-031 per-state subdir layout). The reverse-trace pass globbed flat `docs/problems/<NNN>-*.md` only — so any RFC frontmatter `problems: [P<NNN>]` claim against a subdir-migrated ticket false-flagged as MISSING. The sibling helper `update-problem-rfcs-section.sh` (called by capture-rfc Step 6 + manage-rfc Step 7+9) was already correctly emitting the `## RFCs` row on each ticket — the reconciler just couldn't see those tickets. Cry-wolf class defect: trains operators to distrust the reconciler, masks real missing-trace cases. Observed 2026-05-26 during the RFC-006/007 finalize (ADR-070/071 implementation) — 4 spurious lines for P251/P310/P260 whose `## RFCs` sections were verified correct by direct inspection.

**Fix.** RFC-002-class dual-tolerant-glob, mirroring the sibling precedent already shipped in `reconcile-readme.sh` lines 74-110 (P118). The reverse-trace pass now assembles problem-file candidates from both:

- Flat `$PROBLEMS_DIR/<NNN>-*.md` (legacy / mid-migration tickets).
- Per-state `$PROBLEMS_DIR/<state>/<NNN>-*.md` for state ∈ {open, known-error, verifying, closed, parked} (ADR-031 authoritative layout).

The downstream `MISSING_REVERSE_TRACE` / `STALE_REVERSE_TRACE` / `STATUS_MISMATCH` logic is unchanged.

**Verification on this repo.** Pre-fix `wr-itil-reconcile-rfcs docs/rfcs` reported 16 `MISSING_REVERSE_TRACE` lines (all spurious — RFC-001/P168, RFC-002/P069, RFC-003/P170, RFC-004/P079, RFC-005/P251, RFC-006/P251, RFC-006/P310, RFC-007/P260, RFC-008/P315, RFC-009/P317, RFC-010/P318, RFC-011/P323, RFC-012/P012, RFC-012/P324, RFC-013/P346, RFC-014/P337 — all tickets demonstrably carry the correct `## RFCs` row). Post-fix: 2 lines (RFC-003/P170 + RFC-012/P012 — genuine pre-existing drift in tickets whose `## RFCs` sections are empty; separate scope per ADR-014 single-purpose).

**Coverage.** Two new behavioural bats cases per ADR-052 (`packages/itil/scripts/test/reconcile-rfcs.bats` cases 25–26):

- `P312: reverse-trace clean when problem ticket lives in per-state subdir` — was RED pre-fix (proved the bug — `MISSING_REVERSE_TRACE` fired against a correctly-traced subdir ticket), GREEN post-fix.
- `P312: reverse-trace detects missing trace when problem ticket lives in per-state subdir` — confirms the diagnostic still fires for genuinely-missing reverse-traces under the new layout.

**Compliance.** Architect verdict 2026-06-02: PASS — no new ADR required; restores compliance with existing ADR-031 Confirmation criterion #4 (dual-tolerant globs) + #5 (behavioural regression test). JTBD verdict 2026-06-02: PASS — JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover) restoration of trust signal in the reverse-trace audit-trail report. ADR-014 single-purpose commit grain (test + fix + ticket transition + changeset in one commit; downstream pre-existing drift left out of scope).
