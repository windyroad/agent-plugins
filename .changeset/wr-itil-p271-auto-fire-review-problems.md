---
"@windyroad/itil": patch
---

review-problems auto-fire trigger — Step 0c orchestrator pre-flight (P271)

Ships a 2-axis AND trigger (count ≥ 3 deferred-placeholder tickets AND
`docs/problems/README.md` "Last reviewed" line-3 age > 7 days) that
auto-dispatches `/wr-itil:review-problems` from three SKILL surfaces so the
maintainer no longer has to remember to invoke review-problems after
deferred-placeholder captures accumulate.

Driving incident: the 2026-05-24 work-problems session evidenced 83 deferred
placeholders accumulated across multiple AFK loops because review-problems
never auto-fired. AFK orchestrator iters dispatched against stale WSJF
rankings until the maintainer manually invoked review-problems.

The trigger composes ADR-013 Rule 5 (policy-authorised silent proceed) +
ADR-044 cat 4 (silent framework action) + ADR-062 Step 0b inbound-discovery
staleness precedent (same helper-in-lib + run-wrapper + bin-shim +
behavioural bats shape; same `claude -p` subprocess dispatch).

**Two-axis AND rule (load-bearing per architect verdict)**: either axis
alone over-fires. Count ≥ 3 alone fires when 3 captures came in today after
yesterday's review (the in-spec behaviour). Age > 7 days alone fires on
quiet weeks where there's nothing to re-rate. The intersection — "there is
work to do AND the cadence has slipped" — is the actual signal.

**AFK vs interactive surface asymmetry** per ADR-013 Rule 1 +
JTBD-001's 60-second flow contract:
- work-problems Step 0c: AFK auto-dispatch via `claude -p` subprocess.
- manage-problem Step 0.5: interactive advisory only — auto-dispatch
  would break the flow contract.
- capture-problem Step 7: conditional trailing pointer highlight — no
  auto-dispatch (ADR-032 lightweight contract preserved).

Ships:
- `packages/itil/lib/check-deferred-placeholder-staleness.sh` — new helper
  exporting `should_promote_review_problems_dispatch` (5-outcome enum).
- `packages/itil/scripts/run-check-deferred-placeholder-staleness.sh` —
  adopter-safe wrapper.
- `packages/itil/bin/wr-itil-check-deferred-placeholder-staleness` —
  ADR-049/ADR-080 PATH shim regenerated from canonical template.
- `packages/itil/skills/work-problems/SKILL.md` Step 0c amendment.
- `packages/itil/skills/manage-problem/SKILL.md` Step 0.5 amendment.
- `packages/itil/skills/capture-problem/SKILL.md` Step 7 refinement.
- `packages/itil/skills/work-problems/test/work-problems-step-0c-deferred-placeholder-staleness-behavioural.bats`
  — 12 behavioural test cases (5-outcome enum + dual-tolerant glob per
  ADR-031 RFC-002 migration window + defensive fallbacks +
  closed/verifying exclusions).

Contract-source markers `<!-- DEFERRED-PLACEHOLDER-STALENESS-CONTRACT-SOURCE -->`
placed at the helper + all three SKILL surfaces so future threshold edits
(3 placeholders, 7 days) update all four surfaces in the same commit.

P271 transitions Open → Verification Pending (P143-class fold-fix per
ADR-022 amendment — root cause + Fix Strategy + workaround documented
inline; pre-flight criteria met).

@problem P271
