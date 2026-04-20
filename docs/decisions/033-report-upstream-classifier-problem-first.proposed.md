---
status: "proposed"
date: 2026-04-21
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-21
partially-supersedes: [024-cross-project-problem-reporting-contract]
---

# Report-upstream classifier is problem-first — supersedes ADR-024 Decision Outcome Steps 3 + 5

## Context and Problem Statement

ADR-024 (Cross-project problem-reporting contract) defined the `/wr-itil:report-upstream` skill with a classifier and structured default body modelled on the npm-ecosystem norm: **bug / feature / question** (Step 3 classifier heuristic; Step 5 default body shape). That shape was copied into the suite's own intake templates in the same drop (commit `e36cf84`, shipped as part of P055 Part A).

P066 (Intake templates split bug/feature instead of problem-first) reversed that choice for THIS repo's intake surface on 2026-04-20 (commit `ed36f69`, `@windyroad/itil@0.9.0` adjacent). The intake template is now `problem-report.yml` with fields mirroring the `/wr-itil:manage-problem` ticket shape (Description → Symptoms → Workaround → Affected plugin → Frequency → Environment → Evidence). Every adopter of the suite will inherit the problem-first shape once P065's `scaffold-intake` skill ships.

That shift makes ADR-024's Steps 3 and 5 incoherent: the classifier treats bug/feature/question as first-class shapes, and the structured default reconstitutes a bug-shaped body, while the intake template the classifier matches against is now problem-shaped. P067 flags the incoherence: an agent filing upstream from a problem-shaped local ticket has to either rewrite the prose to fit the bug-shaped default or accept misalignment.

This ADR **partially supersedes ADR-024** — only Steps 3 and 5 of Decision Outcome. Steps 1 (template discovery via `gh api`), 2 (SECURITY.md routing), 4 (security-path classification), 6 (security-path halt + disclosure routing), 7 (cross-reference back-write), 8 (ADR-014 commit), all Consequences, all Confirmation clauses, and the whole `## Reported Upstream` appendage contract remain in force. The partial-supersession pattern follows ADR-022's precedent (ADR-022 reshaped lifecycle-language from an earlier ADR without marking the predecessor superseded).

## Decision Drivers

- **JTBD-301** (Report a Problem Without Pre-Classifying It) — primary. The plugin-user persona shouldn't have to pre-classify on the way in OR on the way out. The classifier's new shape makes the skill emit what the persona's own local ticket already is (a problem).
- **JTBD-001** (Enforce Governance Without Slowing Down) — the "without slowing down" promise fails when the user has to rewrite a problem-shaped draft into a bug-shaped default before filing. The shape is now aligned by construction.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — bi-directional cross-reference preserved unchanged; the audit trail shape is the same.
- **JTBD-101** (Extend the Suite with Clear Patterns) — plugin-developer persona; the classifier's pattern now matches the intake shape P065's scaffold-intake skill will propagate downstream.
- **P066** — the intake shape change that triggered this. Must ship before this ADR's classifier reshape lands in a session. P066 is Verification Pending as of `ed36f69`.
- **P067** — the driver ticket for this ADR.

## Considered Options

1. **Sibling ADR supersedes Steps 3 + 5 only (chosen)** — matches ADR-022's precedent for partial lifecycle-language supersession. ADR-024 stays `.proposed.md`; an `## Amendments` section points at this ADR. Preserves ADR-024's Context / Drivers / Options audit trail for the ecosystem-norm framing that made sense at the time.
2. **In-place amendment of ADR-024** — rewrite Steps 3 + 5 inside ADR-024; add `amended-date` frontmatter. Rejected — ADR-024's Considered Options section reasoned from "match the npm-ecosystem norm", which is no longer the driving force. The new reasoning ("match our ITIL discipline, with ecosystem fallback") is materially different and deserves its own Context / Drivers / Options record.
3. **Full supersession of ADR-024** — rename ADR-024 to `.superseded.md`; draft a full replacement. Rejected — only 2 of 8 Decision-Outcome steps change; Context, security-path handling, back-write contract, commit discipline, and the whole ADR-024 Consequences section remain correct.
4. **Do nothing** — leave ADR-024 as-is; accept the incoherence with P066's intake shape. Rejected per P067 — the incoherence hits every non-bug upstream report and breaks JTBD-001's "without slowing down" at the moment the agent files.

## Decision Outcome

**Chosen option: Option 1** — sibling ADR partially supersedes ADR-024 Steps 3 + 5.

### Partial-supersession scope

This ADR supersedes **ADR-024 Decision Outcome Steps 3 and 5 ONLY**. The following ADR-024 sections remain in force unchanged:

- Context and Problem Statement
- Decision Drivers
- Considered Options (ecosystem-norm reasoning preserved for historical record)
- Decision Outcome Steps 1, 2, 4, 6, 7, 8
- All Consequences subsections (Good, Neutral, Bad)
- All Confirmation clauses
- `## Reported Upstream` appendage contract
- Reassessment Criteria

### Step 3 (new): Problem-first classification

The classifier reads the local ticket's title + Description + Symptoms and picks a shape from this preference order:

1. **Problem shape (primary)** — any of the tokens `problem`, `issue`, `concern`, `defect`, `gap`, or any scoped-npm package reference (`@scope/name`), or any occurrence of `root cause` / `reproduction` / `workaround` in the body.
2. **Security shape** — if ADR-024 Step 2 classified the ticket as security-sensitive, route through Step 4 security-path. Unchanged by this ADR.
3. **Bug shape (backward-compat fallback)** — if no primary tokens match and the prose looks defect-like (contains `broken`, `fails`, `error`, `bug`, `regression`, specific observed-vs-expected contrast). Produces the bug-shaped body only as a fallback for upstream repos that haven't adopted problem-first templates.
4. **Feature shape (backward-compat fallback)** — if no primary tokens match and the prose looks proposal-like (contains `would be nice`, `enhancement`, `feature request`, `could we`, `wish`). Same fallback-only use.
5. **Question shape (backward-compat fallback)** — trailing fallback when prose is a genuine question (ends in `?`, contains `how do I`, `is there a way`).

**Template-discovery preference order** (extends ADR-024 Step 1):

1. `problem-report.yml` in the upstream's `.github/ISSUE_TEMPLATE/` — preferred.
2. `problem.yml` — alternate naming for problem-shaped templates.
3. `bug-report.yml` / `bug.yml` — if primary classifier picked bug shape OR no problem template exists and fallback is bug.
4. `feature-request.yml` / `feature.yml` — feature-shape fallback.
5. `question.yml` — question-shape fallback.
6. Structured default body per Step 5 below — if no template matches.

### Step 5 (new): Problem-shaped structured default body

When no upstream template matches (or when the classifier picks problem-shape and the upstream has no `problem-report.yml`), the skill emits a structured default body with this section order:

```markdown
## Description

<one-paragraph description synthesised from the local ticket's Description section>

## Symptoms

<bullet list drawn from the local ticket's Symptoms section>

## Workaround

<from the local ticket's Workaround section; "None identified yet." if absent>

## Affected plugin / component

<inferred from the local ticket's Impact Assessment or inferred from context>

## Frequency

<from the local ticket's Impact Assessment "Frequency" line>

## Environment

<Claude Code version, OS, plugin versions — synthesised from session context or prompted>

## Evidence

<commit SHAs, test output, transcript excerpts — drawn from Investigation Tasks>

## Cross-reference

<downstream repo, downstream local ticket ID (e.g. `P067`), downstream ticket file path>
```

The body MUST include the Cross-reference section so ADR-024 Step 7's back-write contract works (the downstream ticket's `## Reported Upstream` section records the upstream URL; the upstream issue records the downstream reference).

The bug-shaped default (ADR-024's original Step 5 body: Description → Reproduction → Expected → Actual) is retained ONLY for use when Step 3's backward-compat fallback picks bug shape. Feature-shape and question-shape defaults are similarly retained for fallback use.

### Interactions with other ADRs (unchanged)

- **ADR-024 Step 4 (security-path classification)** fires before Step 3 under this ADR. Security-classified tickets bypass the classifier entirely and route to Step 6 unchanged.
- **ADR-028 (External-comms gate)** — the problem-shaped default body still passes through the voice-tone + risk/leak gates on `gh issue create`. Per ADR-028's surface list this is already in force; the body shape changes, the gate does not.
- **ADR-031 (Problem-ticket directory layout)** — the Cross-reference section's path format follows ADR-031's per-state subdirs post-migration (`docs/problems/open/NNN-<slug>.md`); pre-migration it uses the flat layout.
- **ADR-013 Rule 1** — the classifier does not fire `AskUserQuestion`; Step 4's security-path AskUserQuestion is unaffected.
- **ADR-014** — commit for this ADR's own landing follows the usual `work → score → commit` per the sibling ADR authoring flow.
- **ADR-002** — no inventory change. `report-upstream` skill identity unchanged; no new skill, no new agent.

## Consequences

### Good

- Upstream reports from problem-shaped local tickets no longer require the agent to re-shape prose. Direct JTBD-001 + JTBD-301 win.
- Preference order (problem → bug/feature/question fallback) preserves backward-compat with upstreams that haven't adopted problem-first templates yet.
- Cross-reference structured default matches the intake shape P065's scaffold-intake skill will seed downstream. Ecosystem alignment.
- Audit trail preserved: ADR-024's original reasoning stays intact; this ADR records the shift with its own Context.

### Neutral

- Skill's internal classification logic grows a preference order rather than a 3-way split. Marginal complexity increase; bounded by the 5-shape list.
- Template-discovery adds 2 extra candidate filenames (`problem-report.yml`, `problem.yml`) to the existing 3. One extra `gh api` round-trip per upstream in the worst case.

### Bad

- Two shapes now coexist in the codebase's SKILL.md fallback defaults (problem-shaped for primary; bug/feature/question-shaped for backward-compat fallback). Doubles the fallback-body-template count; bats doc-lint coverage must assert both.
- Upstream repos that HAVE a `bug-report.yml` but not `problem-report.yml` get reports via the bug template even when the local ticket is problem-shaped. The classifier's fallback preserves functionality but the shape asymmetry means the report body is re-shaped on the way out. Accepted: the alternative (force problem-shape into a bug template) produces worse intake UX on the upstream side.
- Partial-supersession creates a precedent future maintainers will reuse. Partial-supersession is slightly harder to search than full supersession (tooling greps for `superseded-by:` in frontmatter; `partially-supersedes:` is a new key). Mitigated by the explicit prose scope in this ADR's Context and the `## Amendments` pointer added to ADR-024.

## Confirmation

### Source review (at implementation time)

- `packages/itil/skills/report-upstream/SKILL.md` Step 3 rewritten with the problem-first preference order; bug/feature/question demoted to fallback.
- `packages/itil/skills/report-upstream/SKILL.md` Step 5 default body has a problem-shaped template (as above) AND retains the bug/feature/question bodies as fallback-only.
- Template-discovery step (ADR-024 Step 1 extended) searches for `problem-report.yml` and `problem.yml` before `bug-report.yml` / `feature-request.yml` / `question.yml`.
- `packages/itil/skills/report-upstream/SKILL.md` cites this ADR (ADR-033) as the authority for Steps 3 and 5.
- `docs/decisions/024-cross-project-problem-reporting-contract.proposed.md` carries an `## Amendments` section near the top referencing this ADR with the specific step numbers carved out.
- `packages/itil/skills/report-upstream/SKILL.md` cites ADR-033 in its Related section alongside the existing ADR-024 citation.

### Bats structural tests

- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` (extended) — asserts:
  - Problem-first classifier tokens are documented in Step 3.
  - Bug/feature/question fallback tokens retained.
  - Problem-shaped structured default body section order matches this ADR's Step 5 specification (Description / Symptoms / Workaround / Affected plugin / Frequency / Environment / Evidence / Cross-reference).
  - Template-discovery preference order cites `problem-report.yml` first.
  - ADR-033 cited in SKILL.md's Related section.

### Cross-reference to ADR-024

ADR-024 `## Amendments` section at file top (sample):

```markdown
## Amendments

- **2026-04-21** — Decision Outcome Steps 3 and 5 superseded by ADR-033 (Report-upstream classifier is problem-first). The classifier's preference order and the structured default body shape are now governed by ADR-033; the rest of ADR-024's Decision Outcome (Steps 1, 2, 4, 6, 7, 8) and all Consequences remain in force.
```

## Pros and Cons of the Options

### Option 1: Sibling ADR partially supersedes Steps 3 + 5 (chosen)

- Good: preserves ADR-024's audit trail; reasoning for the ecosystem-norm framing stays accessible.
- Good: ADR-022 precedent already established for partial-lifecycle-language supersession.
- Good: ADR-024 stays `.proposed.md`; lifecycle untouched.
- Bad: introduces `partially-supersedes:` as a new frontmatter key; future tooling must learn it.

### Option 2: In-place amendment of ADR-024

- Good: one file, one decision record; no new frontmatter key.
- Bad: loses the ecosystem-norm-vs-ITIL-discipline reasoning shift as a first-class audit record.
- Bad: changes ADR-024's content without versioning the change; readers lose the "why" of the shift.

### Option 3: Full supersession of ADR-024

- Good: simplest audit path; one ADR is the authority.
- Bad: 6 of 8 Decision Outcome steps carry over unchanged; full-supersession is overkill.
- Bad: drafting a full replacement duplicates ADR-024's Context / Drivers / Options that are still correct.

### Option 4: Do nothing

- Good: zero effort.
- Bad: classifier incoherence with P066's intake shape; JTBD-001 + JTBD-301 regression on every non-bug upstream report.

## Reassessment Criteria

Revisit this decision if:

- Upstream repos widely adopt problem-first templates and the bug/feature/question fallback paths sit unused for 6+ months. Consider deprecating the fallbacks and simplifying the classifier.
- Conversely, if the primary classifier misfires frequently (false-positive rate exceeds ~10% — measured by user overrides of the auto-picked shape), revisit the token list.
- A new intake shape emerges in the ecosystem (e.g. GitHub introduces a "problem" issue form type natively). Revisit template-discovery preference order.
- `partially-supersedes:` frontmatter proves difficult for tooling to consume. Revisit as a wider ADR-management pattern if second and third partial-supersessions emerge.
- ADR-024 itself gets superseded. At that point this ADR's partial-supersession dissolves into the new ADR.

## Related

- **ADR-024** (Cross-project problem-reporting contract) — partially superseded by this ADR (Steps 3 + 5 only).
- **ADR-022** (Problem lifecycle Verification Pending) — precedent for partial-lifecycle-language supersession pattern.
- **ADR-028** (External-comms gate, amended 2026-04-21) — problem-shaped default body still passes through the voice-tone + risk/leak gates on `gh issue create`.
- **ADR-031** (Problem-ticket directory layout) — Cross-reference section path format depends on this ADR's migration state.
- **ADR-013** (Structured user interaction) — Rule 1 unaffected; classifier does not fire AskUserQuestion.
- **ADR-014** (Governance skills commit their own work) — landing commit of this ADR + SKILL.md edits + bats test updates follows standard work → score → commit.
- **ADR-002** (Monorepo per-plugin packages) — no inventory change required.
- **P067** — driver ticket for this ADR.
- **P066** — ships the intake shape this ADR aligns with (Verification Pending, commit `ed36f69`). Must ship before or with this ADR.
- **P065** — scaffold-intake skill; downstream propagation of the problem-first shape to adopter repos.
- **JTBD-301** (Report a Problem Without Pre-Classifying It) — primary beneficiary.
- **JTBD-001** (Enforce Governance Without Slowing Down), **JTBD-101** (Extend the Suite with New Plugins), **JTBD-201** (Restore Service Fast with an Audit Trail) — secondary beneficiaries.
- `packages/itil/skills/report-upstream/SKILL.md` — target of the Steps 3 + 5 rewrite.
- `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — target of the bats-coverage extension.
