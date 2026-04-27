---
"@windyroad/itil": patch
---

P135 Phase 3 (AFK loop redesign — `@windyroad/itil`) per ADR-044 (Decision-Delegation Contract).

Redesigns the `/wr-itil:work-problems` AFK loop to be the empirical-discovery engine ADR-044 describes. Direction-class observations + deviation candidates accumulate from real friction across iters; loop-end Step 2.5 presents the batched questions as the primary deliverable.

**ITERATION_SUMMARY.outstanding_questions schema** (Phase 3 + R7):
- Field is now mandatory non-empty when iter touched a direction / deviation-approval / one-time-override / silent-framework decision; otherwise empty array.
- Each entry tagged with category for Step 2.5 ranking.
- New **deviation-candidate entry shape**: when iter encounters an existing decision (ADR / SKILL / WSJF / RISK-POLICY) that current evidence contradicts, agent queues a candidate with `existing_decision` citation + `contradicting_evidence` citation per ADR-026 grounding + `proposed_shape ∈ {amend, supersede, one-time}` + `rationale`. Agent does NOT auto-deviate; never blindly follows against evidence. Not-queueing-when-strong-contradicting-evidence-exists is a regression per the bats coverage.

**Step 2.5 (loop-end emit)** — promoted from "fallback when stop-condition #2" to **default loop-end emit shape**. Reads `.afk-run-state/outstanding-questions.jsonl`, de-duplicates, ranks (deviation-approval > direction > one-time-override > silent-framework > taste > correction-followup), presents as batched `AskUserQuestion` per ADR-013 Rule 1 cap. Deviation-candidate entries get the 5-option `AskUserQuestion` (Approve+amend / Approve+supersede / Approve+one-time / Reject / Defer); other entries get options extracted from the entry's `question` text.

**Between-iter aggregation**: orchestrator's main turn appends each iter's `outstanding_questions` entries to the session-level queue file at `.afk-run-state/outstanding-questions.jsonl` between Step 6 (report) and Step 6.5 (release-cadence check). Queue cleared after Step 2.5 resolves all entries. Per ADR-032 pending-questions artefact precedent.

**Mid-loop UserPromptSubmit handler** (R4) — when orchestrator receives user message during an iter, the in-flight iter MUST complete naturally to its `ITERATION_SUMMARY` emission BEFORE the orchestrator surfaces the queue + new direction. **Do NOT abort the iter mid-flight** (no SIGTERM to iter PID). Direct corrective for the 2026-04-27 iter-9-killed overcorrection — the user's correction was about future iter dispatch shape, not the in-flight iter; killing wasted ~$5 + 25 min in-flight work.

**Bats coverage** (Phase 3 R4 + R7):
- `packages/itil/skills/work-problems/test/work-problems-mid-loop-userpromptsubmit-handler.bats` (NEW per R4) — 7 assertions covering handler clause documentation, complete-naturally-to-ITERATION_SUMMARY contract, no-SIGTERM forbiddance, no-abort-mid-flight forbiddance, iter-9 precedent citation, queue-after-iter contract, $5+25min cost grounding.
- `packages/itil/skills/work-problems/test/work-problems-deviation-candidate-shape.bats` (NEW per R7) — 12 assertions covering schema documentation (existing_decision / contradicting_evidence / proposed_shape fields), no-auto-deviate contract, never-blindly-follow assertion, regression assertion (not-queueing-is-a-regression), 5-option loop-end emit, deviation-approval-highest ranking, jsonl persistence, ADR-032 precedent citation, anti-BUFD-for-framework-evolution rationale citation.

19/19 new bats green.

**Per-phase release cadence (R1) + preview-tag rollout (R2)**: Phase 3 ships `@windyroad/itil` patch via npm `preview` tag first (changesets dist-tag); exercise end-to-end against a real `/wr-itil:work-problems` AFK session verifying no-mid-loop-AskUserQuestion + outstanding-questions jsonl + mid-loop UserPromptSubmit handler all behave per spec; only after end-to-end verification, promote `preview` → `latest` via `npm dist-tag` promotion. If verification fails on `preview`, fix-and-republish without affecting `latest` consumers.

Refs: P135 (master), ADR-044 (anchor), ADR-014 (commit grain), ADR-026 (grounding), ADR-032 (pending-questions artefact precedent), ADR-013 Rule 1 narrowing precedent, P124 (verifying-flip-back precedent for deviation-approval reversibility), P122 / P126 (Step 2.5b surfacing routine precedent).
