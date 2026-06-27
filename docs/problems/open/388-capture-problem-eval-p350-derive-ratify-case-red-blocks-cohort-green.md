# Problem 388: capture-problem promptfoo eval — P350 derive-ratify brief-before-ID case is red, blocking the P199/P350/P383 cohort from green

**Status**: Open
**Reported**: 2026-06-27
**Priority**: 6 (Medium) — Impact: 2 x Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

The `packages/itil/skills/capture-problem/eval/promptfooconfig.yaml` suite runs **7/8 GREEN** as of 2026-06-27 — one case fails: *"Step 1.5b brief-before-ID — option labels inline JTBD substance BEFORE the JTBD-NNN ID"* (the P350 derive-then-ratify label-format case). Because the held changesets `wr-itil-p199-kill-deferred-readme-refresh.md`, the P350 brief-before-ID cohort, and `p383-persona-adopter-corpus-and-jtbd-m-resolution.md` all carry a reinstate criterion of *"the capture-problem eval goes GREEN"*, this single red case blocks the whole capture-problem cohort from graduating out of `docs/changesets-holding/`.

A P383 `--persona` adopter-corpus case was drafted and **verified PASSING** this session (the suite ran 7/8 with only the P350 case red). It was NOT committed — committing into a red suite would need its own changeset/release cycle for no green gain. The drafted case (reproduced below) should be added in the same pass that calibrates the P350 case to green, so the suite reaches 8/8 in one go.

### Drafted P383 `--persona` eval case (verified passing, append to `capture-problem/eval/promptfooconfig.yaml`)

```yaml
  - description: Step 1.5b --persona accepts a valid adopter-corpus persona dir name; enum is fallback only
    vars:
      prompt: |
        I am invoking /wr-itil:capture-problem in an ADOPTER repo whose
        persona corpus is docs/jtbd/{smb-owner,advisor,maintainer}/ (none
        of the plugin home-repo names). The caller passed
        `--persona=maintainer`, and docs/jtbd/maintainer/ exists on disk
        with a JTBD whose frontmatter names that persona. Is `maintainer`
        accepted or rejected, and what is the validation source of truth?
        When does the hardcoded home-repo enum apply?
    assert:
      - type: regex
        value: 'docs/jtbd|corpus|directory|dir(ectory)?\s+name|on[\s\-]?disk'
      - type: regex
        value: 'accept|valid|fallback|only\s+when\s+no'
      - type: llm-rubric
        value: |
          On a --persona value naming a real docs/jtbd/<persona>/ dir in an
          adopter repo, the response ACCEPTS it by validating against the
          adopter's docs/jtbd/*/ dir names, treating the hardcoded enum as a
          FALLBACK only when no docs/jtbd/*/ dirs exist. PASS if it accepts
          the on-disk adopter persona. FAIL if it rejects `maintainer` for
          not being in the enum. Saying it does NOT reject a valid on-disk
          persona PASSES.
```

## Symptoms

- `npx promptfoo eval -c packages/itil/skills/capture-problem/eval/promptfooconfig.yaml` → `7 passed, 1 failed`. The failing case is the P350 brief-before-ID label-format case.
- Model output for the failing case briefs substance then the ID (e.g. `Enforce governance gates automatically … — developer; JTBD-001`), which is arguably the correct brief-before-ID shape, yet the assertion fails — pointing at a **mis-calibrated Tier-B llm-rubric** (the P270 class — graders mis-scoring correct responses) rather than a genuine SKILL defect.

## Workaround

None — the cohort stays held until the case goes green.

## Impact Assessment

- **Who is affected**: the capture-problem held cohort (P199/P350/P383) cannot graduate/release; maintainer release cadence for those fixes.
- **Frequency**: every capture-problem cohort graduation attempt.
- **Severity**: holds 3 fixes' changelog attribution; no functional break (the fixes' code de-facto ships per P359).

## Root Cause Analysis

Likely a mis-calibrated Tier-B `llm-rubric` (same class as the P270 / P012-reopen 2026-06-04 finding — `not-regex` on negative clauses / grader strictness false-failing correct brief-before-ID outputs). Could also be a grader non-determinism flake. Needs a focused calibration pass.

### Investigation Tasks

- [ ] Re-run the eval 2-3× to rule out grader non-determinism (flake vs stable red)
- [ ] Inspect the P350 case's Tier-B llm-rubric; re-scope per the P270 fix pattern (positive Tier-A anchors + paraphrase-proof rubric; avoid not-regex on negated clauses)
- [ ] Confirm 8/8 GREEN (incl. the committed P383 case)
- [ ] Then graduate the capture-problem held cohort (P199 / P350 / P383) via interactive Step 6.5 Rule 4

## Dependencies

- **Blocks**: graduation of the capture-problem held cohort (P199, P350, P383)
- **Blocked by**: (none)
- **Composes with**: P012 / RFC-012 (skill-eval harness), P270 (llm-rubric mis-calibration class), P383 / P199 / P350 (the held cohort this unblocks)

## Related

- `packages/itil/skills/capture-problem/eval/promptfooconfig.yaml` — the suite; the failing case is the "brief-before-ID — option labels inline JTBD substance" one.
- **P270** — prior llm-rubric mis-calibration (0/4 → green after rubric re-scope); the fix pattern to mirror.
- **P383** (`docs/problems/verifying/...` no — `docs/problems/known-error/383-...`) — its `--persona` case is committed + green; cohort graduation waits on this ticket.
- Surfaced 2026-06-27 during the work-problems eval-cohort authoring pivot (user direction "author the eval cohort").
