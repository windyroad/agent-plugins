# Problem 459: Agent-Prose Behavioural Eval Flaky — Red-Lines CI on Unrelated Commits

**Status**: Open
**Reported**: 2026-07-24
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture; de-flaking an LLM-rubric eval (pin judge model / raise determinism / add per-case retry / harden the rubric) is a design-bearing change to the eval harness
**JTBD**: JTBD-001
**Persona**: developer

## Description

The `Agent-Prose Behavioural Evals` CI job (promptfoo, `packages/risk-scorer/agents/eval/`) fails intermittently on the `risk-scorer:plan` agent case, independent of the diff under test. Observed 2026-07-24 across four consecutive `main` commits: `a940639b` (cruise brake fix) CI **pass**; `ffaa5ada` (version-packages merge) CI **fail**; `9a806932` (cruise recs) CI **pass**; `6abb4ef1` (P458 gate exclusion) CI **fail**, and **fail again on re-run** — the same 1-of-8 `plan` rubric case (`## Plan Risk Report` LLM-rubric grade) flips PASS/FAIL run-to-run at roughly 50%. None of these commits touch the risk-scorer plan agent or its eval, so the failures are non-deterministic LLM-judge grading, not regressions.

The eval runner also emits `MetadataLookupWarning: received unexpected error = All promises were rejected code = UNKNOWN` repeatedly, suggesting the eval environment (judge model access / network / metadata service) is degraded, which likely amplifies the borderline-case flakiness.

## Symptoms

- `Results: ✓ 7 passed, ✗ 1 failed, 0 errors (87.50%)` on the `plan` agent; the failing row is a formatting-level rubric difference (`Residual risk: **5/25**` bold vs plain).
- CI red on ~half of `main` pushes regardless of what changed, forcing per-release investigation + re-runs.
- A legitimate, reviewed, low-risk release (cruise 0.4.7 + P458 gate patches) had to proceed with CI red because the failure was diagnosed as unrelated flakiness — eroding CI as a trustworthy release signal.

## Workaround

Confirm the failing case is the unrelated `risk-scorer:plan` rubric grade (not a real regression from the diff), then proceed with the release — publishing is not gated on this eval (the brake fix released as 0.4.6 despite `ffaa5ada` CI red). Re-running the failed job sometimes greens it.

## Impact Assessment

- **Who is affected**: maintainers releasing any package — every push risks a false red that demands triage
- **Frequency**: ~50% of `main` pushes (4-commit sample: 2 pass, 2 fail)
- **Severity**: Minor — does not block publish, but wastes triage time and trains maintainers to ignore CI red (dangerous — a real failure could hide behind the assumed-flaky one)
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

An LLM-rubric assertion on the `risk-scorer:plan` agent's prose is graded too strictly (brittle formatting sensitivity) and/or the judge model is non-deterministic without a pinned model + temperature, so a borderline case flips run-to-run. The `MetadataLookupWarning` network errors in the runner may degrade the judge and raise the flip rate.

### Investigation Tasks

- [ ] Identify the exact failing `plan` rubric assertion in `packages/risk-scorer/agents/eval/promptfooconfig.yaml`
- [ ] Determine whether the judge model/temperature is pinned; pin for determinism if not
- [ ] Decide de-flake strategy: loosen the brittle rubric wording, add per-case retry/best-of-N, or gate CI on a pass-threshold rather than 100%
- [ ] Investigate the `MetadataLookupWarning: All promises were rejected` runner errors (eval-env network/metadata degradation)
- [ ] Create a reproduction (run the single `plan` case N times, measure flip rate)

## Dependencies

- **Blocks**: (none — publishing is not gated on this eval)
- **Blocked by**: (none)
- **Composes with**: P324 (agent-prose verdicts lack a behavioural harness), P290 (harden ADR-052 behavioural-only) — same agent-prose-eval surface, different failure mode

## Related

- P324, P290, P012 — agent-prose / skill-eval harness tickets (this is the CI-flakiness failure mode, distinct from the verdict-pattern concern).

(captured via /wr-itil:capture-problem; expand at next investigation)
