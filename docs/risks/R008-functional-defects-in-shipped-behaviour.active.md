---
risk_id: R008
slug: functional-defects-in-shipped-behaviour
status: Active
category: delivery
identified: 2026-05-04
owner: plugin-maintainer
last_reviewed: 2026-05-04
next_review: 2026-08-04
asset_path: [packages/*/skills/*/SKILL.md, packages/*/agents/*.md, packages/*/hooks/*.sh, packages/*/scripts/*.sh, scripts/repo-local-skills/*/SKILL.md]
cascade_scope: every adopter invocation of an affected skill / agent / hook / script; every workflow built on the buggy behaviour
afk_class: both
reversal_class: npm-permanent (defects in published plugins persist until next release; adopters' cached versions until reinstall)
control_budget_class: free-hook (commit-time TDD enforce-edit) + per-edit-llm (architect/JTBD/test-classification reviews) + sustained dogfood-window cost
dogfood_days: variable per surface; established discipline ~30+ days project-wide
authority_class: framework-resolved (test-failure is mechanical); user-direction (which defects are accept-vs-fix)
prompt_cache_window: ongoing
ci_a: integrity (behaviour deviates from contract); availability (defective behaviour can block legitimate workflow)
agentic_category: drift (between contract and implementation), but applies to ALL software not just agentic
---

# Risk R008: Functional defects in shipped plugin behaviour

## Description

Software has bugs. Plugins ship with logic that doesn't behave as the SKILL/agent/hook prose describes — wrong-branch evaluation, off-by-one in slug computation, regex matcher missing a class, marker key-mismatch, hook returning wrong exit code, script behaviour diverging from documented contract. A defect in a published plugin reaches every adopter who installs the version; a defect in a hook fires on every gated tool call until reinstall; a defect in an agent prompt biases every invocation until prompt-cache refresh.

This is the bedrock software-delivery risk class. It exists for every software project; documenting it explicitly here is intentional because (a) the register should not be implicit about the foundation, (b) ISO 31000 wants the full inventory not just the novel parts, (c) other register entries (R001 drift, R002 hook regression, R005 release coordination) are *specialisations* of this class — they describe specific defect modes; R008 is the catch-all for "any other functional defect".

**Source → event → consequence chain**: source = code change lands without exercising the failure scenario in tests; event = adopter (or CI; or in-repo dogfood) hits the unexercised path and produces unexpected behaviour; consequence = workflow degraded / blocked, trust-budget consumed, support cost incurred.

## Inherent Risk

- **Impact**: 4/5 (Significant) — for the typical defect, installed-user workflow degraded across affected paths. Some defect classes (security gate false-allow, secret-leak regex bypass) escalate to higher impact via R003. Others (cosmetic message wording) sit lower.
- **Likelihood**: 4/5 (Likely) — every commit touching plugin code introduces opportunity for defects; the corpus is dominated by per-action pipeline reports tracking exactly this exposure (164 reports across the past 6 weeks).
- **Inherent Score**: 16
- **Inherent Band**: High

## Controls

- **Behavioural bats coverage per ADR-052** (`packages/*/skills/*/test/*.bats`, `packages/*/hooks/test/*.bats`, `packages/*/scripts/test/*.bats`) — TDD discipline requires bats coverage of new behaviour before commit. **Effectiveness**: high for tested surfaces; lower for surfaces without coverage (see R009 for that gap class). Reduces likelihood from 4 to 2 for tested-path defects.
- **`packages/tdd/hooks/tdd-enforce-edit.sh`** + **`packages/tdd/hooks/tdd-post-write.sh`** + **`packages/tdd/hooks/tdd-review-test.sh`** (P081) — enforce TDD red-green-refactor at commit time; classify tests as STRUCTURAL vs BEHAVIOURAL per ADR-052. **Effectiveness**: high for the TDD-gated subset (TS/TSX/JS/JSX) — would reduce likelihood from 2 to 1 for that subset *if it dominated*, but the asset_path is dominated by `.sh` hooks, `.md` SKILL/agent prompts, and `.bats` tests, none of which the TDD red-green hooks gate. Project-wide effect is marginal. Does NOT shift the project-wide residual likelihood.
- **Architect + JTBD review on every Edit/Write** — independent reviewers see proposed changes before they land. **Effectiveness**: medium — catches design defects (wrong abstraction) more than implementation defects (off-by-one). Reduces likelihood marginally for design-class defects.
- **Held-changeset / dogfood-window pattern (R002 control)** — gives in-repo runtime dogfood evidence before adopter exposure. **Effectiveness**: medium-high for dogfood-able surfaces; lower for surfaces only exercised by adopters in different environments.
- **`/wr-risk-scorer:assess-wip` + per-action pipeline scoring** — each commit scored against RISK-POLICY.md; above-appetite residuals halt. **Effectiveness**: low for catching specific functional defects (the scorer reasons about risk classes, not unit-test failures); high for surfacing structural failure modes (architectural drift, untested cascade scope).
- **Behavioural replay** in ADR Confirmation criteria — every ADR mandates manual replay of the implemented behaviour against documented user-verifiable steps. **Effectiveness**: medium — depends on replay discipline; held-changeset reinstate triggers cite "user signals comfort after dogfood observation" as the canonical signal.

## Residual Risk

- **Impact**: 3/5 (Moderate) — controls reduce probability but don't change consequence shape per-defect; reduced from Significant because the typical bug-trajectory in this project ends with in-repo dogfood catching it before adopter exposure (held-changeset pattern), not adopter discovery.
- **Likelihood**: 2/5 (Unlikely) — bats coverage on the dominant asset_path subset (hooks + scripts) is the load-bearing reduction (4 → 2). Other controls (architect/JTBD review, dogfood-window, pipeline scoring) contribute marginal additional reduction; TDD red-green enforcement targets a tiny TS/JS subset that doesn't shift the project-wide weighted residual. Observed in-repo dogfood catch rate is high (P085, P064, P159 each had defects surface in dogfood window) but the catch-rate evidence is weighted toward hook-bearing changes specifically; bedrock defects in skills/agents/scripts are not as well-evidenced. Project-wide residual likelihood holds at 2.
- **Residual Score**: 6
- **Residual Band**: Medium
- **Within appetite?**: No (above 4/Low). Treatment Mitigate continues; bedrock class — eliminating residual to within appetite would require defect-free software (impossible).

## Treatment

**Mitigate** — accept that bedrock-class residual will sit above appetite forever; invest in controls that reduce occurrence + minimise blast radius per occurrence.

**Active mitigations**:
1. TDD discipline + bats coverage on new surfaces (per ADR-052).
2. Held-changeset dogfood-window for hook/skill/script changes (R002 control).
3. Architect + JTBD review gates per CLAUDE.md.
4. Pipeline scoring per RISK-POLICY.md on every commit.
5. Per-defect: file a problem ticket (P078 capture-on-correction surface) when discovered; root-cause-analyse; fix; verify.

**Acceptance**: at residual 6/Medium, this risk class is intentionally above appetite per `RISK-POLICY.md` `## Risk Catalog` ("A catalog-documented residual above appetite IS a real signal — baseline controls are not sufficient for the typical action that triggers this risk class. Either add more controls (drop baseline residual into appetite) or accept that per-action assessments must add specific controls each time"). Per-action assessments add specific controls (the pipeline scorer evaluates each commit's defect risk in context).

**Owner**: plugin-maintainer (Tom Howard).

## Monitoring

- **Trigger to re-assess**: a defect reaches an adopter machine and produces a problem ticket. Or: bats coverage falls below 80% on any plugin's critical-path surface (signal: TDD discipline regressing). Or: held-changeset dogfood-window observed catch-rate trends below 50% (signal: dogfood not catching defects).
- **Metrics**: count of problem tickets opened per month with `/wr-itil:capture-problem` route; bats coverage % per plugin; held-changeset dogfood-window catch count vs adopter-discovered count.

## Related

- **Criteria**: `RISK-POLICY.md`
- **Specialisations** (this risk class generalises these specifics): R001 (documentation-runtime drift), R002 (hook regression cascade), R005 (cross-package release coordination), R009 (insufficient bats coverage), R010 (semver violations).
- **Realised-as**: every problem ticket in `docs/problems/` whose root cause is a code defect (the majority of the backlog). Specifically: P035 (manage-problem commit-gate fallback), P037 (jtbd-reviewer bare verdict), P046 (architect runtime-path performance), P049 (Verification Pending status migration), P124 (SID drift), P119 (manage-problem create-gate), P141 (changeset-discipline gate first iteration), and many others.
- **Treatment ADRs**: ADR-052 (behavioural-tests default; supersedes ADR-037), ADR-005 (Permitted Exceptions; structural test ban with carve-outs), ADR-014 (single-commit grain — minimises blast-radius per-commit), ADR-018 (release cadence), ADR-042 (auto-apply remediations for above-appetite).
- **Personas affected**: every persona — defects affect plugin-user (workflow degradation), plugin-developer (debugging cost), tech-lead (audit-trail integrity), plugin-maintainer (release coordination + support cost).

## Source Evidence

- 164 `.risk-reports/*.md` across the past 6 weeks — every per-action assessment is fundamentally a defect-risk evaluation.
- Problem ticket backlog in `docs/problems/` — majority of tickets root-cause to functional defects (P035, P037, P046, P049, P119, P124, P141, etc.).
- ADR-052 + ADR-037 supersession — codifies the test-discipline arc.
- `packages/tdd/hooks/*.sh` — TDD-enforce control implementations.
- Held changesets P085 / P064 / P159 — exemplars of in-repo dogfood catching defects before adopter exposure.

## Change Log

- 2026-05-04: Bootstrapped from corpus + problem-backlog evidence post-wipe. NEW class — not covered by pre-wipe R001-R006 (which were specifications of specific defect modes). Documenting this class explicitly addresses the user observation 2026-05-04 that the post-wipe register over-rotated to agentic-novel classes and skipped the bedrock software-delivery surface. Other register entries (R001/R002/R005/R009/R010) are specialisations of R008.
