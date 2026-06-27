# Problem 393: run-retro promptfoo eval — Step 4b Stage 2 fix-strategy case is mis-calibrated (6 brittle Tier-A regexes), blocks suite green

**Status**: Open
**Reported**: 2026-06-27
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
- [ ] Identify exactly which of the 6 Tier-A regexes false-fails the correct answer (`promptfoo view` or `--output json`)
- [ ] Demote the brittle multi-part Tier-A regexes to a single Tier-B `llm-rubric` (per P270); keep Tier-A only for distinctive anchors (e.g. `## Fix Strategy`, the shape-name tokens)
- [ ] Re-run `npx promptfoo eval` to 7/7 GREEN (≥2 consecutive)
- [ ] Then reinstate the held P372 changeset (`docs/changesets-holding/`) → release

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
