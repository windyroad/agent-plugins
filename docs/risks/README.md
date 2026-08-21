# Risk Catalogue

Memory aid for the risk-scorer agent: known risk classes + recogniser patterns + control-application tables + per-action modulators. Reading the catalogue at scoring time saves re-deriving them and reduces the chance of forgetting a class previously surfaced.

The catalogue is **recogniser-shaped**: each entry is optimised for the scorer's slug-match-and-paste path. Entries describe how to recognise the class on a commit's diff, which controls fire and what their band-reduction is, how to modulate likelihood for the specific action, and what the residual lands at when controls fire-and-pass.

## How the scorer uses this

1. **Recognise**: walk the diff against the slug-match quick-reference table below. Any path-pattern or diff-content-keyword match → consider the matched entry.
2. **Apply controls**: for each candidate entry, read its `## Controls` table. Identify which controls fire on THIS action; band-reduce per the table.
3. **Modulate**: adjust likelihood per the entry's `## Per-action modulators` table; composition is **max-pessimistic** (most pessimistic adjustment wins).
4. **Score**: residual = inherent_impact × (catalogue_residual_likelihood + max_pessimistic_modulator).

## Residual semantics

Catalogue residuals reflect "**controls firing-and-passing**" — i.e. the per-action lens, matching how the pipeline scorer empirically computes residual on a real action that triggered the class. This is the residual that reconciles with `.risk-reports/` outputs.

A second reading exists: `RISK-POLICY.md` `## Control Composition` strict path-counting (1/2/3+ independent paths → 1/2/3 bands). Where the two diverge, the entry calls it out (R001 has the explicit caveat). The strict reading is more conservative; the per-action reading is what the gates and scorer actually achieve.

An above-appetite catalogue residual is a real signal: even when controls fire-and-pass, the typical instance still sits above appetite. That's where additional controls (or stronger control class) are genuinely needed.

## Slug-match quick-reference

Single-pass lookup for "given this action's diff, which catalogue entries should I consider?":

| Path pattern / surface | Diff-content keywords | Triggers |
|------------------------|----------------------|----------|
| `.changeset/*.md`, `packages/*/CHANGELOG.md`, `gh issue/pr/api`, `npm publish` | revenue / pricing / client-name / user-count; financial figures with business context | **R001** |
| `*/README.md`, `*/SKILL.md`, `*/REFERENCE.md`, `docs/decisions/*`, `docs/jtbd/*`, `docs/problems/README.md`, `CLAUDE.md`, `RISK-POLICY.md` | sort-spec / tie-break / render / lifecycle suffix; ADR/JTBD/P-NNN moves | **R002** |
| `packages/*/hooks/*.sh`, `*/hooks.json`, `packages/*/hooks/lib/*.sh`, `packages/*/hooks/test/*.bats` | PreToolUse / PostToolUse / permissionDecision / additionalContext / hookSpecificOutput | **R003** |
| (state-shape) gitStatus shows ambient files in `.claude/`, `.afk-run-state/`, `/tmp/*-marker-*` | `git add -A`, `git add .`, broad-glob `git add` | **R004** |
| `.changeset/*.md` | bump-class declarations; multi-slice references | **R005** |
| `packages/*/skills/*/SKILL.md`, `packages/*/agents/*.md`, `packages/*/package.json` `files` array, `packages/*/bin/*` | `bash packages/...`; bare `ADR-NNN`/`JTBD-NNN`/`P-NNN` without `@windyroad/<plugin>:` prefix; `"files": [` array changes | **R006** |
| (prose-context) recent conversation, commit messages, ticket bodies, CLAUDE.md MANDATORY rules | "only safe if", "don't release X until", "paired with", "depends on" | **R007** |
| (any Edit/Write target — content-shape, not path-shape) | AWS / PEM / GitHub-token / Cloudflare / Netlify patterns; `api_key=` / `auth_token=` / `secret_key=` with high-entropy values | **R008** |
| `packages/*/{skills,agents,hooks,scripts}/**/*` (broadest source surface) | branch logic / regex / numeric thresholds / exit codes / signature changes | **R009** (catch-all when no specialisation matches) |
| `.changeset/*.md` declaring `patch` AND diff includes SKILL.md / agent.md / hook prose change | `: patch` declaration with semantic content shift; AskUserQuestion call shape change; Step removal/reorder in SKILL.md | **R010** |

## Stage applicability cross-index

| Risk | commit | push | release | external-comms |
|------|--------|------|---------|----------------|
| R001 | yes | yes | yes | **primary** |
| R002 | **primary** | yes | yes | no |
| R003 | yes | yes | **primary** | no |
| R004 | **primary** | yes | yes | no |
| R005 | yes | **primary** | yes | no |
| R006 | yes | yes | **primary** | no |
| R007 | yes | yes | **primary** | yes |
| R008 | **primary** | yes | yes | no |
| R009 | yes | yes | yes | no |
| R010 | yes | yes | **primary** | no |

"primary" = the layer where the risk first matters most. Use to prioritise enumeration when scoring per-layer (Layer 1 / Layer 2 / Layer 3 cumulative).

## Specialisation hierarchy

R009 (functional defects) is the bedrock catch-all. Several entries are specialisations:

```
R009 (functional defects in shipped behaviour)
├── R002 (documentation / index / cross-reference drift)
├── R003 (hook regression cascade)
├── R005 (release coordination drift)
├── R006 (publish-boundary divergence)
└── R010 (semver / backward-compat violation)
```

**Routing rule**: when a defect maps to a specialisation, score under the specialisation (its controls + modulators are sharper). R009 is the residual class for any defect that doesn't slot into one of the specialisations.

R001 + R008 are confidentiality classes (different surfaces). R004 is a state-leak class. R007 is a check, not a defect class.

## Entries

| ID | Class | Inherent | Residual | Status |
|----|-------|----------|----------|--------|
| [R001](R001-confidential-disclosure-in-outbound-prose.active.md) | Confidential / business-metric disclosure in outbound prose | 12 (High) | 3 (Low) | within ✓ |
| [R002](R002-documentation-and-index-drift.active.md) | Documentation / index / cross-reference drift across docs | 12 (High) | 6 (Medium) | above |
| [R003](R003-hook-regression-shipped-to-adopters.active.md) | Hook regression / behaviour change ships to adopters | 16 (High) | 4 (Low) | at appetite |
| [R004](R004-ambient-unstaged-state-in-commits.active.md) | Ambient unstaged state included in commits | 6 (Medium) | 2 (Very Low) | within ✓ |
| [R005](R005-release-coordination-changeset-drift.active.md) | Release-coordination / changeset queue drift | 9 (Medium) | 3 (Low) | within ✓ |
| [R006](R006-published-package-vs-source-tree-divergence.active.md) | Published-package references source-tree-only paths and IDs | 20 (Very High) | 8 (Medium) | above |
| [R007](R007-user-stated-preconditions-paired-capability.active.md) | User-stated preconditions / paired-capability check | 12 (High) | 4 (Low) | at appetite |
| [R008](R008-credentials-in-committed-files.active.md) | Credentials / secrets in committed files | 15 (High) | 5 (Medium) | above |
| [R009](R009-functional-defects-in-shipped-behaviour.active.md) | Functional defects in shipped plugin behaviour (bedrock) | 16 (High) | 8 (Medium) | above |
| [R010](R010-semver-or-backward-compatibility-violation.active.md) | Semver / backward-compatibility violation on plugin contracts | 12 (High) | 4 (Low) | at appetite |
| [R014](R014-release-pressure-wip-limit-controls-not-firing.active.md) | Release-pressure / WIP-limit controls not firing | — | — | pending review |
| [R016](R016-release-batch-r009-skill-prose-concentration-above-appetite.active.md) | Release-batch R009 skill-prose concentration above appetite | — | — | pending review |
| [R017](R017-skill-prose-class-bats-deferred-residual-above-appetite.active.md) | Skill-prose class / bats-deferred residual above appetite | — | — | pending review |
| [R018](R018-r009-bedrock-functional-defect-class-floor-medium.active.md) | R009 bedrock functional-defect class floor medium | — | — | pending review |
| [R024](R024-risk-catalog-empty-no-baseline-controls-documented.active.md) | Risk catalog empty / no baseline controls documented (obsolete — superseded by R001-R010 bootstrap) | — | — | pending review |
| [R025](R025-external-adopter-name-in-public-repo-ticket-prose.active.md) | External Adopter Name In Public Repo Ticket Prose | — | — | pending review |
| [R028](R028-jtbd-build-upon-guard-agent-prose-verdict-residual-above-appetite.active.md) | Jtbd Build Upon Guard Agent Prose Verdict Residual Above Appetite | — | — | pending review |
| [R029](R029-r009-agent-prose-verdict-surface-no-llm-harness.active.md) | R009 Agent Prose Verdict Surface No Llm Harness | — | — | pending review |
| [R035](R035-r009-prose-surface-floor-un-verified-eval-run.active.md) | R009 Prose Surface Floor Un Verified Eval Run | — | — | pending review |
| [R036](R036-p350-skill-prose-brief-before-id-no-promptfoo-coverage.active.md) | P350 Skill Prose Brief Before Id No Promptfoo Coverage | — | — | pending review |
| [R037](R037-capture-problem-skill-prose-no-promptfoo-eval.active.md) | Capture Problem Skill Prose No Promptfoo Eval | — | — | pending review |
| [R038](R038-skill-prose-amendment-multi-surface-promptfoo-coverage-gap.active.md) | Skill Prose Amendment Multi Surface Promptfoo Coverage Gap | — | — | pending review |
| [R039](R039-skill-prose-r009-floor-migrate-briefing-no-promptfoo.active.md) | Skill Prose R009 Floor Migrate Briefing No Promptfoo | — | — | pending review |
| [R040](R040-work-problems-skill-prose-floor-without-paired-promptfoo-eval.active.md) | Work Problems Skill Prose Floor Without Paired Promptfoo Eval | — | — | pending review |
| [R041](R041-external-project-handle-in-public-repo-ticket-origin-stamp.active.md) | External Project Handle In Public Repo Ticket Origin Stamp | — | — | pending review |
| [R043](R043-r009-wrapper-skill-prose-no-paired-promptfoo-eval.active.md) | R009 Wrapper Skill Prose No Paired Promptfoo Eval | — | — | pending review |
| [R044](R044-work-problems-skill-prose-no-promptfoo-coverage.active.md) | Work Problems Skill Prose No Promptfoo Coverage | — | — | pending review |
| [R045](R045-r009-skill-prose-work-problems-no-promptfoo-eval.active.md) | R009 Skill Prose Work Problems No Promptfoo Eval | — | — | pending review |
| [R046](R046-r009-skill-prose-floor-work-problems-no-promptfoo-coverage.active.md) | R009 Skill Prose Floor Work Problems No Promptfoo Coverage | — | — | pending review |
| [R047](R047-work-problems-skill-prose-floor-no-paired-promptfoo.active.md) | Work Problems Skill Prose Floor No Paired Promptfoo | — | — | pending review |
| [R049](R049-review-problems-skill-prose-floor-without-paired-promptfoo.active.md) | Review Problems Skill Prose Floor Without Paired Promptfoo | — | — | pending review |
| [R050](R050-work-problems-skill-prose-cohort-depth-7-binding-on-single-eval-slice.active.md) | Work Problems Skill Prose Cohort Depth 7 Binding On Single Eval Slice | — | — | pending review |
| [R052](R052-review-problems-skill-prose-no-promptfoo-eval.active.md) | Review Problems Skill Prose No Promptfoo Eval | — | — | pending review |
| [R053](R053-adr-skill-prose-amendment-no-paired-changeset-or-promptfoo.active.md) | Adr Skill Prose Amendment No Paired Changeset Or Promptfoo | — | — | pending review |
| [R054](R054-architect-jtbd-agent-prose-verdict-grammar-no-promptfoo-eval.active.md) | Architect Jtbd Agent Prose Verdict Grammar No Promptfoo Eval | — | — | pending review |
| [R056](R056-reconcile-readme-prose-no-promptfoo-eval.active.md) | Reconcile Readme Prose No Promptfoo Eval | — | — | pending review |
| [R057](R057-feat-commit-without-paired-changeset-phase-1-ambiguity.active.md) | Feat Commit Without Paired Changeset Phase 1 Ambiguity | — | — | pending review |
| [R058](R058-work-problems-skill-prose-floor-no-paired-promptfoo-p358.active.md) | Work Problems Skill Prose Floor No Paired Promptfoo P358 | — | — | pending review |
| [R059](R059-skill-prose-surface-push-without-paired-eval.active.md) | Skill Prose Surface Push Without Paired Eval | — | — | pending review |
| [R060](R060-skill-prose-upstream-dispatch-no-promptfoo-coverage.active.md) | Skill Prose Upstream Dispatch No Promptfoo Coverage | — | — | pending review |
| [R061](R061-catchup-migration-mode-skill-prose-no-promptfoo-coverage.active.md) | Catchup Migration Mode Skill Prose No Promptfoo Coverage | — | — | pending review |
| [R062](R062-rate-at-capture-skill-prose-no-paired-promptfoo-coverage.active.md) | Rate At Capture Skill Prose No Paired Promptfoo Coverage | — | — | pending review |
| [R063](R063-minor-bump-shipped-under-unconfirmed-oversight-adr.active.md) | Minor Bump Shipped Under Unconfirmed Oversight Adr | — | — | pending review |
| [R064](R064-adr-ratification-precondition-unmet-before-release.active.md) | Adr Ratification Precondition Unmet Before Release | — | — | pending review |
| [R065](R065-update-policy-skill-step-6a-r009-prose-floor-no-promptfoo.active.md) | Update Policy Skill Step 6A R009 Prose Floor No Promptfoo | — | — | pending review |
| [R066](R066-capture-problem-persona-adopter-corpus-prose-no-dedicated-eval.active.md) | Capture Problem Persona Adopter Corpus Prose No Dedicated Eval | — | — | pending review |
| [R067](R067-agent-prose-verdict-axis-shipped-without-promptfoo-harness.active.md) | Agent Prose Verdict Axis Shipped Without Promptfoo Harness | — | — | pending review |
| [R068](R068-work-problems-skill-prose-plugin-dir-dispatch-no-promptfoo.active.md) | Work Problems Skill Prose Plugin Dir Dispatch No Promptfoo | — | — | pending review |
| [R069](R069-r009-skill-prose-floor-undischarged-until-promptfoo-green-verified.active.md) | R009 Skill Prose Floor Undischarged Until Promptfoo Green Verified | — | — | pending review |
| [R070](R070-work-problems-skill-prose-r009-floor-cohort-depth-nine-held-on-single-eval.active.md) | Work Problems Skill Prose R009 Floor Cohort Depth Nine Held On Single Eval | — | — | pending review |
| [R071](R071-r009-i13-existing-vehicle-trace-branch-no-promptfoo-eval.active.md) | R009 I13 Existing Vehicle Trace Branch No Promptfoo Eval | — | — | pending review |
| [R072](R072-skill-prose-gate-invocation-floor-no-paired-promptfoo-for-changed-branch.active.md) | Skill Prose Gate Invocation Floor No Paired Promptfoo For Changed Branch | — | — | pending review |
| [R073](R073-adopter-name-and-usage-detail-in-public-repo-rfc-prose.active.md) | Adopter Name And Usage Detail In Public Repo Rfc Prose | — | — | pending review |
| [R074](R074-shipped-entrypoint-non-executable-mode-bit-inert.active.md) | Shipped plugin entrypoint loses its executable mode bit → inert at adopter installs | — | — | pending review |
| [R076](R076-skill-behavioural-change-shipped-without-paired-changeset.active.md) | Skill Behavioural Change Shipped Without Paired Changeset | — | — | pending review |
| [R077](R077-restore-incident-skill-prose-floor-no-promptfoo-eval.active.md) | Restore Incident Skill Prose Floor No Promptfoo Eval | — | — | pending review |
| [R078](R078-capture-adr-skill-prose-no-paired-promptfoo-eval.active.md) | Capture Adr Skill Prose No Paired Promptfoo Eval | — | — | pending review |
| [R080](R080-plugin-installer-help-text-copied-verbatim-from-sibling-package.active.md) | Plugin Installer Help Text Copied Verbatim From Sibling Package | — | — | pending review |
| [R081](R081-work-problems-step-3-6-carveout-branch-no-promptfoo-case.active.md) | Work Problems Step 3 6 Carveout Branch No Promptfoo Case | — | — | pending review |
| [R082](R082-manage-story-skill-prose-no-paired-promptfoo-eval.active.md) | Manage Story Skill Prose No Paired Promptfoo Eval | — | — | pending review |
| [R083](R083-multi-adr-lockstep-amendment-drift-no-load-bearing-detector.active.md) | Multi Adr Lockstep Amendment Drift No Load Bearing Detector | — | — | pending review |
| [R084](R084-adr-101-born-unconfirmed-ratification-drain-pending.active.md) | Adr 101 Born Unconfirmed Ratification Drain Pending | — | — | pending review |
| [R085](R085-story-implemented-while-in-draft-accepted-gate-never-fired.active.md) | Story Implemented While In Draft Accepted Gate Never Fired | — | — | pending review |
| [R086](R086-story-047-accepted-gate-unmet-before-implementation.active.md) | Story 047 Accepted Gate Unmet Before Implementation | — | — | pending review |
| [R087](R087-oversight-content-hash-ignores-body-status-mirror-false-unratified.active.md) | Oversight Content Hash Ignores Body Status Mirror False Unratified | — | — | pending review |
| [R088](R088-story-body-shape-prose-change-no-paired-promptfoo-assertion.active.md) | Story Body Shape Prose Change No Paired Promptfoo Assertion | — | — | pending review |
| [R089](R089-adopter-corpus-migration-shipped-without-self-firing-cadence.active.md) | Adopter Corpus Migration Shipped Without Self Firing Cadence | — | — | pending review |
| [R090](R090-adopter-migration-reachable-only-via-release-notes-no-cadence.active.md) | Adopter Migration Reachable Only Via Release Notes No Cadence | — | — | pending review |
| [R091](R091-full-local-suite-cannot-complete-ci-is-only-full-suite-arbiter.active.md) | Full Local Suite Cannot Complete Ci Is Only Full Suite Arbiter | — | — | pending review |
| [R092](R092-machine-wide-projection-sample-concurrency.active.md) | Machine Wide Projection Sample Concurrency | — | — | pending review |
| [R093](R093-uninspectable-pipeline-state-blocks-risk-assessment.active.md) | Uninspectable Pipeline State Blocks Risk Assessment | — | — | pending review |
| [R094](R094-release-batch-skill-prose-concentration-above-appetite.active.md) | Release Batch Skill Prose Concentration Above Appetite | — | — | pending review |
| [R095](R095-cumulative-branch-ratification-and-validation-gap.active.md) | Cumulative Branch Ratification And Validation Gap | — | — | pending review |
| [R096](R096-adr-116-ratification-precondition-unmet.active.md) | Adr 116 Ratification Precondition Unmet | — | — | pending review |
| [R097](R097-hook-regression-installed-runtime-smoke-gap.active.md) | Hook Regression Installed Runtime Smoke Gap | — | — | pending review |

> **Pending-review queue**: Remaining active auto-scaffolded entries carry ADR-026 sentinels for ungrounded scoring fields and `Status: Active (auto-scaffolded — pending review)` for downstream human curation. Obsolete release-delay and atomic-holding entries were retired when ADR-099 removed held changesets as a shipment control.

## Where we need more controls (above-appetite entries)

| ID | Residual | Why above appetite + next mitigation milestone |
|----|----------|------------------------------------------------|
| **R002** | 6 (Medium) | Some drift sub-classes (ADR-vs-ADR; sort-spec across N render-block sites) have only retro-time advisory coverage. P161 generalisation pattern adds load-bearing detectors; would drop residual to 1 → score 3 / Low. |
| **R006** | 8 (Medium) | Controls (ADR-049 shim, ADR-055 prefix, P154 detector) are mostly **advisory at retro time, not blocking at commit time**. Production evidence: `@windyroad/itil@0.23.2 → 0.24.0` shipped 5 broken-shim versions before catch. Phase-2 promotion to commit-blocking drops residual to 1 → score 4 / Low. |
| **R008** | 5 (Medium) | Impact 5 (Severe) caps residual at 5 even with Likelihood 1 (Rare). No additional detection control will drop residual below 5. Treatment: post-incident rotation-runbook readiness for WHEN-not-IF. |
| **R009** | 8 (Medium) | Bedrock class — defect-free is impossible. Coverage gaps real (skill-prose surfaces don't get behavioural-tested; ~50 legacy structural bats accepted-until-touched per ADR-052 Migration). Phase-2 retrofit + harness-maturity (P012) drop residual incrementally; floor ~6 stays. |

## Adding to the catalogue

Identifying a new class during scoring? Author it via `/wr-risk-scorer:create-risk` (interactive) or `/wr-risk-scorer:create-risk --slug <slug>` (orchestrator-driven from an ADR-056 hint).

The entry shape (per-entry sections to author): description; recogniser (path patterns + diff keywords + anti-patterns); stage applicability; inherent risk per `RISK-POLICY.md`; controls table with "if absent for THIS action" column; per-action modulators (composition: max-pessimistic); residual; watch-out; see-also. Refer to existing entries as templates — R001 / R003 are the canonical examples.

The catalogue is self-pruning: when a class stops surfacing in `.risk-reports/` (controls have made it rare), retire its entry by renaming `R<NNN>-<slug>.md` to `R<NNN>-<slug>.retired.md`. Git history preserves prior content.
