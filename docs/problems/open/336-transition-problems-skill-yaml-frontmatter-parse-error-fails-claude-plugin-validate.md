# Problem 336: packages/itil/skills/transition-problems/SKILL.md frontmatter has YAML Parse error — `claude plugin validate packages/itil` fails on this file

**Status**: Open
**Reported**: 2026-05-30
**Priority**: 12 (High) — Impact: 3 (Moderate — `claude plugin validate packages/itil` hard-fails for adopters; npm publish path disrupted) × Likelihood: 4 (Likely — already hit on dogfood; persistent on `@windyroad/itil@0.39.0`)
**Origin**: internal
**Effort**: S (one-line frontmatter quoting fix; shipped session 9)
**WSJF**: 12.0 (re-rated 2026-05-31; fix shipped session 9, awaiting K→V transition on next `@windyroad/itil` release)
**Type**: technical

## Description

Surfaced 2026-05-30 by P263 iter 6 empirical probe. Running `claude plugin validate packages/itil` (Claude Code CLI 2.1.150) reports:

```
frontmatter: YAML frontmatter failed to parse: YAML Parse error: Unexpected token
```

Specifically against `packages/itil/skills/transition-problems/SKILL.md`. Blocks `validate`-clean state for `@windyroad/itil`. Once the P263 Phase 1 CI gate (non-strict `claude plugin validate` per plugin pre-publish) is shipped, this YAML error will fail CI with the wrong signal — the gate would report a real frontmatter defect, not a regression introduced by Phase 1.

Reporter: iter 6 of `/wr-itil:work-problems` session 9 (2026-05-30 work-problems AFK loop, dispatched by orchestrator after iter 5 deferred P082 on JTBD ratification).

## Symptoms

- `claude plugin validate packages/itil` exits non-zero with `frontmatter: YAML frontmatter failed to parse: YAML Parse error: Unexpected token`.
- Other SKILL.md frontmatters in `@windyroad/itil` parse clean — defect is scoped to `packages/itil/skills/transition-problems/SKILL.md`.

## Workaround

(deferred to investigation — likely an unescaped colon, multiline string, or special character in the frontmatter block)

## Impact Assessment

- **Who is affected**: maintainer + future P263 Phase 1 CI gate
- **Frequency**: every `claude plugin validate packages/itil` invocation (manual or CI)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Locate the exact malformed token in the SKILL.md frontmatter
- [ ] Repair frontmatter so `claude plugin validate packages/itil` exits 0
- [ ] Add a behavioural test (bats) that runs `claude plugin validate` on all `@windyroad/*` plugins and fails on parse errors — composes with P263 Phase 1 (the CI gate itself catches this class going forward; this ticket is the one-off cleanup)

## Dependencies

- **Blocks**: P263 Phase 1 CI gate (`claude plugin validate` per plugin pre-publish) — once Phase 1 lands, this YAML error fails CI on every push of `@windyroad/itil` until repaired.
- **Blocked by**: (none)
- **Composes with**: P263 (CI gate provides ongoing protection against this class of defect once repaired)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **P263** — surfaced this defect during iter 6 empirical probe; P263 Phase 1 CI gate would catch similar future regressions.
