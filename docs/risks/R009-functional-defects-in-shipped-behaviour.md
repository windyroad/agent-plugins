# R009: Functional defects in shipped plugin behaviour

Software has bugs. A plugin ships logic that doesn't behave as the SKILL/agent/hook prose describes — wrong-branch evaluation, off-by-one in slug computation, regex matcher missing a class, marker key-mismatch, hook returning wrong exit code, script behaviour diverging from documented contract. A defect in a published plugin reaches every adopter who installs the version; in a hook it fires on every gated tool call until reinstall; in an agent prompt it biases every invocation until prompt-cache refresh.

This is the bedrock software-delivery risk class. Several other entries are *specialisations* of it — R002 (drift), R003 (hook regression), R005 (release coordination), R006 (publish-boundary), R010 (semver violation) each name a specific defect mode. R009 is the catch-all for "any other functional defect" that doesn't slot into a specialisation.

Insufficient test coverage is treated here as a control gap, not a separate risk class — uncovered code paths are how defects ship; covering them is how this risk's residual drops. The "Controls" section below details the test-discipline surfaces.

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 4 (Significant) — `RISK-POLICY.md` L64: "Installed plugins degrade developer workflow — hooks fire incorrectly, skills fail to load". Functional defects in shipped behaviour are this Impact class by definition.
- **Likelihood**: 4 (Likely) — every code change risks defects; bedrock class with high inherent likelihood.
- **Inherent score**: 16
- **Inherent band**: High

## Residual risk

Per `RISK-POLICY.md` `## Control Composition`:

- **Likelihood after controls**: 2 (Unlikely) — two effective paths over the broad class: behavioural bats coverage on the dominant tested-path subset (hooks + scripts) and architect/JTBD review on every Edit/Write. TDD red-green hooks gate only `.ts/.tsx/.js/.jsx` (~5% of project surface), so they don't shift project-wide weighted residual. Held-changeset dogfood + pipeline scoring + behavioural replay are sub-class-scoped and don't compose project-wide. 4 → 3 → 2.
- **Residual score**: 8
- **Residual band**: Medium

**Gap-to-appetite**: residual exceeds appetite (4/Low) — but this is the bedrock class; defect-free software is impossible. Realistic mitigation lowers residual incrementally as: (a) ADR-052 Migration retrofits legacy structural bats to behavioural; (b) Phase-2 promotion of `tdd-review-test` from PostToolUse advisory to PreToolUse blocking; (c) coverage gaps in skill/agent prose surfaces close as the test harness for prompt-driven LLM behaviour matures (P012). None of these gets residual below ~6 because the bedrock-class likelihood floor is 2 even with three solid independent paths.

## Controls

- **Behavioural bats per ADR-052** (`packages/*/{skills,agents,hooks,scripts}/test/*.bats`) — TDD discipline; coverage is uneven across plugins. ~50 legacy structural bats are accepted-until-touched per ADR-052 Migration (incremental retrofit, not retroactive).
- **TDD red-green discipline** via `packages/tdd/hooks/tdd-enforce-edit.sh` + `tdd-post-write.sh` — gates `.ts/.tsx/.js/.jsx` files from edit unless paired test is RED or GREEN. Does NOT gate `.sh`/`.md`/`.bats` (the dominant surface in this project), so most defects need coverage by-package convention rather than enforcement.
- **`packages/tdd/hooks/tdd-review-test.sh`** + **`packages/tdd/agents/review-test.md`** (P081) — PostToolUse advisory hook + classification agent flag STRUCTURAL test files; suggest behavioural alternatives; require harness-gap ticket citation when structural-permitted.
- **ADR-005 + P011 Permitted Exception narrative** — structural-grep ban with carve-outs for prose-spec assertions on SKILL.md / agent.md / ADR content (where behavioural verification is genuinely out of scope).
- **Architect / JTBD review on every Edit/Write** — independent reviewers see proposed changes before they land. Catches design defects (wrong abstraction) more than implementation defects (off-by-one).
- **Held-changeset / dogfood-window pattern** — gives in-repo runtime time to surface defects before adopter exposure (R003 control; applies broadly to defect classes touching hooks/skills).
- **Per-action pipeline scoring** — each commit is scored against `RISK-POLICY.md`; above-appetite residuals halt. More effective for surfacing structural failure modes (architectural drift, untested cascade scope) than catching specific unit-test failures.
- **Behavioural replay in ADR Confirmation criteria** — every ADR mandates manual replay of implemented behaviour against documented user-verifiable steps.

## Watch-out

- Defect-free software is impossible — this class will always sit at non-zero residual. Mitigation is about reducing occurrence + minimising blast-radius per occurrence, not elimination.
- When scoring, check whether the defect maps to a specialisation entry (R002/R003/R005/R006/R010) before naming it as generic R009. If it does, score against the specialisation — its controls and watch-outs are sharper.
- Defects in skill / agent prose (vs. in script code) are harder to test behaviourally — the runtime is LLM-driven, output is non-deterministic, structural assertions on prompt content are pragmatic but limited (per ADR-005 + P011 Permitted Exception).
- Held-changeset dogfood catches HOOK defects well (P085, P064, P159 are exemplars) but skill-prose defects often slip through because dogfood replays focus on documented steps, not the un-documented edge cases that bite adopters.
- Coverage gap sub-classes worth distinguishing: (a) new code lands without paired bats; (b) modified code's bats only assert stdout/exit-code, missing filesystem side-effects on the same path; (c) ~50 legacy structural bats give a "test passes" signal that's weaker than it looks (they assert prose content, not behaviour). The Phase-2 trigger in ADR-052 Reassessment Criteria — un-annotated structural count drops to 0 OR advisory-skip rate exceeds 20% sustained — is when `tdd-review-test` promotes from PostToolUse advisory to PreToolUse blocking.
