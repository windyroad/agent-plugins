---
'@windyroad/risk-scorer': patch
---

P193 (Open→Known Error, S, WSJF 3.0) — `risk-gate.bats:174` "Band B with no hash file" flake fixed by tightening the test's elapsed-time budget.

**Bug.** The test "Band B with no hash file: passes but does NOT slide (no invariance proof)" backdated the score file by 3s, slept 1s, then called the gate against TTL=5s. Elapsed at assertion-time was ~4–5s — parked on the TTL upper boundary. Under CI-runner timing the actual elapsed crossed 5s, the gate's strict-less-than `age < TTL` check fired the expired-branch, and the assertion red-failed. Recurrence 2026-05-28: CI run `26549501237` failed `not ok 572` on a docs-only commit (`ec6cf9e`) touching only `docs/problems/` + `docs/retros/` — zero risk-gate-relevant content. The false-red eroded the green-CI signal for `plugin-developer` (JTBD-101).

**Fix.** Option (b) from the ticket's investigation matrix: tighten the test's elapsed budget. One-line change in `packages/risk-scorer/hooks/test/risk-gate.bats:174` — `_backdate "$SCORE_FILE" 3` → `_backdate "$SCORE_FILE" 2`. New elapsed at assertion is ~3s, comfortably inside Band B's `[TTL/2, TTL) = [2.5, 5)` range with both a 0.5s headroom to the Band B lower bound and a 2s headroom to the TTL upper bound. The other two candidate fixes were rejected: option (a) (widen test TTL) would have required test-setup plumbing for no gain; option (c) (relax the gate to `age <= TTL`) would have changed the production contract and is the wrong fix for a test-flake.

**Production contract untouched.** The gate's `age < TTL` strict-less-than rule (ADR-009) is unchanged. This is a test-only timing-margin fix. No source change to `risk-score-commit-gate.sh` or `risk-gate.sh`.

**Coverage.** Verified deterministic across 5 sequential `npx bats hooks/test/risk-gate.bats` runs (28/28 GREEN each pass; test #14 explicitly OK on every run). No new bats fixture added — the existing test IS the reproduction surface; the fix is to make it stop straddling the boundary.

**Compliance.** Architect verdict 2026-06-03: PASS — no new ADR required; ADR-005 (Plugin Testing Strategy) confirmation criterion improved by the flake reduction; ADR-009 (Gate Marker Lifecycle) production semantics untouched. JTBD verdict 2026-06-03: PASS — serves JTBD-101 (`plugin-developer` "CI validates required files, package fields, installer dry-runs, and hook tests" desired outcome; flake-on-docs-only-commit was the exact JTBD-101 pain). Single ADR-014 commit covers the test fix + ticket Open→Known Error transition + README WSJF row re-position + README-history rotation per P134 + this changeset. Verifying transition deferred to post-release iter per ADR-022 (helper exit 3 — changeset still in working tree this commit).
