# Problem 162: Codify dogfood-graduation criteria for held changesets — symmetric risk assessment (release-risk vs delay-risk) drives the reinstate decision, not arbitrary calendar guards

**Status**: Open
**Reported**: 2026-05-04
**Priority**: 12 (High) — Impact: Significant (3) x Likelihood: Almost certain (4)
**Effort**: M — new ADR (sibling to ADR-042) defining the graduation contract + risk-scorer extension to compute counterfactual delay-risk + behavioural bats covering the counterfactual scoring path + amendment to docs/changesets-holding/README.md "Process" section + retroactive application to currently-held P085, P064, P159 to establish baseline graduation evidence. Could grow to L if the risk-scorer extension requires a new evidence-collection pipeline (`.afk-run-state/dogfood-evidence.jsonl` reader + windowed metrics). Bounded M because the contract amendment + ADR + initial bats are well-scoped; the evidence pipeline can ride a Phase 2 ticket if needed.

**WSJF**: (12 × 1.0) / 2 = **6.0**

> Surfaced 2026-05-04 by user direction at end of `/wr-itil:work-problems` AFK loop iter 7 surfacing pass — verbatim: *"I love it. This is a really good pattern - dog food here and when robust, include in the release - we should make that a standard going forward and have a robust process for it, so we are rigourous with the application of the process. 1-2 weeks is arbritrarty and too long. What are the concrete signals that will tell us when it's ready to be included in the published packages?"* and *"Definitly risk-scorer related - basically, we would ask 'what is the release risk (along with all the other queued changes) if we added it to the release now?' But we need to think about when is the right time to ask. Also, we need to consider the value in releasing. We should do a counterfactual risk assessment - 'what is the risk of delaying the release of this longer?' i.e. what are the risks users are facing without this new feature"*.

## Description

ADR-042 Rule 2 establishes the move-to-holding remediation: when cumulative pipeline residual exceeds appetite (≥ 5/25), the orchestrator can `git mv` a changeset from `.changeset/` to `docs/changesets-holding/` to drop release risk while preserving the underlying fix commit. The mechanism works — three changesets currently held (`wr-itil-p085-assistant-output-gate.md`, `wr-risk-scorer-p064-external-comms-gate.md`, `wr-retrospective-p159-readme-jtbd-currency-hook.md`), all load-bearing-from-the-start hook surfaces awaiting in-repo dogfood evidence before user-facing release.

What's missing: **the reinstate-side contract**. The README's "Currently held" entries each name a vague "reinstate trigger" — typically "user signals comfort with hook behaviour OR scorer downgrades residual below appetite after dogfood observation". This is unmeasurable in practice:

1. **"User signals comfort"** is human-judgment with no observable evidence shape. The user has no way to know when the dogfood window is sufficient — they'd be guessing. Calendar-time windows (e.g. "hold 7-14 days") were explicitly rejected by the user as *"arbitrary and too long"*.

2. **"Scorer downgrades residual below appetite"** is closer, but the current scorer doesn't have any input that would change its mind. It scores the SAME pipeline state every time — held changesets stay held forever unless something else changes the residual.

The user's direction reframes the graduation question as a **symmetric risk balance** rather than a one-sided release-risk threshold:

- **Release risk** (current): "what is the risk of shipping the held changeset to npm now?" — the existing scorer dimension. Driven by load-bearing surfaces, bats coverage, blast radius, prior incidents.
- **Delay risk** (proposed addition): "what is the risk of NOT shipping this fix to users right now?" — currently zero in the model, which is wrong. Real delay risk includes: users hitting the bug the fix would prevent, users hitting the gap the new gate would catch, accumulation of dependent work that wants the fix, reputation drift if announced fixes lag actual ship.

The reinstate-criterion becomes: **"reinstate when delay-risk ≥ release-risk"** — the same balance ADR-042 applies on the release-side, applied symmetrically. As dogfood evidence accumulates (more commits without false-positive, more auto-fix invocations succeeding, no unrecovered errors), release-risk decays. As wall-clock proceeds without ship (more users hit the gap, more dependent work piles up), delay-risk accrues. Eventually they cross. That's the graduation.

## Symptoms

- Three changesets held in `docs/changesets-holding/` (P085 since 2026-04-24, P064 since 2026-04-26, P159 since 2026-05-04). No formalized exit criteria for any of them. P085 + P064 are 8-10 days old with no visible reinstate progress despite presumably accumulated dogfood evidence in the contributor's local repo.
- The orchestrator's Step 6.5 risk scoring re-fires on every iter but doesn't read accumulated dogfood evidence — held changesets stay held with no progressive signal.
- The user must remember to manually reinstate by `git mv`'ing a changeset back to `.changeset/` and pushing — a step that has no clear trigger and no documented "this is the time" indicator.
- ADR-042's Rule 2 is monotonic in one direction (stuff-flows-to-holding-when-above-appetite) but has no codified flow back (stuff-leaves-holding-when-evidence-justifies). The vocabulary is open per Rule 2a; the reinstate vocabulary is empty.
- New "load-bearing-from-the-start" surfaces (this loop's P159 hook is the third such pattern after P085 and P064) will keep accumulating in holding without a graduation contract — by month 6, the holding directory may have N entries with no clear reinstate path.

## Workaround

Manual reinstate via `git mv docs/changesets-holding/<name>.md .changeset/` + push. User must remember to do this; no agent reminder; no observable signal saying "now is the right time".

## Impact Assessment

- **Who is affected**: Plugin-developer persona (JTBD-101) authoring load-bearing surfaces — they pay the upfront move-to-holding cost expecting eventual release; without graduation, the surface stays effectively unreleased indefinitely. Plugin-user persona (JTBD-302) affected indirectly — features land in main but never reach npm where adopters consume them.
- **Frequency**: Every load-bearing-from-the-start surface (currently 3 known: P085 / P064 / P159). Each future drift-detector / commit-time hook / risk-leak gate is a candidate. Conservative forecast: 1-3 new holds per quarter.
- **Severity**: Significant (3) — features developed and dogfooded but not released = user-facing value is invisible. Not catastrophic (the fix exists in source, just not in published versions); not negligible (the entire point of the plugin model is publish-via-npm).
- **Likelihood**: Almost certain (4) — every load-bearing surface follows the move-to-holding pattern (verified by ADR-042 Rule 2 application across 3 distinct surfaces); without graduation criteria, every one will accumulate.

## Root Cause Analysis

ADR-042 was authored to address P103 (orchestrator escalated resolved release decisions instead of auto-applying) and P104 (partial-progress painted release queue into a corner). Both root causes are about the **inflow** to holding — what should land in `.changeset/` vs `docs/changesets-holding/`. The ADR's Rule 7 blesses the holding location as the authoritative mechanism but does not pin **outflow** criteria. The Reassessment criterion explicitly mentions "above-appetite resolution" as the trigger but not below-threshold reinstate.

This is the inverse-failure-mode of the original problem: ADR-042 made the inflow decision tractable; the symmetric outflow decision was not yet load-bearing in 2026-04-23 because no surface had been held. Now three surfaces have been held over an 8-day window, the symmetric question is load-bearing, and the contract gap is visible.

The deeper observation (per the user's verbatim framing): **risk assessment in the project today is asymmetric**. We score the risk of doing-things (commit / push / release) but not the risk of NOT-doing-things (delay / defer / hold). This asymmetry is fine when defaults are "do" and the question is "should we hold?" — but inverts when defaults are "hold" and the question is "should we ship?". The graduation contract needs the symmetric counterfactual scoring because it asks the inverse question.

### Investigation Tasks

- [ ] Architect review on the proposed ADR shape — sibling ADR vs ADR-042 amendment; per-class graduation matrix; counterfactual delay-risk framework grounding.
- [ ] JTBD review on the persona-fit — JTBD-006 + JTBD-101 + JTBD-302 alignment.
- [ ] Phase 1 — Draft + land the new ADR.
- [ ] Phase 2 — Risk-scorer extension implementing counterfactual scoring (separate iter).
- [ ] Phase 3 — Retroactive application to P085 + P064 + P159 (separate iter).
- [ ] Phase 4 — docs/changesets-holding/README.md Process amendment (separate iter).

## Fix Strategy

**Phase 1 (next interactive iter)**: New ADR — `docs/decisions/<NNN>-dogfood-graduation-criteria.proposed.md`. Sibling to ADR-042. Codifies:

1. **The graduation question**: "is delay-risk ≥ release-risk for this held changeset?"
2. **Release-risk computation**: existing ADR-042 Rule 2 / RISK-POLICY.md scoring against current pipeline state with the held changeset hypothetically reinstated.
3. **Delay-risk computation** (new dimension): scoring against the cost to users of NOT releasing. Concrete inputs:
   - Days held (calendar-time floor; not the threshold itself, but accumulates risk).
   - Adopter-side gap citations (issues / discussions / mentions in upstream issues referring to "feature X not yet shipped" — driver for `/wr-itil:report-upstream` integration).
   - Dependent-work-stack: count of subsequent tickets / commits whose value is reduced or blocked by the held surface staying held. Composes with P076 transitive-dependency rule.
   - Accumulated dogfood evidence: false-positive count (lower is better — evidence the gate works); successful-fire count (more is better — evidence the gate has been exercised); unrecovered-error count (zero is required — gate cannot regress).
4. **The reinstate trigger**: "release-risk ≤ delay-risk" → orchestrator's Step 6.5 emits a `RISK_REMEDIATIONS:` entry with `reinstate-from-holding` action class (open-vocabulary per ADR-042 Rule 2a). Agent reads + applies.
5. **When to ask**: Step 6.5 evaluates graduation only when (a) the held changeset's hold-age ≥ baseline floor (e.g. ≥ 7 firings of the gate without false-positive — observable evidence, not calendar) AND (b) the orchestrator is in within-appetite drain mode (i.e. would drain anyway). Avoids running graduation queries every iter when nothing else is shipping.
6. **Per-class graduation matrices**: PreToolUse:Bash gates / UserPromptSubmit detectors / commit-hook-with-auto-fix surfaces / SessionStart additionalContext hooks each have different baseline evidence requirements. The ADR pins the matrix; risk-scorer reads class-tagged evidence.

**Phase 2 (separate iter)**: Risk-scorer extension implementing the counterfactual scoring path. Reads `.afk-run-state/dogfood-evidence.jsonl` (new evidence-collection artifact written by the held hook itself on every fire), composes with adopter-side gap signal (gh issues mentioning the held feature), emits `reinstate-from-holding` remediation when graduation is satisfied. Behavioural bats covering: (a) graduation-not-satisfied → no remediation; (b) graduation-satisfied → remediation emitted; (c) class-specific thresholds enforced; (d) counterfactual delay-risk monotonically increases with hold-age.

**Phase 3 (separate iter)**: Retroactive application to P085 + P064 — gather dogfood evidence from session transcripts + commit history for both held changesets; emit graduation verdict; reinstate or document why hold continues. Establishes graduation-criteria baseline by exercising it on real surfaces. Closes the open question of "are P085 and P064 ready to ship now?"

**Phase 4 (eventual)**: Amendment to `docs/changesets-holding/README.md` "Process" section adding the graduation flow as an explicit step. Move-to-holding stays open-ended; graduation becomes documented and observable.

## Dependencies

- **Blocks**: (none — until graduation criteria exist, P085 / P064 / P159 stay held with no clear reinstate path; future load-bearing surfaces will accumulate. No direct ticket-level block, but the value of move-to-holding is reduced without the symmetric exit.)
- **Blocked by**: (none — Phase 1 ADR is self-contained; risk-scorer extension in Phase 2 composes with existing scorer surface, not blocked by any other ticket.)
- **Composes with**: P076 (WSJF transitive-dependency rule — delay-risk should account for dependent work), P033 (risk register — delay-risk is itself a standing-risk class for adopters; composes with R005 + the risk-register surface), P085 (held changeset — first instance of pattern this ticket codifies), P064 (held changeset — second instance), P159 (held changeset — third instance, drove this ticket's surfacing)

## Related

- **ADR-042** (`docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — parent decision; this ticket is the symmetric outflow contract.
- **`docs/changesets-holding/`** — three currently-held changesets (P085 / P064 / P159) all need graduation criteria.
- **P085** (`docs/problems/085-assistant-asks-when-obvious-and-uses-prose-instead-of-askuserquestion.verifying.md`) — held since 2026-04-24; first instance of the load-bearing-from-the-start hold pattern.
- **P064** (`docs/problems/064-no-risk-scoring-gate-on-external-comms.verifying.md`) — held since 2026-04-26; second instance.
- **P159** (`docs/problems/159-jtbd-currency-detector-should-be-load-bearing-commit-hook-with-auto-fix-not-retro-advisory.verifying.md`) — held 2026-05-04 (this loop); third instance, drove this ticket's surfacing.
- **R005** (`docs/risks/R005-readme-skill-md-prose-drifts-from-runtime-behaviour.active.md`) — standing risk register entry; delay-risk concept this ticket introduces aligns conceptually with the standing-risk surface.
- **ADR-026** (evidence-grounded scoring — counterfactual delay-risk needs to ground in observable evidence, not speculation).
- **ADR-013 Rule 5** (policy-authorised silent-action — graduation-driven reinstate is policy-authorised once criteria are met; no per-reinstate AskUserQuestion needed).
- **JTBD-006** (Progress the Backlog While I'm Away) — orchestrator should auto-graduate held changesets without user intervention when criteria are met.
- **JTBD-101** (Extend the Suite with New Plugins) — plugin-developer pays move-to-holding cost expecting graduation; without criteria the cost has unclear payoff.
- **JTBD-302** (Trust README describes installed behaviour) — plugin-user persona indirectly affected; held features don't reach adopters until graduation.

## Change Log

- **2026-05-04** — Opened by `/wr-itil:manage-problem` invocation from orchestrator's main turn at end of `/wr-itil:work-problems` AFK loop iter 7 surfacing pass. Skeleton ticket — chosen signal shape (risk-scorer-driven counterfactual) + chosen home (new ADR) + Investigation Tasks deferred to architect/JTBD review at next interactive session. Initial duplicate-check: no existing tickets cover graduation criteria (P103/P104 are inflow-side, closed). Captured via manage-problem (P119) instead of capture-problem because the just-shipped capture-problem skill (P155 commit 86e99e5, released as @windyroad/itil@0.25.0) is not yet in the local plugin cache mid-session — sibling-finding flagged in iter 4 outstanding_questions.
