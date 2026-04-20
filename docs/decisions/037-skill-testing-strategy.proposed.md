---
status: "proposed"
date: 2026-04-21
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-21
---

# Skill testing strategy — contract-assertion bats companion to ADR-005

## Context and Problem Statement

ADR-005 (Plugin testing strategy) sanctions `bats-core` for **hook** shell scripts under `packages/<plugin>/hooks/test/`. Skills — the markdown documents Claude interprets at runtime — have no testing contract of their own. ADR-011's `manage-incident` rollout hit this gap: the architect flagged skill tests as an Undocumented Decision and the skill shipped with an Option-A-lite holding pattern (execute embedded bash fragments + mocked Skill-tool handoff) under `packages/itil/skills/manage-incident/test/`.

Since then, several skill `.bats` files have landed that assert SKILL.md structural invariants: frontmatter shape, required sections, cited ADRs, allowed-tools lists, step numbering. Exemplars: `report-upstream-contract.bats` (ADR-024 confirmation-criteria assertions), `manage-problem-output-formatting.bats`, `run-retro-verification-close-housekeeping.bats` (ADR-032 deferred-question contract assertions), `manage-problem-external-root-cause-detection.bats` (ADR-013 Rule 1/6 compliance). The pattern works; it is not codified as a decision.

P012 (Skill testing harness scope undefined) pinned the companion-ADR direction on 2026-04-20. The user's direction: skills differ enough from hooks (LLM-interpreted prose vs executable bash) that the testing strategy deserves its own decision record. This ADR is that record.

**Architect review (2026-04-21) surfaced three must-address gaps before landing**:
1. Evaluate Anthropic's `skill-creator` eval harness (dual-run with/without skill, grader subagent, `evals.json`, benchmark aggregation) as a first-class considered option. P012 investigation tasks explicitly flag this as load-bearing prior art.
2. Frame SKILL.md as a **contract document** (like `hooks.json` in ADR-005). Contract-assertions (section X exists, ADR-N cited, `allowed-tools` contains Y) are structurally distinct from the P011 source-grep ban, which targets behavioural claims about code paths. Without this framing the pattern operates in a grey zone.
3. Do not mark runtime-skill-testing permanently out of scope. Reject for now with named reassessment triggers. ADR-005's own reassessment criterion ("If Claude Code adds a way to test agent behavior programmatically") is arguably already met by the skill-creator harness existing upstream.

## Decision Drivers

- **JTBD-002** (Ship AI-Assisted Code with Confidence) — primary. Every skill gets a structural-contract gate before release; skill contracts can't silently drift.
- **JTBD-101** (Extend the Suite with New Plugins) — plugin-developer "clear patterns, not reverse-engineering". ADR-037 names the canonical file location, naming convention, and helper library for skill tests. No plugin author reinvents the approach.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — tech-lead auditability. CI-visible pass/fail evidence per skill; contract drift is caught before it reaches users.
- **P012** — driver ticket.
- **ADR-005** — hook-testing companion; this ADR does NOT supersede it. Scope partition: ADR-005 owns hooks; ADR-037 owns skills.
- **ADR-011** — `manage-incident` holding pattern; this ADR subsumes that into the formal structure.
- **ADR-025** — test content quality review (concreteness + traceability). Applies to skill bats content equally; `@jtbd JTBD-NNN` / `@problem P-NNN` traceability on skill-test assertions.
- **ADR-026** — agent output grounding. When a skill bats asserts quantitative claims embedded in a SKILL.md, the claim itself must be ADR-026-grounded; the bats assertion is a persist-surface observation.
- **ADR-035** — centralised review reports; skill bats assertion outcomes (PASS/FAIL) become one class of reviewer-agent verdict persisted under ADR-035 once review-reports land.
- **Anthropic `skill-creator` harness** (2026 prior art) — considered; rejected for now (see Considered Options). Named reassessment trigger.

## Considered Options

1. **Contract-assertion bats for every skill; runtime testing out-of-scope with reassessment triggers (chosen)** — every skill ships at least one `<skill>-contract.bats` asserting SKILL.md structural invariants. Helpers at `packages/shared/test/skill-test-helpers.bash`. Per-invariant splitting allowed when the contract surface is large (precedent: `manage-problem/test/` has 9 bats files). Anthropic skill-creator harness evaluated and deferred. ADR-005 unchanged in its hook-testing authority; the two ADRs coexist via scope partition.

2. **Adopt Anthropic skill-creator eval harness** — full dual-run grader-subagent evaluation with `evals.json`, `benchmark.json`, pass_rate aggregation, `with_skill` / `without_skill` / `old_skill` workspace layout, HTML review UI. Runtime-exercised skills against ground-truth assertions.

3. **ADR-005 amendment (not companion ADR)** — extend ADR-005's "Permitted exceptions" clause to cover SKILL.md contract-assertions.

4. **No formal skill-testing contract (status quo)** — continue the ad-hoc pattern; each new skill's author decides independently.

5. **Delegation-based test only** — assert that each skill's SKILL.md declares the correct subagent / tool delegations (ADR-032) and leave the rest to live-session feedback loops.

## Decision Outcome

**Chosen option: Option 1** — contract-assertion bats as the sanctioned approach; runtime-skill-testing rejected for now with reassessment triggers.

### SKILL.md as a contract document

SKILL.md is a **contract document**, semantically equivalent in this framing to `hooks.json` under ADR-005. Its content is a contract between the skill's author and the agent that interprets it at runtime. Contract-assertions — "section `## Step 4a Verification-close housekeeping` exists", "ADR-032 is cited in Related", "`allowed-tools` frontmatter contains `AskUserQuestion`", "the stable marker string `- **Upstream report pending** —` appears verbatim" — are **structural checks on the contract**, not source-greps asserting behavioural claims about interpreted code paths.

This distinction draws the line between permitted and forbidden assertions:

- **Permitted (contract-assertion)**: "SKILL.md contains section X"; "SKILL.md cites ADR-N by ID"; "SKILL.md frontmatter declares `<field>: <value>`"; "SKILL.md's Operations table row Y carries marker text Z verbatim"; "SKILL.md lists all N expected option shapes for the `AskUserQuestion` described in the contract".
- **Forbidden (behavioural / source-grep per P011)**: "the `bash` heuristic at lines 45-50 uses regex R"; "the classifier prefers token T over token U when both appear" (a behavioural claim about how the LLM will interpret the prose); "the skill will NEVER call `Agent(run_in_background: true)` unless Step 0 is present" (an interpreter-behaviour claim).

The test of "is this a contract-assertion?" is: **does this assertion fire against a string the contract authoritatively pins, or does it fire against a behavioural claim about how the contract will be interpreted?** Only the first is permitted under ADR-037.

ADR-025 § Confirmation criterion 6's test-file annotation-vs-behavioural-grep carve-out extends naturally: test assertions grep SKILL.md for declared contract content, not for imagined runtime behaviour.

### File location and naming

- **Canonical location**: `packages/<plugin>/skills/<skill>/test/`.
- **Canonical file name**: at least one `<skill>-contract.bats` per skill asserting the baseline structural invariants (SKILL.md exists, frontmatter valid, cited ADRs present).
- **Per-invariant splitting permitted**: when a skill's contract surface is large, multiple `.bats` files may split the assertions by invariant family (precedent: `manage-problem/test/` ships 9 bats files covering output-formatting, concern-boundary, next-id-origin-lookup, external-root-cause-detection, readme-refresh-on-transition, verification-detection, effort-buckets, no-prose-options, parked-and-cache). The contract naming establishes the entry point; splitting follows natural invariant boundaries.
- **Shared helpers**: `packages/shared/test/skill-test-helpers.bash` (NEW — ships as part of P012 execution). Common assertions: `skill_md_exists`, `skill_cites_adr`, `skill_has_section`, `skill_frontmatter_field_equals`, `skill_cites_problem`, `skill_allowed_tools_contains`. Helper file synced via ADR-017 pattern.

### Scope partition with ADR-005

- **ADR-005** remains authoritative for **hook testing** (`hooks/test/*.bats`). Its "Permitted exceptions" clause (structural assertions on `hooks.json` etc.) is unchanged.
- **ADR-037** is authoritative for **skill testing** (`skills/<skill>/test/*.bats`). Its contract-assertion framing parallels ADR-005's `hooks.json` exceptions.
- **Shared**: both ADRs inherit the P011 source-grep ban ("behavioural assertions must be functional, not source-grep"). Contract-assertions are NOT source-greps for P011's purposes.
- **ADR-005 gets `[Reassessment Triggered]`** flag per P012 investigation task. ADR-005's reassessment criterion ("If Claude Code adds a way to test agent behavior programmatically") is arguably met by the Anthropic skill-creator harness existing upstream. The trigger flag signals that ADR-005's Reassessment Criteria should be re-read when ADR-037 ships; a separate commit does the reassessment if needed.

### Retrofit plan (execution under P012)

- Enumerate skills missing `<skill>-contract.bats`: `manage-incident`, `create-adr`, `scaffold-intake` (once ADR-036 ships), `capture-problem` / `capture-retro` / `capture-adr` (once ADR-032 ships), `update-guide` (voice-tone / style-guide / jtbd / risk-scorer variants), `review-history` (once ADR-035 ships), `send` / `setup` (connect), `configure` / `access` (discord), `c4:check` / `c4:generate`, `wardley:generate`.
- Phase retrofit by plugin: each plugin's next release includes contract bats for its skills. ADR-014 commit discipline applies.
- Existing exemplars (`report-upstream-contract.bats`, `manage-problem-*.bats`, `run-retro-verification-close-housekeeping.bats`, `manage-problem-external-root-cause-detection.bats`) become the template library.

### Anthropic skill-creator harness — considered and deferred

The `skill-creator` harness from the official Claude plugins repo exercises skills via:

- `evals/evals.json` — per-skill prompt corpus with `assertions` arrays.
- Dual-run: spawn two subagents in the same turn (with-skill + without-skill); optional `old_skill` snapshot for improvement-delta.
- Grader subagent (`agents/grader.md`) scores outputs against assertions.
- Analyzer subagent (`agents/analyzer.md`) aggregates patterns.
- `scripts/aggregate_benchmark` → `benchmark.json` / `benchmark.md` with pass_rate, time, tokens, mean ± stddev, delta.
- HTML review UI (`eval-viewer/generate_review.py`, `--static` for headless CI).
- Workspace: `<skill>-workspace/iteration-N/eval-<name>/{with_skill,without_skill,old_skill}/outputs/`.

**Deferred for now.** Reasons:

- Harness runtime is substantial: each eval case is a full dual-run subagent invocation with token cost; aggregation requires grader + analyzer subagents. Total cost per skill-test run is order-of-magnitude more than contract-assertion bats (which run in ≤ 5s per skill).
- Grader subagent authorship is itself a skill-development effort (grader prompts, assertion library, domain-specific "what does a good output look like"). For 15+ skills in the suite, grader authorship is the XL half of P012's effort — bigger than the contract-assertion layer.
- Contract-assertion bats catches the high-leverage failure modes (contract drift, missing sections, stale ADR citations) at low cost. Runtime testing catches a qualitatively-different failure mode (the skill's prose produces wrong outputs); valuable but orthogonal.
- Integration with `packages/shared/test/` and `npm test` is already established for bats; adopting skill-creator is a new tool surface.

**Reassessment triggers for adopting skill-creator (or a variant)**:

- Anthropic's skill-creator harness stabilises with a public, non-internal API.
- A second plugin reaches the "mocked handoff is insufficient" failure mode documented for `manage-incident` (ADR-011 Option A-lite).
- A skill ships a correctness regression that contract-assertion bats could not have caught, AND the cost of adopting the harness is lower than the recurrence cost of the regression class.
- ADR-035's centralised review-reports data (`~/.claude/review-reports/`) accumulates real-world skill outputs usable as ground-truth eval inputs — this would significantly lower the grader-authorship cost, which is currently the blocker.
- The suite ships ≥ 20 skills (vs the current ~12–15) and contract-assertion bats alone proves insufficient for catching inter-skill integration regressions.

### Interaction with ADR-025

ADR-025 (Test content quality review) governs the **content** of test files: concreteness invariants, `@jtbd` / `@problem` traceability citations, specific-input/specific-output quadruplets. Skill bats files inherit ADR-025 contracts in full:

- Skill bats assertions MUST cite a JTBD (`@jtbd JTBD-NNN`) or Problem ticket (`@problem P-NNN`) in the test description or surrounding comments.
- Assertions MUST be concrete (`run grep -F -- '<exact substring>' "$SKILL_MD"; [ "$status" -eq 0 ]`) — not abstract (`assert_contains_something`).
- Cross-cutting test cases (concreteness-check across all skills) cite the relevant problem ticket (P012 for this ADR's retrofit layer; P010 for naming convention).

### Interaction with ADR-010 amended (skill-split naming, P071)

ADR-010's "Skill Granularity" amendment requires one skill per distinct user intent. Skill contract-bats files assert that the Operations table in each SKILL.md does not contain argumented subcommands (per the amended Confirmation criterion). This assertion is shared across every skill's contract bats and lives in the `skill-test-helpers.bash` helper library.

### Interaction with ADR-032 (governance skill invocation patterns)

ADR-032 introduces the background-capture pattern + deferred-question resumption contract. Capture-* skills under ADR-032 inherit the same contract-assertion scheme: `<capture-skill>-contract.bats` asserts the background-pattern clause, Rule 6 audit section, deferred-question artefact path, and cross-reference to ADR-032.

## Scope

### In scope (this ADR)

- Contract-assertion framing for SKILL.md ("SKILL.md is a contract document").
- Canonical file location + naming convention (`<skill>-contract.bats`).
- Per-invariant splitting policy (permitted; exemplar-based).
- Shared helper library at `packages/shared/test/skill-test-helpers.bash` + ADR-017 sync pattern.
- ADR-005 `[Reassessment Triggered]` flag (separate commit can do the reassessment if ADR-005 needs updating).
- Retrofit plan (tracked under P012 execution).
- Anthropic skill-creator harness evaluation + reassessment triggers.
- ADR-025 + ADR-010 amended + ADR-032 inheritance contracts.

### Out of scope (follow-up tickets or future ADRs)

- Runtime-exercised skill testing (the skill-creator harness pattern). Deferred with reassessment triggers listed above.
- Cross-plugin integration tests (skill-A invoking skill-B behaviour). Current bats suite covers isolated-skill contracts; cross-skill integration remains manual.
- Performance testing of skill invocation (token cost, time-to-first-output). ADR-023 performance review scope; not in ADR-037.
- Plugin-manifest drift tests (declared-skill-vs-actual-directory) — ADR-021 covers plugin-manifest version-sync; skill-identity drift is a neighbouring surface that may warrant its own check.
- Golden-output regression tests (snapshot skill output against frozen fixtures). Relies on runtime exercise; deferred with runtime-skill-testing.

## Consequences

### Good

- P012 closes at design level. Every `@windyroad/*` skill has a sanctioned testing path.
- ADR-005's hook-testing authority is preserved; companion ADR avoids supersession-overhead.
- Contract-assertion framing gives plugin authors a clear line between permitted and forbidden assertions. P011 source-grep ban preserved.
- Shared helper library centralises common assertions; future plugins get the helpers for free per ADR-017 sync.
- Skill-creator harness evaluation is documented with named reassessment triggers — future adoption isn't starting from zero.
- ADR-025 traceability + ADR-010 amended + ADR-032 / ADR-035 / ADR-036 interactions captured; skill tests are integrated, not siloed.

### Neutral

- Every new skill now requires at least one contract bats file. Author cost per skill: ~15-30 min for the baseline invariants. Acceptable.
- Retrofit touches ~10-15 existing skills. Phased under P012 execution; no single-commit blast radius.
- `packages/shared/test/skill-test-helpers.bash` adds a new sync target under ADR-017; CI drift check `check:skill-test-helpers` mirrors `check:install-utils`.

### Bad

- **Contract-assertion framing has a grey-zone edge**: "does this assertion fire against a contract string or a behavioural claim?" can be ambiguous for complex clauses (conditional logic in SKILL.md, multi-option AskUserQuestion shapes). Plugin authors may over-assert ("the classifier WILL pick token T"). Mitigated by architect review at first-draft time + the worked-example exemplars cited above.
- **Runtime regression class goes uncaught**: a skill whose prose is semantically drifted but structurally correct (e.g. SKILL.md cites the right ADR, has the right sections, but the prose instructs Claude incorrectly) passes contract bats. Mitigated by the skill's review-reports audit trail (ADR-035) and by reassessment-triggers-for-adopting-harness if the class becomes recurrent.
- **Retrofit surface is broad**: 10-15 skills × at least one contract.bats each = ~10-15 new test files across ~8 plugins. Acceptable as a phased rollout; ADR-037 doesn't gate current releases on retrofit completion.
- **Skill-creator deferral leaves prior art unused**: Anthropic's harness is already usable; deferring it means the Windy Road suite won't catch runtime regressions the harness could. Mitigated by the explicit reassessment-triggers list — this is a "not yet" not a "never".
- **Helper-library drift risk**: if `packages/shared/test/skill-test-helpers.bash` diverges from its synced copies, skill tests fail inconsistently across plugins. Mitigated by the `check:skill-test-helpers` CI drift check.

## Confirmation

### Source review (at implementation time, phased under P012)

- `packages/shared/test/skill-test-helpers.bash` exists with the baseline assertion library (SKILL.md-exists, cites-ADR, has-section, frontmatter-field-equals, cites-problem, allowed-tools-contains).
- Per-skill `<skill>-contract.bats` exists for every skill in every `@windyroad/*` plugin. Retrofit tracked under P012.
- Each contract bats asserts: SKILL.md file path exists; frontmatter `name:` matches the skill directory; at least one ADR is cited in Related; the ADR-010 amended skill-granularity rule is respected (no argument-subcommand without `deprecated-arguments: true` frontmatter).
- ADR-005 gets a `[Reassessment Triggered]` flag in its Reassessment Criteria section with a pointer to ADR-037.

### Structural bats assertions (cross-plugin)

- `packages/shared/test/skill-contract-coverage.bats` — enumerates every `packages/*/skills/*/SKILL.md` and asserts a sibling `<skill>-contract.bats` exists. Fails on any skill missing coverage. Phased: temporary allowlist of skills pending retrofit during Phase 1; allowlist removed at Phase 2 closure.
- `packages/shared/test/skill-test-helpers-sync.bats` — ADR-017 drift check for the shared helper file across consumers (if the helper is distributed via sync rather than central-sourced).
- Contract bats MUST use the shared helpers where available (enforced by a lint check: no direct `grep -F` on SKILL.md when a helper exists).

### Behavioural replay (for plugin authors, at each new skill ship)

1. Author writes SKILL.md.
2. Author writes `<skill>-contract.bats` using the shared helpers.
3. `npm test` runs; the contract bats passes.
4. Architect review validates the bats assertions fit the contract-assertion framing (not source-greps).
5. `<plugin>.claude-plugin/plugin.json` declares the new skill; the skill-contract-coverage bats picks it up on next run.

### ADR-025 concreteness + traceability inheritance

- Every contract bats asserts concretely (exact substring, exact frontmatter value) — no abstract truthiness.
- Every contract bats cites `@problem P-NNN` or `@jtbd JTBD-NNN` in the file header or test description where the assertion is not self-evidently tied to the skill's own SKILL.md.

## Pros and Cons of the Options

### Option 1: Contract-assertion bats + runtime-testing deferred with triggers (chosen)

- Good: low cost per skill; integrates cleanly with existing bats + `npm test`; preserves ADR-005's P011 source-grep ban via contract-assertion carve-out; shared helpers reduce author effort; plugin authors get a repeatable pattern.
- Bad: runtime regressions uncaught (semantic drift in prose that passes structure); grey-zone edge cases in "is this a contract-assertion?".

### Option 2: Adopt Anthropic skill-creator eval harness

- Good: catches the behavioural-drift class that Option 1 misses; dual-run grader-subagent is the industry prior-art; benchmark aggregation produces signal beyond pass/fail.
- Bad: grader-subagent authorship is itself ~1/2 of P012's XL scope; runtime cost per eval is substantial (dual subagent invocations + grader); CI integration requires new tooling; Anthropic harness is currently internal-facing (non-stable API); workspace layout and tooling stack is a new adoption surface.

### Option 3: ADR-005 amendment

- Good: one ADR instead of two.
- Bad: ADR-005's scope is hooks (executable bash); extending it to skills (LLM-interpreted prose) conflates two surfaces; companion ADR is the cleaner shape per P012 pinned direction.

### Option 4: Status quo (no formal contract)

- Good: zero effort.
- Bad: P012 open; new skill authors re-derive the pattern; contract drift goes uncaught.

### Option 5: Delegation-based test only

- Good: easy to assert ("skill declares subagent X as its handoff target").
- Bad: doesn't catch non-delegation contract drift (SKILL.md section drops, ADR citation goes stale, option-list in AskUserQuestion breaks the 4-cap).

## Reassessment Criteria

Revisit this decision if:

- Anthropic's skill-creator harness ships a public, stable API — adoption cost drops sharply; evaluate Option 2 again.
- A second plugin hits the ADR-011 "mocked handoff is insufficient" failure mode — Option A-lite patterns accumulate; harness becomes worth the cost.
- A skill ships a correctness regression that contract-assertion bats could not have caught AND the regression's cost exceeds the harness adoption cost. Track with a specific problem-ticket citation before triggering.
- ADR-035 centralised review-reports data becomes rich enough to ground grader subagents (real-world skill outputs as ground-truth) — lowers the grader-authorship barrier substantially.
- The suite ships ≥ 20 skills and cross-skill integration regressions emerge.
- Contract-assertion grey-zone friction becomes a recurring architect-review load (authors repeatedly over-assert behavioural claims). Signal: refine the framing or add a lint check for forbidden assertion shapes.
- `packages/shared/test/skill-test-helpers.bash` drift proves recurrent — may warrant a stricter distribution model.

## Related

- **P012** — driver ticket; execution tracks here.
- **ADR-005** (Plugin testing strategy) — hook-testing companion. Gets `[Reassessment Triggered]` flag.
- **ADR-010 amended** (skill-split naming, P071) — contract bats inherit the skill-granularity rule.
- **ADR-011** (manage-incident skill) — Option A-lite holding pattern subsumed here.
- **ADR-017** (Shared code sync pattern) — helper library distribution model.
- **ADR-025** (Test content quality review) — concreteness + traceability inheritance.
- **ADR-026** (Agent output grounding) — if contract bats asserts quantitative claims, ADR-026 grounding applies.
- **ADR-032** (Governance skill invocation patterns) — capture-* skills inherit background-pattern clause contract.
- **ADR-035** (Centralised review reports) — skill bats assertion outcomes persistable as reviewer-agent verdicts; also provides real-world data for future runtime-harness adoption.
- **ADR-036** (Scaffold downstream OSS intake) — scaffold-intake skill will ship with contract bats per this ADR.
- **P011** — source-grep ban on behavioural assertions; preserved by the contract-assertion carve-out.
- **P034** (Centralised review reports) — data substrate for future harness adoption.
- **P017** — multi-decision split rule; this ADR stays single-decision (skill-testing contract).
- Anthropic `skill-creator` harness — https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/skills/skill-creator/SKILL.md — prior art for runtime skill testing.
- **JTBD-002**, **JTBD-101**, **JTBD-201** — personas whose needs drive this ADR.
- `packages/shared/test/skill-test-helpers.bash` (future) — helper library.
- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — template exemplar (matches this ADR's naming + framing).
- `packages/itil/skills/manage-problem/test/*.bats` — per-invariant splitting exemplar.
