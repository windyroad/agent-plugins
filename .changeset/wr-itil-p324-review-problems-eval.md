---
"@windyroad/itil": patch
---

P324 Phase 2 — paired promptfoo Tier-A/B eval for the `/wr-itil:review-problems` SKILL surface. Extends the Phase 1 reference slice (work-problems eval shipped earlier this session as `@windyroad/itil@0.47.15`) under ADR-075 Amendment 2026-06-02 + RFC-012, applying the harness pattern to the inbound-discovery + assessment-pipeline behavioural contracts.

Coverage (6 tests across the Step 4.5 verdict-shape + AFK-marker surface, 6/6 GREEN on first run, 1m 6s wall-clock):

- **Step 4.5e Step 6 safe-and-valid accepted-into-backlog ack** (P229) — reporter-facing comment body names the freshly allocated local ticket P-id and gives an actionable expectation; no `safe-low-fix-risk` / `safe-and-valid-local-ticket-created` / `docs/problems/` / `Step 4.5e` framework-vocab leakage.
- **Step 4.5d matched-local-ticket duplicate cross-reference ack** (P229) — body names the matched local P-id and uses duplicate-verdict language; no legacy `Tracked locally as docs/problems/...` boilerplate, no `matched-local-ticket` classification-token leak.
- **Step 4.5e Step 4 above-threshold-pushback won't-fix ack** (P229) — body declares won't-fix in plain language with a plain-language reason gloss; the raw `out-of-scope-for-documented-personas` token stays on the audit-log surface (4.5f), not in the reporter-facing body.
- **Step 4.5e Step 5 clear-malicious policy-violation-close (5th implicit verdict)** (P229) — immediate close (stronger than won't-fix per JTBD-301 verdict-shape table), plain-language gloss of the policy class, misclassification-escape sentence; raw `wr-risk-scorer:inbound-report` verdict token does NOT substitute into the reporter-facing body.
- **JTBD-301 four-documented-verdict contract briefing** (P229) — all 4 documented JTBD-301 verdicts (`fix released` / `accepted into backlog` / `duplicate` / `won't-fix`) AND the 5th implicit `policy-violation close` are named, with the 5th correctly characterised as STRONGER than won't-fix.
- **Step 4.5 § 6 AFK-marker / I12 derive-then-ratify** (P287) — `--no-prompt` is the AFK-mode marker; `/wr-itil:capture-problem` derives persona + JTBD from the report body; derivation-failure with no `--persona=` / `--jtbd=` flags supplied → halts-with-stderr-directive + records `cache_audit_note: gate-denied-safe-and-valid-derive-failure`; NO silent fallback to `type=technical` (the type-classification axis was retired per twice-confirmed user direction 2026-05-25 + 2026-06-02).

Per ADR-061 Rule 4 evidence-floor: this paired-and-passing eval IS the per-class evidence flipping the R009 prose-surface modulator +1 → -1 for `review-problems`, dropping 2 review-problems-surface held changesets (P229 + P287) within appetite atomically as cohort-graduation candidates on the next Step 6.5 pre-check on interactive user return.

Eval files excluded from the published tarball per `packages/itil/.npmignore` line 13 (`skills/*/eval/`). Architect PASS + JTBD PASS on the new files (ADR-075 / ADR-061 / ADR-014 / ADR-052 / ADR-062 / RFC-012 alignment; JTBD-001 / JTBD-006 / JTBD-007 / JTBD-101 / JTBD-301 served; no new decision required — purely additive following the Phase 1 reference precedent). Subscription auth — no API key.
