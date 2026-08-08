# Problem 486: Retro Detectors Exit 2 on an Absent Default Directory, So Enforcement Fails Open in Adopter Repos

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 16 (High) — Impact: 4 (Significant — installed plugins degrade developer workflow; a documented run-retro enforcement pass does not execute in an adopter install) × Likelihood: 4 (Likely — holds in every adopter repo lacking the default directory; three downstream hits in one night, reproduced here) — derived at capture per Step 4a
**Origin**: inbound
**Effort**: M — the one-line guard per script is S, but the absent-target-directory convention spans a nine-script family and the approach-choice is not covered by any in-force ADR, so a ratified ADR precedes implementation per ADR-073's Confirmation clause
**JTBD**: (unconfirmed — elicitation queued)
**Persona**: plugin-user

## Description

Four `wr-retrospective` advisory detector scripts exit 2 (`dir not found`) when their **default** target directory is absent, which is the normal state of an adopter repo — a consumer project that installs `@windyroad/retrospective` but has no `packages/` monorepo tree, and may not yet have `docs/retros/` or `docs/briefing/`.

Reproduced in a temporary adopter-shaped repo (no `packages/`, no `docs/retros/`, no `docs/briefing/`), invoking each script with no arguments:

```
check-readme-jtbd-currency     exit=2  packages dir not found: packages
check-briefing-budgets         exit=2  briefing dir not found: docs/briefing
check-ask-hygiene              exit=2  retros dir not found: docs/retros
check-tickets-deferred-cause   exit=2  retros dir not found: docs/retros
```

The default path is the one adopters exercise: `run-retro` SKILL.md invokes the shims bare, with no directory argument.

The consequence is that a retro enforcement surface **fails open** in every adopter repo. The ADR-040 Tier 3 briefing budget is unenforced rather than satisfied, and the adopting maintainer sees silence that reads as a pass.

The inconsistency is visible inside a single script: `check-readme-jtbd-currency.sh` already exits 0 silently when `packages/` exists but contains zero package directories. Zero packages because the directory is *absent* is the same "nothing in scope" condition, but it exits 2 instead.

### What was verified, and what turned out to be stale

The originating report also claimed the scripts are not on `$PATH` at all in an adopter install. **That half is already fixed** and should not be re-worked:

- `packages/retrospective/bin/` contains ADR-080-template shims for all four scripts, landed in commit `4a7d695b` (2026-07-25), on `main`.
- `npm pack @windyroad/retrospective@0.27.1` confirms all four shims ship in the published tarball.
- The downstream "not on `$PATH`" observation was made against 0.27.0, before that commit.

**Residual**: `packages/retrospective/skills/run-retro/SKILL.md` lines 500 and 604 still name `packages/retrospective/scripts/check-tickets-deferred-cause.sh` repo-relative rather than the `wr-retrospective-check-tickets-deferred-cause` shim, unlike the other three which were reworded. Line 500 sits inside Step 4b's normative prose, where an agent reads it as an invocation step. That path does not resolve in an adopter tree.

### Approach options (none yet ratified)

Architect review found the absent-target-directory semantics is an approach-choice no in-force ADR covers, and that the same `2 = parse error (dir missing or unreadable)` contract is shared by at least nine sibling scripts — so changing four of them creates two contradictory contracts inside one family unless the rule is recorded.

- **A** — explicit-arg absent dir → exit 2 (preserves typo detection); default absent dir → exit 0, silent.
- **B** — absent dir → exit 0 silently, always. One rule for the family; loses the typo signal.
- **C** — exit 0 plus a distinguishable stdout sentinel (e.g. `NOT_APPLICABLE dir=docs/retros reason=absent`), following the `measure-context-budget.sh` `not-measured reason=<reason>` precedent. Verified inert against the only enforcement consumer, which greps `^TOTAL packages=` and `^README package=`.
- **D** — leave the exit codes; fix the consumer. `run-retro` Step 2b already documents this fail-open branch; Steps 2d, 3 and 4b have no equivalent.

Architect lean: C, or A composed with C — C is the only option that unblocks the adopter without converting a loud failure into indistinguishable silence, which is the specific harm this ticket reports.

## Symptoms

- Every `run-retro` pass that reaches the Step 2b README currency advisory, the Step 2d.8 R6 ask-hygiene gate, the Step 3 Tier 3 briefing budget pass, or the Step 4b Stage 1 tickets-deferred check, in an adopter repo missing the corresponding default directory.
- The maintainer sees no output and reads it as a pass.

## Workaround

Pass the directory explicitly where it exists, or create the directory before the retro. Neither helps the `packages/` case in a non-monorepo adopter.

## Impact Assessment

- **Who is affected**: adopters installing `@windyroad/retrospective` into a repo that is not the source monorepo.
- **Frequency**: every retro in an affected repo.
- **Severity**: governance signal silently lost; no data loss.
- **Analytics**: three downstream occurrences in a single night, plus a first-party reproduction.

## Root Cause Analysis

### Investigation Tasks

- [ ] Ratify the absent-target-directory convention for the detector-script family (options A-D above) per ADR-073's Confirmation clause
- [ ] Apply the ratified shape to the four scripts, and decide whether the other five siblings follow in the same change
- [ ] Reword `run-retro` SKILL.md lines 500 / 604 to the `wr-retrospective-check-tickets-deferred-cause` shim
- [ ] Rewrite the two existing bats tests that assert the current exit-2 default behaviour, keeping a live default-path assertion by other means
- [ ] Create reproduction tests

## Dependencies

- **Blocks**: (none)
- **Blocked by**: an ADR ratifying the absent-target-directory convention
- **Composes with**: P449, P435

## Related

Captured via `/wr-itil:capture-problem`.

Reported downstream as windyroad P130; partially tracked upstream as issue #362 (the shim half of which is already fixed — see Description).

Two existing bats tests assert the behaviour any fix here inverts, and are the current contract rather than an omission:
`packages/retrospective/scripts/test/check-tickets-deferred-cause.bats` (`default retros-dir argument is docs/retros (when omitted)`) and the same-shaped test in `check-ask-hygiene.bats`. Both use the exit-2 message as the only observable proof that the default path is what it claims, so an exit-0 change silently stops them testing anything. `check-briefing-budgets.bats` has a pattern worth copying — it populates a real directory in a temp cwd and asserts the output.

**Hang-off check**: the mechanical pre-filter returned more than five shared-signal candidates, so the `wr-itil:hang-off-check` dispatch was skipped per the capture-problem candidate-cap short-circuit. Re-evaluate absorption at the next `/wr-itil:review-problems`. The nearest same-class parents are:

- **P449** (`i13 rfc-trace gate not adopter-aware, fires in repos without rfc tier`) — same "gate not adopter-aware" class.
- **P435** (`risk-scorer gates hardcoded to home-repo shape`) — same class.
- **P412** (`rfc/story/story-map tiers invisible to adopters, no scaffold or nudge`) — adjacent adopter-shape gap.
- **P420** (`check-briefing-budgets crashes on empty array under bash 3.2`) — a different defect in one of the same four scripts; a fix touching these scripts should reconcile with it.

**Anchoring**: the persona is confidently `plugin-user` (the affected party is unambiguously the adopter). The JTBD is low-confidence — no existing job is a clean fit; `JTBD-302` (trust that the README describes the plugin just installed) is about README-to-version currency rather than a documented pass silently not executing. Captured under AFK with the unconfirmed-anchoring sentinel per P401 never-discard; the elicitation interview is queued for the next interactive session. Do not build dependent RFC/story/fix work until the anchoring is confirmed.
