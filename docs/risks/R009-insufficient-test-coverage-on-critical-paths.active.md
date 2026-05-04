---
risk_id: R009
slug: insufficient-test-coverage-on-critical-paths
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [packages/*/skills/*/test/, packages/*/hooks/test/, packages/*/scripts/test/, packages/*/agents/test/]
cascade_scope: every untested code path that ships; every regression in those paths that subsequent commits introduce undetected
afk_class: both
reversal_class: bats-recoverable (writing the missing test is the fix); the underlying defect blast-radius depends on what the path does
control_budget_class: per-edit-llm at write-time (TDD red-green); free-hook at commit-time (TDD enforce-edit checks paired test exists)
dogfood_days: ADR-052 ~7 days; ADR-037 superseded shape ran ~30 days prior
authority_class: framework-resolved (TDD discipline is mechanical); deviation-approval for documented Permitted Exception (P081 structural-permitted comment + harness-gap citation)
prompt_cache_window: ongoing
ci_a: integrity (regression in untested path produces wrong behaviour); availability (untested edge cases can break under conditions the test suite never exercises)
agentic_category: drift (test-suite-coverage vs runtime-path-coverage)
---

# Risk R009: Insufficient bats / behavioural test coverage on critical paths

## Description

Plugin code paths that are NOT exercised by behavioural tests can ship with defects that subsequent commits introduce or fail to remove. ADR-052 (behavioural-tests-default, supersedes ADR-037) sets the discipline: test-green ≡ safe-to-commit. ADR-005 + P011 carve out Permitted Exceptions for prose-spec assertions on agent prompts and SKILL.md content. P081 (structural source-content tests are wasteful) extends this with the `tdd-review-test` agent that classifies new test files as STRUCTURAL vs BEHAVIOURAL and rejects bare structural greps without harness-gap citation.

But the test suite has gaps: ~50 existing structural bats predate ADR-052 and remain accepted-until-touched per the migration clause. Critical-path coverage is uneven across plugins — some have rich behavioural fixtures (`packages/risk-scorer/agents/test/*.bats`, `packages/itil/hooks/test/*.bats`); others have thinner coverage. The risk: a code path that's not in any bats can regress silently between commits.

This risk class is a *specialisation* of R008 (functional defects); it specifically addresses the *meta-control* — the test suite — rather than per-defect occurrences. A weakening of this control is observable in advance (coverage drops) and is itself a leading indicator for R008 residuals trending up.

**Source → event → consequence chain**: source = code path lands without paired bats coverage (Permitted Exception not cited; structural-grep-only test; or no test at all); event = subsequent commit modifies the path or its dependencies; consequence = regression undetected at commit-time, ships through dogfood (which exercises only documented user-verifiable steps), reaches adopters where the un-exercised path manifests.

## Inherent Risk

- **Impact**: 3/5 (Moderate) — uncovered paths can degrade adopter workflow; severity scales with how critical the path is. Not Significant because most critical paths in this project HAVE bats coverage; the un-covered paths are typically edge cases.
- **Likelihood**: 3/5 (Possible) — corpus evidence: ADR-052 Migration section explicitly accepts ~50 existing structural bats as "accepted-until-touched"; P081 codification recent (~3 days); coverage debt is a known property of the project.
- **Inherent Score**: 9
- **Inherent Band**: Medium

## Controls

- **`packages/tdd/hooks/tdd-enforce-edit.sh`** — TDD red-green enforcement at commit time. Implementation files (.ts/.tsx/.js/.jsx) blocked from edit unless paired test is in RED or GREEN state. **Effectiveness**: high for TDD-gated extensions (.ts/.tsx/.js/.jsx); zero for the dominant project surface (.sh hooks, .md SKILL/agent prompts, .bats tests themselves). Reduces likelihood from 3 to 2 for TS/JS surfaces; no reduction for Bash/Markdown.
- **`packages/tdd/hooks/tdd-review-test.sh`** + **`packages/tdd/agents/review-test.md`** (P081) — PostToolUse advisory hook + classification agent flag STRUCTURAL test files; suggest behavioural alternatives; require harness-gap ticket citation when structural-permitted. **Effectiveness**: medium-high for the *new-test-file* subset — would reduce likelihood from 2 to 1 for that subset specifically. But ~50 legacy structural bats are accepted-until-touched per ADR-052 Migration; they remain a residual surface unaffected by this control. Project-wide weighted likelihood does not drop because the legacy population dominates until it's retrofitted.
- **ADR-052 Migration clause** — accepted-until-touched policy for legacy structural bats. **Effectiveness**: control-relaxation (intentional). Documents coverage debt explicitly so it's not forgotten; contributes to control transparency.
- **ADR-005 + P011 Permitted Exception narrative** — structural-grep ban with carve-outs. **Effectiveness**: medium — clear policy boundary makes audit possible; depends on author honesty in citing exceptions.
- **Architect + JTBD review on test-bearing edits** — reviewers see new bats files and flag missing coverage. **Effectiveness**: medium — depends on reviewer thoroughness; surfaces obvious gaps.

## Residual Risk

- **Impact**: 3/5 (Moderate) — controls don't change per-path consequence shape.
- **Likelihood**: 2/5 (Unlikely) — TDD-enforce on the TS/JS subset + review-test classifier on new test files each reduce likelihood for THEIR scope; legacy ~50 structural bats remain a residual surface that accepted-until-touched policy bounds but doesn't actively eliminate. Project-wide weighted residual reflects the legacy gap — would drop to 1 once the legacy retrofit completes (Phase-2 trigger documented below).
- **Residual Score**: 6
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; coverage retrofit is incremental-as-touched per ADR-052 Migration clause.

## Treatment

**Mitigate**. Continue TDD discipline + ADR-052 behavioural-tests-default + P081 review-test classifier + Permitted Exception discipline. Coverage retrofit is incremental — when a code path is touched by a commit, paired bats coverage upgrades from structural-permitted (or none) to behavioural at that point.

**Active mitigations**:
1. TDD red-green enforcement on TS/JS surfaces (existing hook stack).
2. P081 review-test classifier on new test files (advisory; promotes to blocking if Phase 2 reassessment fires).
3. ADR-005 Permitted Exception narrative for prose-spec asserts.
4. ADR-052 Migration clause: legacy ~50 structural bats convert as touched.

**Phase-2 trigger** (per ADR-052 Reassessment Criteria): if un-annotated structural count drops to 0 OR advisory-skip rate exceeds 20% sustained, promote `tdd-review-test` to PreToolUse blocking (current state: PostToolUse advisory).

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: total structural-bats count exceeds 100 (signals migration not keeping pace). Or: a defect reaches an adopter via a path that lacks bats coverage (post-hoc trigger). Or: ADR-052 advisory-skip rate exceeds 20% sustained.
- **Metrics**: count of `*.bats` files per plugin; ratio behavioural / structural; count of test-class advisory-skips per week (signal: review-test classifier being routed around); harness-gap ticket count (P012-shape framework primitives needed).

## Related

- **Criteria**: `RISK-POLICY.md`
- **Realised-as**: P011 (Permitted Exception driver), P081 (structural source-content tests are wasteful — TDD agent should reject them), P012 (Skill testing harness scope undefined — framework primitives blocker).
- **Generalisation-of**: R008 (functional defects in shipped behaviour) — R009 specialises by addressing the test-suite meta-control.
- **Treatment ADRs**: ADR-052 (behavioural-tests default; supersedes ADR-037), ADR-005 (Permitted Exception narrative), ADR-037 (.superseded; covers the prior test-discipline regime).
- **Personas affected**: plugin-developer (JTBD-101 — clear patterns for new plugin authors); plugin-maintainer (coverage debt management cost); plugin-user (every uncovered defect reaches them).

## Source Evidence

- `docs/decisions/052-behavioural-tests-default-for-skill-testing.proposed.md` Migration clause — names ~50 structural bats accepted-until-touched.
- `docs/decisions/005-plugin-testing-strategy.*.md` — Permitted Exception authority.
- `docs/problems/081-structural-source-content-tests-are-wasteful.verifying.md` — driver for the classifier.
- `docs/problems/011-permitted-exception-...md` — driver for the ADR-005 carve-out.
- `docs/problems/012-skill-testing-harness-scope-undefined.open.md` — Layer-B framework primitives; blocks comprehensive coverage upgrade.
- `packages/tdd/hooks/*.sh` — control implementations.
- `packages/tdd/agents/review-test.md` — classifier agent prompt.

## Change Log

- 2026-05-04: Bootstrapped post-wipe addressing user observation that post-wipe register over-rotated to agentic-novel classes and missed bedrock software-delivery risks. R009 specialises R008 by addressing the test-suite meta-control. Inherent / Residual estimated from ADR-052 + ADR-005 + P081 control inventory + Migration clause coverage-debt accounting.
