# Problem 388: capture-problem promptfoo eval — P350 derive-ratify brief-before-ID case is red, blocking the P199/P350/P383 cohort from green

**Status**: Known Error
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

**Confirmed (2026-06-27) — flaky multi-part/semantic Tier-A regexes, NOT a stable red and NOT a SKILL defect (the P393 sibling pattern exactly).** Re-running the suite 3× surfaced a *different* case red each run (run 1: the P350 brief-before-ID case; run 2: 2 cases; run 3: the Step 2b hang-off-check case on the compound `ADR-032|5th invocation|fresh-context-subagent` token). The model answered every case behaviourally-correctly — it just phrased the substance outside the brittle alternation ~1-in-3 (e.g. "fresh-context isolation" instead of the compound `fresh-context-subagent` token; "documented as ADR-032's pattern" missing the literal). Per P(all green) ≈ (2/3)^N across N flaky cases, the suite was rarely fully green by chance. Same class as P270 / P393 — over-brittle positive Tier-A on free-form prose — but here it is PURELY a calibration issue: unlike P393, no genuine capture-problem SKILL self-contradiction was found (the SKILL prose is correct; the eval mis-read it).

## Fix Implemented (2026-06-27)

Calibrated 6 cases per the P270/P393 pattern: demoted the paraphrasable semantic Tier-A alternations to the already-comprehensive Tier-B `llm-rubric` in each case, keeping Tier-A ONLY for distinctive paraphrase-proof anchors — file paths (`docs/problems/README.md`, `docs/jtbd`), command/subagent names (`wr-itil:hang-off-check`, `/wr-itil:review-problems`), citation/classification/verdict tokens (`ADR-014`, `ADR-074`, `ADR-044`/`category 4`, `JTBD-007`, `HANG_OFF`, `PROCEED_NEW`), and structural format lines (`Impact: [1-5]`, `Likelihood: [1-5]`, `(S|M|L|XL)` — P375 case left intact, those are paraphrase-proof). The Tier-B rubric was already authoritative for every demoted clause. Also appended the drafted P383 `--persona` adopter-corpus case (calibrated to its `docs/jtbd` anchor). Suite went **3× consecutive 8/8 GREEN**. Tarball-excluded test-infra (`skills/*/eval/` per packages/itil/.npmignore) — no `.changeset/` entry.

### Investigation Tasks

- [x] Re-run the eval 2-3× to rule out grader non-determinism — **flake confirmed**: a different case failed each run (P350, then 2 cases, then Step 2b), all behaviourally-correct outputs.
- [x] Inspect the brittle Tier-A; re-scope per the P270 fix pattern — demoted semantic alternations to Tier-B across 6 cases; Tier-A keeps distinctive anchors only.
- [x] Confirm 8/8 GREEN (incl. the committed P383 case) — 3× consecutive 8/8 GREEN.
- [x] Eval-floor evidence recorded + graduation queued for the entries whose SOLE reinstate criterion is "capture-problem eval GREEN" — **only `wr-itil-p199` + `p383`** (both solo Rule 3a, exact-surface match). The P350 4-changeset cohort (8 surfaces across 4 packages) and P352 (5 surfaces) are NOT discharged by capture-problem alone — their other surfaces' evals remain uncovered, so they stay held. Per P308 (holding-README line 24) AFK records evidence-met + queues the Rule 4 Graduate/Defer/Reject decision; it does NOT auto-graduate (the P270 precedent). Queued to `.afk-run-state/outstanding-questions.jsonl`.

## Dependencies

- **Blocks**: graduation of the capture-problem held cohort (P199, P350, P383)
- **Blocked by**: (none)
- **Composes with**: P012 / RFC-012 (skill-eval harness), P270 (llm-rubric mis-calibration class), P383 / P199 / P350 (the held cohort this unblocks)

## Related

- `packages/itil/skills/capture-problem/eval/promptfooconfig.yaml` — the suite; the failing case is the "brief-before-ID — option labels inline JTBD substance" one.
- **P270** — prior llm-rubric mis-calibration (0/4 → green after rubric re-scope); the fix pattern to mirror.
- **P383** (`docs/problems/verifying/...` no — `docs/problems/known-error/383-...`) — its `--persona` case is committed + green; cohort graduation waits on this ticket.
- Surfaced 2026-06-27 during the work-problems eval-cohort authoring pivot (user direction "author the eval cohort").
