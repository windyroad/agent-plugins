# Problem 381: update-policy Step 6a SKILL prose lacks paired promptfoo Tier-A/B eval (R009 prose-surface floor)

**Status**: Verification Pending
**Reported**: 2026-06-26
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-001
**Persona**: developer

## Fix Released

Test-infra fix (commit `3b8b3608`) — `packages/risk-scorer/skills/update-policy/eval/promptfooconfig.yaml` authored covering the four Step 6a behaviours (appetite<5 trigger, P350 brief-before-ID register formatting, policy-row fallback, confirm-vs-revise options); **4/4 cases GREEN across 3 calibration runs**. Tarball-excluded via the `package.json` `files`-negation `"!skills/*/eval/"` (no npm artefact), so there is no post-release window — the fix is verifiable in-repo. Discharges the R009 prose-surface floor for this SKILL per ADR-075 + RFC-012.

**Awaiting user verification** — run `npx promptfoo eval` in `packages/risk-scorer/skills/update-policy/eval/` and confirm 4/4 cases GREEN.

## Description

ADR-086 (band rebalance + default appetite 4→5) landed a new Step 6a in `/wr-risk-scorer:update-policy` SKILL.md — an interactive `AskUserQuestion` confirm-with-warning that fires when the user picks appetite < 5, scans `docs/risks/R*.active.md` for Impact=5 entries, and cites them by activity-class-first per P350 brief-before-ID discipline.

The new prose lands without a paired promptfoo Tier-A/B eval. The risk-scorer pipeline flagged the gap during ADR-086 release scoring (commit `5c90fdf8`) with a structured remediation:

> Add paired promptfoo Tier-A/B eval for update-policy SKILL Step 6a interactive warning at `packages/risk-scorer/skills/update-policy/eval/promptfooconfig.yaml` covering appetite<5 trigger, register-derived example formatting (P350 brief-before-ID), policy-row fallback when register empty, and confirm-vs-revise option semantics; would discharge R009 prose-surface floor per ADR-075 + RFC-012.

The R009 prose-surface floor (per ADR-075 + RFC-012) sits at residual 9/25 for SKILL.md prose without paired behavioural eval. The Step 6a addition is narrow but load-bearing — if the prose mis-cites the register, fires when it shouldn't, or fails to fire when it should, the precise hole ADR-086 is closing reopens silently. The bats coverage of the gate code (`risk-gate.bats`, 29/29 green) catches the structural-behaviour layer but NOT the SKILL prose execution surface.

The remediation has a known shape — first reference slice is `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` per the ADR-075 / RFC-012 pattern. The Step 6a eval would cover:

1. **Appetite<5 trigger** — verify the second `AskUserQuestion` fires when user selects appetite < 5 in step 6 first call; verify it does NOT fire when user selects appetite ≥ 5.
2. **Register-derived example formatting** — verify the warning cites Impact=5 entries by activity-class-first per P350 (e.g. `credentials-in-committed-files (R008)`, not bare `R008`).
3. **Policy-row fallback** — verify the warning falls back to the Impact=5 row from the policy's own Impact Levels table when `docs/risks/` is empty or has no Impact=5 entries.
4. **Confirm-vs-revise option semantics** — verify the option labels are clear and the revise path returns to step 6.

This is a Tier-A/B eval (deterministic assertions where possible — `icontains` / `contains` / `regex` for the cited text shape; `llm-rubric` pass^k for the prose-quality judgement).

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

**Root cause**: ADR-086 landed Step 6a (the tight-appetite confirm-with-warning) as new SKILL prose without a paired behavioural eval, because no eval harness existed under `packages/risk-scorer/skills/` — update-policy had zero prior evals. The R009 prose-surface floor therefore held un-discharged for this surface.

**Resolution** (commit `3b8b3608`, 2026-06-28): authored `packages/risk-scorer/skills/update-policy/eval/promptfooconfig.yaml` modelled on the `capture-problem` Tier-A/B reference shape, with the generic `run-skill-eval.sh` runner (copied from manage-problem) + `grade-llm-rubric.sh` grader (copied from capture-problem). Four test cases cover the four Step 6a behaviours (appetite<5 trigger, P350 activity-class-first register formatting, policy-row fallback, confirm-vs-revise options). Tier-A holds only paraphrase-proof anchors; all semantic/negative judgement routes to Tier-B llm-rubric (P270/P393 calibration). **3/3 calibration runs GREEN, 4/4 cases each** — no flakiness.

**Harness-scaffold finding (reusable)**: this was the FIRST eval under `packages/risk-scorer/skills/`. The tarball-exclusion mechanism that actually works in this repo's npm 10.9 + workspaces setup is the **`package.json` `files`-array negation `"!skills/*/eval/"`** — NOT the `.npmignore`. Empirically verified: adding `packages/risk-scorer/.npmignore` with `skills/*/eval/` did NOT exclude the eval from `npm pack`, and moving `packages/itil/.npmignore` aside did NOT make itil's eval start shipping (itil excludes via its own `files`-negation at `package.json` line 30). The `.npmignore` was kept for parity with itil + ADR-075 documentation, but it is inert for exclusion here. `npm pack --dry-run` from `packages/risk-scorer/` confirms no `skills/*/eval/` path ships while `SKILL.md` still ships. This trap is easy to miss — the architect gate itself initially mis-attributed the mechanism to the `.npmignore`.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — left to orchestrator/review-problems; Effort confirmed M (5 files, mechanical copy + 1 new config + mechanism discovery)
- [x] Author `packages/risk-scorer/skills/update-policy/eval/promptfooconfig.yaml` modelled on the reference slice (used `capture-problem` Tier-A/B shape rather than `manage-problem` — capture-problem is the canonical Tier-A-anchors + Tier-B-llm-rubric pattern post P270/P393 calibration)
- [x] Cover the four Step 6a behaviours enumerated above (trigger, formatting, fallback, options)
- [x] Verify locally with `npx promptfoo eval` against the SKILL via the `run-skill-eval.sh` exec provider wrapping `claude -p --append-system-prompt` — 3/3 runs GREEN
- [x] Discharge R009 prose-surface floor for the update-policy SKILL per ADR-075 amendment 2026-06-02 + RFC-012 — eval GREEN; the −1 prose-surface modulator is now claimable on the next risk assessment of `update-policy/SKILL.md` Step 6a prose
- [x] Cross-check: does the update-policy SKILL have ANY existing eval, or is this the first slice? — FIRST slice; harness scaffold (eval/ dir, config shape, exec provider wiring, `files`-negation tarball-exclusion) landed with this work
- [x] Create reproduction test (the eval IS the reproduction test in this case) — GREEN

**Verification**: the eval (reproduction + verification in one) is GREEN in-session across 3 runs. No release is required (eval is tarball-excluded test infra), so there is no post-release confirmation window — verification is satisfied by the in-session GREEN. Ready to close at the orchestrator's next verification pass / retro Step 4a.

## Dependencies

- **Blocks**: discharge of R009 prose-surface floor on update-policy SKILL (residual 9/25, above appetite 5)
- **Blocked by**: (none)
- **Composes with**: P324 (agent prose verdicts class), P290 (ADR-052 behavioural-only hardening)

## Related

- **ADR-086** (`docs/decisions/086-risk-label-bands-rebalanced-default-appetite-5.proposed.md`) — landed Step 6a; commit `5c90fdf8` flagged this as a follow-up.
- **ADR-075** — R009 control vocabulary amendment 2026-06-02 (SKILL.md prose-surface scope extension).
- **RFC-012** — promptfoo Tier-A/B SKILL-eval implementation.
- **R009** (`docs/risks/R009-functional-defects-in-shipped-behaviour.active.md`) — the standing-risk entry.
- **P290** (`docs/problems/open/290-harden-adr-052-to-behavioural-only-remove-structural-test-escape-hatch.md`) — sibling concern; ADR-052 hardening to behavioural-only.
- **P324** (`docs/problems/open/324-agent-prose-verdicts-have-no-behavioural-harness-forces-structural-escape-and-above-appetite-release.md`) — same R009 class; different surface (agent verdicts vs SKILL prose).
- **P012** (`docs/problems/open/012-skill-testing-harness.md`) — skill testing harness driver.
- `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` — first reference slice; model new SKILL evals on this shape.
- `packages/risk-scorer/skills/update-policy/SKILL.md` — Step 6a is the locus.
- **Step 2b hang-off-check** result: short-circuit fired (>5 broad candidates on `promptfoo` / `R009` / `update-policy` signals); subagent dispatch skipped per ADR-032 5th invocation pattern. P324 / P290 carry the closest semantic overlap (R009 prose-surface family); review-problems re-evaluation is the canonical absorb-vs-proceed surface.
- Captured via /wr-itil:capture-problem; expand at next investigation.
