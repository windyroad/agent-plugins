# Problem 393: run-retro promptfoo eval — Step 4b Stage 2 fix-strategy case is mis-calibrated (6 brittle Tier-A regexes), blocks suite green

**Status**: Verification Pending
**Reported**: 2026-06-27

## Fix Released

Released 2026-06-27 in `@windyroad/retrospective` (changeset `p393-run-retro-silent-delete-reconcile.md`). All 7 run-retro eval cases were recalibrated (brittle multi-part Tier-A regexes demoted to Tier-B `llm-rubric` per P270); the recalibrated Tier-B rubric also caught + reconciled a genuine Step 1.5 silent-delete self-contradiction in the SKILL prose (the delete queue is silent per ADR-044/P132, not a batched AskUserQuestion). Suite now 3× consecutive 7/7 GREEN. The stale structural test 2389 was repointed to the silent-delete contract (fix-and-continue, architect PASS). Discharging the run-retro R009 prose-floor unblocked + released P372.

**Awaiting user verification** — confirm `npx promptfoo eval` on the run-retro suite stays GREEN and the Step 1.5 silent-delete contract holds.
**Priority**: 6 (Medium) — Impact: 2 x Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The `packages/retrospective/skills/run-retro/eval/promptfooconfig.yaml` suite runs **6/7 GREEN** as of 2026-06-27. The failing case is *"Step 4b Stage 2 silent fix-strategy pick"* (config line ~604). The model's response is behaviourally CORRECT (it answers "No — Stage 2 does not fire AskUserQuestion per ticket; silent agent action; user corrects via direct edit") yet the case FAILs — because the case carries **6 brittle Tier-A `regex` assertions** (lines ~633-648) that ALL must match a free-form multi-part prose answer, and the correct answer doesn't hit one of the exact patterns. This is the P270 / P388 class (over-brittle Tier-A regexes false-failing correct prose).

Because the R009 prose-floor discharge for run-retro requires the WHOLE suite GREEN, this one mis-calibrated case blocks new run-retro SKILL-prose fixes from releasing — it already forced **P372** (the ADR-043 byte-floor trigger) to move-to-holding this session despite P372's own added eval case passing.

## Symptoms

- `npx promptfoo eval -c packages/retrospective/skills/run-retro/eval/promptfooconfig.yaml` → `6 passed, 1 failed`; the failing case is the Stage-2 fix-strategy case, on a behaviourally-correct response.
- Any run-retro SKILL-prose changeset (e.g. P372) cannot discharge its R009 prose-floor → held.

## Workaround

Move-to-holding the run-retro SKILL-prose changesets (P372 held this session) until the suite goes green.

## Impact Assessment

- **Who is affected**: maintainer release cadence for run-retro SKILL-prose fixes (P372 now held; future run-retro fixes will hold too).
- **Frequency**: every run-retro SKILL-prose changeset until the case is calibrated.
- **Severity**: holds releases; no functional break (the SKILL prose is correct; only the eval gate mis-reads).

## Root Cause Analysis

The Stage-2 case uses 6 positive Tier-A `regex` assertions on a free-form, multi-part prose answer (does-it-fire-AskUserQuestion + per-observation shape A/B/C + recovery-path + Fix-Strategy-record). A correct answer that phrases any one of those parts outside the regex's alternation fails the whole case. Per the P270 lesson (briefing `promptfoo-eval-authoring.md`): brittle multi-part Tier-A regexes on free-form prose should be demoted to a single Tier-B `llm-rubric` that checks the substance, keeping Tier-A only for distinctive, paraphrase-proof anchors.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Identify exactly which of the 6 Tier-A regexes false-fails the correct answer (`promptfoo view` or `--output json`) — **the suite is FLAKY, not deterministically red**: the Stage-2 case passed on first re-run. Root cause is intermittent, not a single fixed regex (2026-06-27).
- [x] Demote the brittle multi-part Tier-A regexes to a single Tier-B `llm-rubric` (per P270); keep Tier-A only for distinctive anchors — applied to the Stage-2 case AND, on widening the audit, **all 7 cases** (each carried 5 multi-part Tier-A regexes flaking ~1-in-3). See Fix Implemented.
- [x] Re-run `npx promptfoo eval` to 7/7 GREEN (≥2 consecutive) — **3 consecutive 7/7 GREEN** after both root-cause fixes (eval calibration + SKILL.md reconciliation).
- [ ] Reinstate the held P372 changeset (`docs/changesets-holding/`) → release — done in a paired graduation commit this iteration; release drains via the orchestrator.

## Fix Implemented (2026-06-27) — TWO root causes, scope-expanded

The investigation surfaced **two** independent causes of the intermittent suite redness, both of the P270 brittle-eval class but at different layers:

**Root cause 1 — over-brittle Tier-A regexes across the whole suite (the captured P393 scope, widened).** Every one of the 7 cases carried multi-part / negative-clause Tier-A `regex` assertions on free-form prose answers. Each flaked ~1-in-3 when the model's (behaviourally-correct) phrasing fell outside an alternation, so P(all 7 green) ≈ (2/3)^5 — the suite was rarely fully green by chance. Fix per P270 / briefing `promptfoo-eval-authoring.md`: demote the semantic/negative-clause regexes to the existing comprehensive Tier-B `llm-rubric` (which already asserts every substance dimension per case), keeping Tier-A only for distinctive, paraphrase-proof positive anchors (numeric thresholds, command names, citation/classification tokens — e.g. `## Fix Strategy`, `10240`, `/wr-itil:transition-problem`, `skill_unavailable`). Tarball-excluded test-infra (ADR-075 `!skills/*/eval/`), so no changeset.

**Root cause 2 — a genuine run-retro SKILL.md self-contradiction (discovered mid-fix; the residual flake after RC1).** The Step 1.5 `<= -3` delete prose contradicted itself: the threshold table + a "Delete queue confirmation" block said deletes fire a batched interactive `AskUserQuestion`, while Step 3's "Removals are silent (P135 / ADR-044)" clause, line 86's P352 AFK queue-and-continue amendment, CLAUDE.md MANDATORY P132 (worked-example list naming "run-retro Step 1.5 silent classification, Step 3 briefing removals"), and ADR-044's framework-resolution boundary (lists "Briefing add / remove / rotate" as a framework-mediated NOT-an-`AskUserQuestion` surface) all say deletes are silent. The model (reading SKILL.md as system prompt) followed the stale batched-confirm prose ~1-in-3 → the Step 1.5 eval case **correctly** failed it (Tier-B rubric, not Tier-A — the eval was working as designed). Fix: strike the stale batched-`AskUserQuestion` prose (SKILL.md lines 58, 71-82, 95); deletes are now silent in both modes, surfaced in the Step 5 Signal-vs-Noise Pass table, user corrects via P078 (reversible from git). Ships → `@windyroad/retrospective` **patch** changeset `.changeset/p393-run-retro-silent-delete-reconcile.md`. R009 prose-floor discharged by the now-GREEN paired eval.

Gates: architect ALIGNED (both edits; no new ADR — stale-prose reconciliation to ratified ADR-044) + JTBD PASS (JTBD-006; silent-delete-with-P078-correction respects the persona's control-via-visibility+reversibility) + external-comms PASS + voice-tone PASS on the changeset body.

## Fix Strategy

`Kind: improve` (Option 2 — Skill/test-infra improvement stub). RC1 is a test-infra calibration (eval config, tarball-excluded). RC2 is a bounded prose reconciliation to `packages/retrospective/skills/run-retro/SKILL.md` Step 1.5 — a targeted edit to an existing SKILL, no new concept. No new ADR; no new behavioural bats (the promptfoo eval IS the behavioural harness per ADR-052 — structural SKILL.md grep tests are disavowed).

**Release vehicle**: `.changeset/p393-run-retro-silent-delete-reconcile.md` (`@windyroad/retrospective` patch). K→V when the release drains.

## Dependencies

- **Blocks**: P372 release (held this session); any future run-retro SKILL-prose changeset release
- **Blocked by**: (none)
- **Composes with**: P388 (capture-problem eval P350 case mis-calibrated — identical class, different suite), P270 (llm-rubric mis-calibration class + the fix pattern), P324/RFC-012 (the eval-harness programme), P012 (skill-testing harness)

## Related

- `packages/retrospective/skills/run-retro/eval/promptfooconfig.yaml` — the suite; failing case ~line 604, brittle regexes ~633-648.
- **P388** — sibling (capture-problem eval P350 case mis-calibrated; same fix shape).
- **P270** — the llm-rubric mis-calibration class + the documented fix (route negative-clause/multi-part to Tier-B).
- **P372** (`docs/problems/known-error/372-...`) — held this session on this suite's red.
- Surfaced 2026-06-27 in the work-problems loop while discharging P372's R009 floor.
