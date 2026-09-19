# Problem 290: Harden ADR-052 to behavioural-only — remove the structural-test escape hatch entirely

**Status**: Open
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — the documented-justification escape hatch lets wasteful structural tests keep shipping; the user's standing position is that structural tests are "not real tests"; removing the hatch raises the whole suite's test quality and stops the `structural-justified` verdict being a permanent parking spot) × Likelihood: 3 (Likely — every test-author decision + the 28 existing escape-hatch-reliant test files)
**Origin**: internal
**Effort**: L — ADR-052 redesign (remove the escape hatches + the `structural-justified` verdict) + supersede ADR-005's Permitted Exception + P011 + convert/remove 28 existing structural test files + resolve the not-yet-behaviourally-expressible-test tension (Layer B harness primitives) — gated on P324 Layer B harness
**WSJF**: 9/4 = **2.25** (Open multiplier 1.0)

## Description

Surfaced during the P283/ADR-066 ADR-oversight drain (`/wr-architect:review-decisions` flow, 2026-05-25). When ADR-052 (Behavioural-tests-default for skill testing) was presented for human-oversight confirmation, the user declined to confirm it as-recorded and directed a hardening:

> User direction 2026-05-25 (drain): *"structural tests not permitted at all."*

ADR-052 currently chose **"Option 1 — behavioural-default with documented-justification escape hatches"**: structural tests are permitted when (a) the behavioural assertion isn't yet expressible under the framework AND (b) the author documents the harness gap with a linked ticket. The `review-test` agent emits a permitted `structural-justified` verdict, and two escape hatches exist (`WR_TDD_REVIEW_TEST=skip`; an in-file `tdd-review: structural-permitted (justification: …)` comment). The user wants the escape hatch **removed entirely** — behavioural is the ONLY permitted kind; structural tests are not allowed, period. This makes absolute the standing position behind P081 (structural tests are "wasteful and not real tests").

This is a **material amendment** to an extensively-built ADR (the whole `review-test` agent design is organised around the `structural-justified` classification + escape hatches), so it is its own unit of work. **ADR-052 is left unoversighted** (P283/ADR-066 marker withheld) until this rework lands and the hardened decision is re-confirmed — mirroring P287 (ADR-060) and P289 (solo-developer).

## Symptoms

(deferred to investigation)

- ADR-052 lines 51/63/69/125/142/184-185/201/220/227/257-259 (pre-amendment) encoded the escape-hatch / `structural-justified` / `structural-permitted` mechanism.
- **28 existing in-tree test files** rely on the structural-permitted exception. Verified 2026-06-09 via `grep -rl 'tdd-review: structural-permitted' packages/` (33 raw matches; subtract CHANGELOG.md × 2, SKILL.md × 1, `review-test.md` × 1, `tdd-review-test.sh` × 1 → 28 test files). Full Phase-2 conversion list below.
- **ADR-005** carries a structural-test "Permitted Exception" (P011) that the hardened ADR-052 supersedes — note: ADR-005 was human-confirmed in the same drain batch, but its Permitted Exception sub-clause is now superseded by this hardening; ADR-005's `human-oversight` clears to `unconfirmed` per the 2026-06-09 amendment.
- The `review-test` agent (`packages/tdd/agents/review-test.md`) emits `structural-justified` as a permitted verdict — Phase 2 makes this a failing (non-permitted) verdict; vocabulary collapses to BEHAVIOURAL / MIXED / STRUCTURAL / UNCLEAR.

## Workaround

None — the escape hatch is the current policy; this ticket changes the policy.

## Root Cause Analysis

### Investigation Tasks

**Phase 1 — Docs/policy (DONE 2026-06-09 in this iter):**

- [x] **Resolve the load-bearing design tension by direction**: Layer B harness primitives (P324 agent-prose-verdict harness, P176 skill-invocation harness, P012-descendants) are the prerequisite for behavioural alternatives. Tests that need those primitives BLOCK on the harness-gap ticket rather than ship as structural-with-justification. The ADR text states this; the in-tree contradiction window is tracked in this ticket body (NOT in the ADR — keeps the policy clean per the no-shortcuts/no-softening discipline).
- [x] Amend ADR-052: removed the documented-justification escape hatches + the `structural-justified` permitted verdict; behavioural-only. Frontmatter clears to `human-oversight: unconfirmed` + `oversight-date: 2026-06-09`.
- [x] Tighten ADR-005's Permitted-Exception sub-clause: removed the `tdd-review: structural-permitted` permission language from the "Excluded from this clause (per ADR-052)" sub-clause. ADR-005 frontmatter clears to `human-oversight: unconfirmed` + `oversight-date: 2026-06-09`.
- [x] Drop stale Surface-2 cross-reference in ADR-064 line 130 (mechanical cleanup; no marker clearance).
- [x] Regenerate `docs/decisions/README.md` compendium in the Phase 1 commit.

**Phase 2 — Source conversion (IN PROGRESS; agent-vocab slice landed 2026-06-27; architect + jtbd promptfoo twins landed 2026-06-27 via RFC-012 S1/S1-arch; first two structural retirements landed 2026-09-19):**

> **BLOCKER RESOLVED (2026-09-19 iter) — the 2026-07-04 finding no longer holds.** That finding said the bats retirement was gated on RFC-012 **S2** (Tier-A CI wiring) being unbuilt, so deleting the structural bats would strip the only CI-enforced coverage of the verdict surfaces. Re-verified this iter: `.github/workflows/ci.yml` now carries an `eval-agents` job that runs `scripts/run-agent-evals-ci.sh` -> `npm run eval:agents` over every `packages/*/agents/eval/promptfooconfig.yaml`, guarded by a step-level probe of the provisioned `CLAUDE_CODE_OAUTH_TOKEN` secret (fork PRs skip green; token-bearing runs are merge-blocking). RFC-012 records the S2/S3 ci.yml wiring as landed 2026-07-05 and the evals as proven green in CI on 2026-08-12. **Both preconditions of the user's 2026-07-04 ratified direction — provision the secret, wire the checks to gate CI merges — are therefore satisfied, and the THEN clause (delete the structural grep-the-prose tests) is live.**
>
> **Substance-confirm guard cleared (2026-09-19).** ADR-052 now carries `human-oversight: confirmed` / `oversight-date: 2026-06-10` on the hardened Option 1A (behavioural-only, no escape hatch) body, and ADR-005 is `confirmed` too. The ADR-074 hold recorded in the 2026-07-04 note is discharged: the retirement no longer builds on unconfirmed substance. **Phase 3 item 2 (re-confirm hardened ADR-052 + tightened ADR-005) is consequently already satisfied** — it happened out-of-band on 2026-06-10, ahead of this ticket's own sequencing.
>
> **Escape-hatch file-count drift (re-derived 2026-09-19):** `grep -rl 'tdd-review: structural-permitted' packages/` returns 38 raw matches -> 31 `.bats` conversion targets before this iter, 29 after the two retirements below. The count keeps growing because the hook's advisory heredoc still instructs authors to add the comment. Re-derive at execution time; do NOT trust the frozen 2026-06-09 list further down this file.

**Landed 2026-09-19 — first two structural retirements (the agent-prose pre-edit-review-mode pair):**

- [x] Deleted `packages/jtbd/agents/test/jtbd-pre-edit-review-mode.bats` and `packages/architect/agents/test/architect-pre-edit-review-mode.bats`. Both were pure positive prose greps over `agent.md` — every assertion `run grep ...` + `[ "$status" -eq 0 ]`, none asserting an absence, so neither fell in the ADR-005 preserved-exception class that keeps `hooks.json` content checks, file-existence/removal checks and hook-script safety-construct checks. Their behaviour is now asserted by the CI-gated promptfoo fixtures: every fixture in both eval configs frames its prompt as a PROPOSED change that is not yet applied and grades the verdict that comes back, so a P313 regression reds the fixture instead of passing a grep. Both files cited only `@jtbd JTBD-001`, which both successor configs already carry, so no annotation migration was owed.
- [x] Amended P313's `## Fix Released` evidence in place — it is a live `verifying`-state ticket that named both deleted files as its shipped guards. It now records the retirement and points forward to the covering fixtures, so a contributor verifying P313 lands on current evidence rather than two dead paths.

**Remaining agent-prose conversion targets (3), each with its specific unblock:**

- [ ] `packages/jtbd/agents/test/jtbd-unratified-dependency-verdict.bats` — its behaviour IS already covered (the jtbd eval's first fixture pins the positive-fire branch, asserting `JTBD Review: ISSUES FOUND` + `Unratified Dependency`; the second pins the over-fire guard). What blocks deletion is the `@jtbd JTBD-202` / `JTBD-101` trace this file carries at line 22, which must migrate to `packages/jtbd/agents/eval/promptfooconfig.yaml` first. **That annotation edit is gated on re-ratifying JTBD-001 + JTBD-002** — the jtbd gate flags re-authoring a citation manifest that already carries unratified jobs as an [Unratified Dependency] build-upon, and the named remedy is the interactive `/wr-jtbd:confirm-jobs-and-personas` drain, which an unattended run cannot reach.
- [ ] `packages/architect/agents/test/architect-needs-direction-verdict.bats` — the architect eval config has **no** NEEDS DIRECTION fixture at all. The sibling `promptfooconfig.codex.yaml` has one, but the codex configs are not run by CI: `npm run eval:agents` globs only `promptfooconfig.yaml`. **The replacement fixture is already designed and proven green** (see below); adding it is gated on the same JTBD-001/JTBD-002 drain, because the architect eval config's annotation block cites both.
- [ ] `packages/architect/agents/test/architect-unratified-dependency-verdict.bats` — gated on **RFC-012 S1b** (synthetic unratified-decision corpus). The claude runner does `cd "$REPO_ROOT"` and reads the live 130-ADR corpus, where no stable unratified ADR exists to cite, so the positive-fire branch is not constructable there. The codex runner already copies `packages/architect/agents/eval/fixtures/repo/` into a temp repo and covers it; porting that isolation to the claude runner IS the S1b slice.

**Deferred NEEDS DIRECTION fixture — wording already proven green, ready to land once the drain clears:**

The first attempt ported the codex config's marketplace-distribution prompt, and the architect gate correctly rejected it: ADR-003 (Marketplace-Only Distribution) and ADR-120 pin that choice in the live corpus, so the agent should *decline* to emit NEEDS DIRECTION there — the fixture would have failed outright, or worse flaked on corpus-reading variance. Replacement topic verified unpinned (`grep -ril 'bash 3|bash 4|bash 5|bash version|BASH_VERSINFO' docs/decisions/*.md` returns nothing), then run for real through `bash packages/architect/agents/eval/run-agent-eval.sh` against the live corpus. It emitted `**Architecture Review: NEEDS DIRECTION**` for the right reason — stated that no ADR pins a minimum bash version, named the decision question, enumerated viable options, flagged the `AskUserQuestion` handoff, and labelled its advisory lean without acting on it. It also surfaced live-repo grounding nobody fed it (18 bash-4-using scripts under `packages/*/scripts/`, hooks already 3.2-clean, P428's `/bin/bash` regression), which is the evidence that distinguishes corpus reading from prompt pattern-matching. Fixture prompt to land:

> PRE-EDIT architecture gate. Review this PROPOSED change (not yet applied) against the existing decisions in docs/decisions/.
>
> Proposed change: the repo's shell hook scripts must settle on a minimum bash version. Option A: keep targeting bash 3.2, the version macOS ships as /bin/bash, avoiding associative arrays and other bash-4+ constructs. Option B: require bash 5, add a BASH_VERSINFO guard that exits with a clear message on older interpreters, and document Homebrew bash as a contributor prerequisite. Both are workable; the prompt pins no direction and no existing decision records a choice.
>
> Classify the alignment of this proposal and give your verdict inline, beginning with the `Architecture Review:` verdict line.

Assertions: Tier A `icontains: 'NEEDS DIRECTION'`; Tier B `llm-rubric` requiring the response to name the unpinned decision question and surface two or more viable options rather than silently picking one, explicitly tolerating a labelled advisory lean — the observed-correct output carries one, so a stricter rubric would false-fail the very behaviour ADR-064 mandates (the P270 not-regex lesson). Caveat to carry: the fixture is coupled to the live corpus staying unpinned on bash version; if an ADR ever records one, the correct verdict inverts to PASS and the fixture false-fails. That coupling is a second argument for the S1b synthetic corpus.

**Stale cross-references in RATIFIED ADRs — owed a supersede-ADR, NOT an in-place edit:**

All four sites below still describe the removed Surface-2 escape hatch or name a now-deleted structural guard as a confirmation surface. Every one lives in an ADR carrying `human-oversight: confirmed`, and a ratified decision is immutable — changing it requires deprecation or a superseding decision, not an `### Amendment` section. **ADR-052's own Migration item 3 instructs a lockstep update of these references, but that instruction predates their ratification and must not be cited later as authority to edit them in place.**

- [ ] **ADR-068** line 82 — "structural-permitted per ADR-052 Surface 2 (P176)".
- [ ] **ADR-075** line 53 — "Surface-2 structural escape hatch is narrowed for agent-prose verdicts".
- [ ] **ADR-052** line 214 — residual `structural-justified` mention surviving its own amendment.
- [ ] **ADR-064** line 96 (Confirmation criterion 1 names `architect-needs-direction-verdict.bats` as the verdict's confirmation surface) and line 130. Both surfaced by the architect gate this iter; neither was in the previously-recorded set.

**JTBD-011 coupling — a user-facing job is held unratified by test infrastructure:**

`packages/jtbd/agents/eval/promptfooconfig.yaml`'s first fixture hard-codes JTBD-011 (Have a Correction to the Agent's Conduct Hold Everywhere) as its unratified subject, so ratifying that job turns the merge-blocking fixture red. The drain must therefore be scoped to JTBD-001 + JTBD-002 and exclude JTBD-011. The durable fix is the same RFC-012 S1b synthetic corpus — a fixture job carrying `human-oversight: unconfirmed`, isolated from the live `docs/jtbd/` root — which frees the real job to be ratified. This must not be allowed to rot into prose-only.

**Persona cost recorded (plugin-developer, ratified):** the documented "slow test-fix-release cycles" pain point gets marginally worse with each retirement, because a locally-runnable bats is replaced by a live-agent CI eval while RFC-012 S2's pre-commit/pre-push hook is still open. ADR-052 plus the pinned 2026-07-04 direction settle the trade-off; the cost is tracked, not concealed.

**ADR-075 cost-trip measurement owed:** the architect gate noted ADR-075's cost-trip criterion still records "no per-run data yet" for the eval job. Capturing per-run token / wall-clock cost is a separate measurement task, deliberately not folded into this ticket's slices.

- [x] Update `packages/tdd/agents/review-test.md` verdict vocabulary: collapsed to BEHAVIOURAL / MIXED / STRUCTURAL / UNCLEAR (dropped `structural-justified` AND `structural-permitted` from the enum). STRUCTURAL is now a failing classification; the escape-hatch recognition section is removed. ADR-005's preserved exceptions (hooks.json content, file-existence/removal, safety-construct presence on executable bash under `hooks/`) fold into BEHAVIOURAL — they observe artefact/executable/filesystem state, not prose-document content (ADR-052 line 194 retains them for ADR-005). **Paired a promptfoo agent-prose-verdict eval** at `packages/tdd/agents/eval/` (config + `run-agent-eval.sh` + `grade-llm-rubric.sh`, replicating the P324/RFC-012 architect+jtbd `agents/eval/` pattern; dev-only, tarball-excluded via `package.json` `"!agents/eval/"`) — three Tier-A/Tier-B fixtures: behavioural→behavioural, prose-grep→structural(failing, no-escape-hatch), and the ADR-005 preserved-exception over-fire guard. Closes R009 for this agent-prose change. Landed 2026-06-27 (SAFE non-breaking slice — the hook short-circuits the 28 files at line 73 BEFORE the agent runs, so the 28 still-structural files do not reach the agent and CI is unaffected; `npm test` runs bats only, no `.github` promptfoo workflow). **Release vehicle**: `.changeset/wr-tdd-p290-review-test-vocab.md`.
- [ ] Update `packages/tdd/hooks/tdd-review-test.sh`: remove the `WR_TDD_REVIEW_TEST=skip` env-var short-circuit + the `tdd-review: structural-permitted` in-file comment short-circuit. Hook fires on every test-shaped write inside `$PWD`. **(DEFERRED — removing the short-circuits while ~29 structural files still exist would break CI/commits on all of them; gated on the conversion count hitting 0.)** Architect advisory 2026-06-27: the hook's advisory heredoc (lines 96-103) still instructs authors to add a `tdd-review: structural-permitted` comment — that prose contradicts the now-behavioural-only agent vocabulary and must be rewritten in the same iter that removes the short-circuits, so the hook prose and agent prose don't drift in opposite directions.
- [ ] Convert the remaining in-tree structural-reliant test files to behavioural-only (**2 of 31 retired as of 2026-09-19**; the frozen list below is stale — re-derive it at execution time). The 2026-07-04 "gated on RFC-012 S2" directive that stood here is **superseded**: S2/S3 CI wiring landed 2026-07-05 and the evals were proven green in CI on 2026-08-12, so the retirement precondition is met. See the BLOCKER RESOLVED note above and the per-target unblocks recorded there — the three remaining agent-prose targets wait on the JTBD-001/JTBD-002 drain and on RFC-012 S1b, and the ~26 SKILL-prose targets wait on RFC-012 S6.
- [ ] Update downstream-consumer ADRs that reference the old Surface-2 framing:
  - [ ] **ADR-068** line 82 — references "structural-permitted per ADR-052 Surface 2 (P176)"; needs parallel update.
  - [ ] **ADR-075** line 53 — references "Surface-2 structural escape hatch is narrowed for agent-prose verdicts"; needs parallel update.

**Phase 3 — Hook promotion + re-confirm (post-Phase-2):**

- [ ] Promote the `tdd-review-test.sh` hook from PostToolUse advisory to PreToolUse blocking once in-tree structural-classified count hits 0.
- [ ] Re-confirm hardened ADR-052 + tightened ADR-005 via `/wr-architect:review-decisions` → write `human-oversight: confirmed` on both.
- [ ] Close P290.

### 28 in-tree structural-reliant test files (Phase 2 conversion targets)

Captured 2026-06-09 via `grep -rl 'tdd-review: structural-permitted' packages/` (33 raw matches, minus 5 non-test files):

```
packages/architect/agents/test/architect-needs-direction-verdict.bats
packages/architect/agents/test/architect-pre-edit-review-mode.bats
packages/architect/agents/test/architect-unratified-dependency-verdict.bats
packages/architect/skills/create-adr/test/create-adr-adr-044-contract.bats
packages/architect/skills/create-adr/test/create-adr-substance-confirm-pattern.bats
packages/itil/agents/test/hang-off-check.bats
packages/itil/scripts/test/update-problem-references-section.bats
packages/itil/skills/manage-incident/test/manage-incident-adr-044-contract.bats
packages/itil/skills/manage-problem/test/manage-problem-adr-044-step4-derive-first.bats
packages/itil/skills/manage-problem/test/manage-problem-release-vehicle-seed.bats
packages/itil/skills/manage-problem/test/manage-problem-step-9d-recovery-path.bats
packages/itil/skills/mitigate-incident/test/mitigate-incident-contract.bats
packages/itil/skills/report-upstream/test/report-upstream-contract.bats
packages/itil/skills/work-problem/test/work-problem-contract.bats
packages/itil/skills/work-problems/test/work-problems-adr-013-rule-6-p352-amendment.bats
packages/itil/skills/work-problems/test/work-problems-deviation-candidate-shape.bats
packages/itil/skills/work-problems/test/work-problems-mid-loop-userpromptsubmit-handler.bats
packages/itil/skills/work-problems/test/work-problems-step-5-is-error-transient-halt.bats
packages/itil/skills/work-problems/test/work-problems-step-5-iter-changeset-required.bats
packages/itil/skills/work-problems/test/work-problems-step-5-prompt-body-re-grounding.bats
packages/itil/skills/work-problems/test/work-problems-step-5-stream-timeout-salvage.bats
packages/jtbd/agents/test/jtbd-pre-edit-review-mode.bats
packages/jtbd/agents/test/jtbd-unratified-dependency-verdict.bats
packages/retrospective/skills/run-retro/test/run-retro-step-2d-r6-auto-flag.bats
packages/retrospective/skills/run-retro/test/run-retro-step-4a-cross-plugin-dispatch.bats
packages/retrospective/skills/run-retro/test/run-retro-step-4a-prior-session-evidence-drain.bats
packages/retrospective/skills/run-retro/test/run-retro-step-4a-recovery-path.bats
packages/shared/test/intake-templates.bats
```

(28 entries. `packages/tdd/hooks/test/tdd-review-test.bats` is the dogfood test for the escape-hatch logic itself — it gets rewritten alongside the hook source rather than counted as a conversion target. P324 is the gating ticket for the architect + jtbd agent-prose-verdict tests at the top of the list.)

### Open substance question (queued for next interactive turn)

**Transition treatment of the 28 in-tree structural-reliant test files during the contradiction window** — between this Phase 1 amendment landing (2026-06-09) and Phase 2 completion (blocked on P324). Three options the architect surfaced:

- (i) **Honest contradiction window** — Phase 1 amendment lands as-is; the 28 in-tree tests persist as known-state-of-violation tracked by this ticket until Phase 2 conversion completes. Hook continues advisory-only in this window. (Current default in this Phase 1 amendment.)
- (ii) **Block Phase 1 on P324** — defer the ADR-052 amendment landing until P324's behavioural harness ships, then collapse Phase 1 + Phase 2 into one iter.
- (iii) **Delete the 28 in-tree tests in the Phase 1 commit** — aggressive but eliminates the contradiction window at the cost of losing coverage of agent-prose-verdict surfaces until P324 lands.

This question is queued in `outstanding_questions` for the user's next interactive turn. Phase 1 has landed under default (i) per the iter task constraints (AskUserQuestion forbidden); (ii) would have required a rollback; (iii) would have required substance confirmation that wasn't pinned.

## Dependencies

- **Blocks**: ADR-052 + ADR-005 human-oversight confirmation (both cleared to `unconfirmed` by the 2026-06-09 Phase 1 amendment; re-confirmation held until P290 Phase 2 + Phase 3 close).
- **Blocked by**: **RFC-012 S2** (Tier-A promptfoo CI wiring) — gates the architect + jtbd bats *retirement* (RFC-012 S4). The S1/S1-arch harness exists but is dev-only/manual; until S2 wires Tier-A into `ci.yml`, retiring the structural bats strips the only CI-enforced coverage (2026-07-04 BLOCKER finding). **P324** (agent-prose-verdict behavioural harness primitive) — the harness-existence prerequisite; now satisfied for architect + jtbd, but harness-existence ≠ retirement-safety.
- **Composes with**: P081 (structural-tests-are-wasteful master), P012 (skill-testing-harness / Layer B primitives), P176 (skill-invocation harness-gap), ADR-052 (amendment target), ADR-005 (narrowing-tightening target), ADR-064 (Surface-2 cross-ref cleanup), ADR-068 + ADR-075 (Phase 2 downstream-consumer ADRs), `packages/tdd/agents/review-test.md` + `packages/tdd/hooks/tdd-review-test.sh` (Phase 2 source surfaces), P283/ADR-066 (the drain that surfaced this).

## Related

(captured during the P283/ADR-066 ADR-oversight drain, 2026-05-25)

- **P283** / **ADR-066** — the oversight-drain mechanism that surfaced this.
- **P287** (ADR-060 type-tag) + **P289** (solo-developer rename) — sibling drain-surfaced material amendments; same "withhold marker + capture rework" pattern.
- **P081** — structural-tests-are-wasteful master ticket (this hardens it into policy).
- **ADR-052** (`docs/decisions/052-behavioural-tests-default-for-skill-testing.proposed.md`) — amendment target.
- **ADR-005** + **P011** — the structural Permitted Exception this supersedes.
- `packages/tdd/agents/review-test.md` — the `review-test` verdict surface.


## Ratified Direction - 2026-07-04 interactive decision drain

**Provision a CI claude-auth secret** (USER ACTION), then wire the promptfoo behavioural checks to gate CI merges, THEN delete the structural grep-the-prose tests. Also unblocks P324 (agent-prose harness S3). Do NOT delete structural tests before CI-wiring exists.
