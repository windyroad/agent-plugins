# Problem 290: Harden ADR-052 to behavioural-only — remove the structural-test escape hatch entirely

**Status**: Open
**Reported**: 2026-05-25
**Priority**: 9 (Med High) — Impact: 3 (Moderate — the documented-justification escape hatch lets wasteful structural tests keep shipping; the user's standing position is that structural tests are "not real tests"; removing the hatch raises the whole suite's test quality and stops the `structural-justified` verdict being a permanent parking spot) × Likelihood: 3 (Likely — every test-author decision + the 28 existing escape-hatch-reliant test files)
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

**Phase 2 — Source conversion (DEFERRED; blocked on P324):**

- [ ] Update `packages/tdd/agents/review-test.md` verdict vocabulary: collapse to BEHAVIOURAL / MIXED / STRUCTURAL / UNCLEAR (drop `structural-justified`). STRUCTURAL becomes a failing classification.
- [ ] Update `packages/tdd/hooks/tdd-review-test.sh`: remove the `WR_TDD_REVIEW_TEST=skip` env-var short-circuit + the `tdd-review: structural-permitted` in-file comment short-circuit. Hook fires on every test-shaped write inside `$PWD`.
- [ ] Convert the 28 in-tree structural-reliant test files to behavioural-only (list below). Conversions that depend on agent-prose-verdict behavioural harness primitives BLOCK on **P324** until the harness ships.
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
- **Blocked by**: **P324** (agent-prose-verdict behavioural harness primitive) — gates Phase 2 conversion of the 28 in-tree structural-reliant test files; without P324's Layer B harness, the architect + jtbd agent-prose verdict tests cannot be expressed behaviourally.
- **Composes with**: P081 (structural-tests-are-wasteful master), P012 (skill-testing-harness / Layer B primitives), P176 (skill-invocation harness-gap), ADR-052 (amendment target), ADR-005 (narrowing-tightening target), ADR-064 (Surface-2 cross-ref cleanup), ADR-068 + ADR-075 (Phase 2 downstream-consumer ADRs), `packages/tdd/agents/review-test.md` + `packages/tdd/hooks/tdd-review-test.sh` (Phase 2 source surfaces), P283/ADR-066 (the drain that surfaced this).

## Related

(captured during the P283/ADR-066 ADR-oversight drain, 2026-05-25)

- **P283** / **ADR-066** — the oversight-drain mechanism that surfaced this.
- **P287** (ADR-060 type-tag) + **P289** (solo-developer rename) — sibling drain-surfaced material amendments; same "withhold marker + capture rework" pattern.
- **P081** — structural-tests-are-wasteful master ticket (this hardens it into policy).
- **ADR-052** (`docs/decisions/052-behavioural-tests-default-for-skill-testing.proposed.md`) — amendment target.
- **ADR-005** + **P011** — the structural Permitted Exception this supersedes.
- `packages/tdd/agents/review-test.md` — the `review-test` verdict surface.
