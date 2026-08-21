# Problem 459: Agent-Prose Behavioural Eval Flaky — Red-Lines CI on Unrelated Commits

**Status**: Known Error
**Reported**: 2026-07-24
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture; de-flaking an LLM-rubric eval (pin judge model / raise determinism / add per-case retry / harden the rubric) is a design-bearing change to the eval harness
**WSJF**: 8 — (8 × 2.0) / 2 (added 2026-07-26 review)
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

## Fix Applied 2026-07-25

Root cause verified: `packages/risk-scorer/agents/eval/run-agent-eval.sh` ran the agent as a single-shot non-deterministic `claude -p`; the plan/wip/pipeline/external-comms cases assert a deterministic `icontains` of the contract verdict token (`RISK_VERDICT:` / `RISK_SCORES:` / `EXTERNAL_COMMS_RISK_VERDICT:`). When a generation omitted the exact token, the case failed and red-lined the whole Agent-Prose Evals job (~50% of pushes, incl. a version-packages merge touching no agent code).

**Fix**: bounded retry in the driver — map AGENT→its contract token, generate up to 3× until the token PREFIX appears, then emit. Absorbs transient token-omission WITHOUT masking regressions: never-emits still fails after 3 tries; a WRONG-value verdict has the prefix present so no retry fires and the assertion still grades/fails (the load-bearing masking-avoidance invariant). No changeset — eval artefacts are tarball-excluded (`!agents/eval/`, `!agents/test/`), CI-only; takes effect on the next CI run. Behavioural bats `packages/risk-scorer/agents/test/run-agent-eval-retry.bats` (3/3 — recover / hard-fail-preserved / wrong-value-no-retry) per ADR-005. Architect PASS (with the required bats).

**Verify**: the next several pushes should show the Agent-Prose Behavioural Evals job green consistently (no PASS/FAIL flip on unrelated commits).

## Correction 2026-07-25 — first fix was PARTIAL; primary flake is verdict-VALUE variance

The CI run on the token-retry fix (02901e65) STILL failed the same Agent-Prose Evals job (7/8). Precise diagnosis: the dominant flake is verdict-VALUE variance, not token omission — e.g. the plan case "residual 5/25 + projected release 6/25, threshold 5" should emit `RISK_VERDICT: FAIL` (6 > 5 exceeds appetite) but the agent non-deterministically emits PASS. The bounded token-PREFIX retry (shipped, kept as a real partial improvement for the omission sub-flake + guarded by run-agent-eval-retry.bats) does NOT address value variance — the prefix is present either way.

**Refined fix strategy** (proper fix, not yet done): one of — (a) ADR-075 §5 pass^k / N-sample majority so a single boundary flip does not fail the job; (b) disambiguate the boundary fixtures (move off the exactly-at/just-over-threshold edge where the LLM flips); (c) harden the plan/pipeline agents boundary-appetite reasoning (explicit "> threshold exceeds; ≤ threshold within"). (a) is the ADR-075-documented mechanism and the most robust.

**Process note**: I had wrongly attributed ALL this session`s CI red to P459; verifying the actual failed job revealed my own P151 lint also false-positived (fixed same commit). The exact P461 / P434 verify-before-asserting lesson.

## Phase 2 — third mechanism: a fail-closed assertion that cannot tell emitting from naming (added 2026-08-21)

A third, distinct sub-mechanism of the same symptom, found during the
2026-08-21 release drain. It is not token-omission (Fix Applied 2026-07-25) and
not verdict-value variance (Correction 2026-07-25) — it is a **latently broken
assertion** that any sampling variance is enough to trip.

`packages/risk-scorer/agents/eval/promptfooconfig.yaml` line 279, in the case
`Codex pipeline fails closed when the assessed root is absent`:

```yaml
    assert:
      - type: not-contains
        value: 'RISK_SCORES:'
      - type: icontains
        value: 'RISK_CWD'
```

The case exists to prove the agent **refuses to score** when the assessed root
is missing. But `not-contains` is a substring test over the whole response, so
it cannot distinguish the two things it needs to tell apart:

- the agent **emitting** a verdict it should have withheld — a real failure; and
- the agent **naming** the token inside a correct refusal — "I must not emit
  `RISK_SCORES:` because the assessed root is absent" — which is the *desired*
  behaviour and passes the intent of the test while failing its letter.

Whether a given generation phrases its refusal with or without the literal
token is a sampling coin-flip. So the case fails intermittently on commits that
touch nothing near it, and passes on re-run.

**Observed 2026-08-21**: this case reddened CI on an otherwise-green commit
during the release drain, then passed on re-run with no change to the diff.

**Why it matters beyond the wasted triage**: this is the failure mode named in
this ticket's own Impact Assessment — "trains maintainers to ignore CI red". A
red that greens on re-run with no code change is indistinguishable, from the
outside, from the flake classes already fixed here. It will keep recurring, and
each recurrence makes the next real failure easier to wave through.

**Fix direction**: assert on the refusal's *shape*, not on the absence of a
substring — e.g. require the fail-closed sentinel the agent is contracted to
emit, and use a `not-regex` anchored to the token in **emitting** position
(start-of-line followed by a score payload, as the sibling case at line 273
already does with `not-regex` for the duplicate-`RISK_CWD` check) rather than a
bare `not-contains` over free prose. The sibling case two blocks up is the
worked example: it uses `not-regex` precisely because a bare substring test was
not precise enough there either.

### Phase 2 Investigation Tasks

- [ ] Replace the line 279 `not-contains: 'RISK_SCORES:'` with an assertion that
      matches the token only in emitting position, so a refusal that names the
      token passes.
- [ ] Add the positive half: assert the refusal actually carries the fail-closed
      sentinel the agent is contracted to emit, so the case proves refusal
      rather than merely proving absence.
- [ ] Sweep the rest of `promptfooconfig.yaml` for other bare `not-contains`
      assertions over contract tokens — the same emitting-vs-naming ambiguity
      applies wherever a negative assertion tests a token the agent may
      legitimately discuss.
- [ ] Re-check whether this mechanism, rather than value variance, accounts for
      some of the flakes previously attributed to the Correction 2026-07-25
      diagnosis.

**Hang-off rationale**: captured against this ticket rather than as a sibling
per the inflow-discipline rule — same eval config, same CI job, same observable
symptom (a red that greens on re-run), and the same remedy surface. A separate
ticket would split one flake-class investigation across two files.
