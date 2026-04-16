---
status: "proposed"
date: 2026-04-16
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2026-10-16
---

# Governance Skills Commit Their Own Completed Work

## Context and Problem Statement

Governance skills (manage-problem, manage-incident, create-adr, run-retro, update-guide) currently end with "Do not commit. The user will commit when ready." This instruction leaves completed work uncommitted in the working tree, which creates three problems:

1. **Pipeline invisibility.** Uncommitted changes are not assessed by `wr-risk-scorer:wip` or the commit-gate hook. The risk pipeline cannot score what it cannot see.
2. **Loss risk.** If a session ends unexpectedly, all uncommitted governance artefact changes are lost — no git recovery, no audit trail.
3. **WIP accumulation.** Multiple skill operations in a session stack up as uncommitted changes. The lean release principle (minimise WIP dwell time) is violated on every skill invocation.

The commit gate hook (`packages/risk-scorer/hooks/risk-score-commit-gate.sh`) blocks `git commit` unless a risk-scorer bypass marker exists. A skill that auto-commits must therefore obtain a score before committing — establishing the ordering constraint `work → score → commit`.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — manual commit steps add friction; the "no manual step needed" desired outcome applies equally to commit steps
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — "every commit has been through risk scoring" presupposes that commits actually happen; uncommitted work is invisible to the pipeline
- **Lean release principle** — minimise WIP dwell time; completed work should flow to the pipeline immediately
- **ADR-013** (Structured User Interaction) — above-appetite decisions require `AskUserQuestion`, not prose; this ADR extends that rule to the commit-gate branch point
- **P023** — open problem this ADR resolves

## Considered Options

### Option A: Skills commit autonomously (chosen)

Skills instruct the primary agent to commit after completing each discrete unit of work, using the ordering: `work → score via wr-risk-scorer:pipeline → commit`. If the risk score is above appetite, the skill presents an `AskUserQuestion` before committing. Non-interactive fail-safe per ADR-013 Rule 6: skip commit and report clearly if `AskUserQuestion` is unavailable.

### Option B: Skills stage but leave commit to the user (status quo)

Keep "Do not commit. The user will commit when ready." Skills produce files; the user decides when to commit.

### Option C: Structured commit-ready summary handed off to a separate commit skill

Skills produce a machine-readable commit-ready payload. A separate `/commit-governance` skill handles scoring and committing. Skills remain commit-agnostic.

## Pros and Cons of the Options

### Option A: Skills commit autonomously

**Pros:**
- Completed work enters the pipeline immediately — no WIP accumulation
- Audit trail created at the moment of completion, not later
- Eliminates a manual step that adds no quality benefit (quality checks happen inside the skill, before the commit instruction)
- Consistent with how non-governance work flows (developers commit after completing a unit of work)
- Above-appetite branch uses `AskUserQuestion` (ADR-013 compliant), making the decision structured and auditable

**Cons:**
- Introduces a sequencing dependency between any governance skill and `wr-risk-scorer:pipeline`
- A failed risk assessment above appetite requires an explicit user decision mid-skill-run
- Non-interactive contexts (CI, scheduled triggers) must handle the `AskUserQuestion` fail-safe path

### Option B: Stage but leave commit to user (status quo)

**Pros:**
- No new dependencies between skills and risk-scorer
- User retains full control over commit timing
- No risk of above-appetite work being committed without explicit acknowledgement

**Cons:**
- Directly violates the lean release principle — WIP accumulates across multiple skill operations
- Uncommitted work is invisible to the risk pipeline until the user manually commits
- Session-end data loss risk
- Requires the user to remember to commit after each skill operation — easy to forget under time pressure (incidents, retros)

### Option C: Separate commit skill

**Pros:**
- Skills remain single-responsibility (produce artefacts, not pipeline actions)
- Centralises commit-gate interaction in one place

**Cons:**
- Adds a second skill invocation step after every governance skill run — more friction, not less
- The "separate commit skill" is itself a manual step the user must remember
- Effectively the same as Option B from the user's perspective

## Decision Outcome

**Option A is chosen.** The reduction in WIP dwell time and pipeline visibility improvements outweigh the added skill–risk-scorer sequencing dependency.

### Scope

**In scope (this ADR):**
- `packages/itil/skills/manage-problem/SKILL.md`
- `packages/itil/skills/manage-incident/SKILL.md`

**Out of scope for now (to be addressed when those skills are worked):**
- `packages/architect/skills/create-adr/SKILL.md`
- `packages/retrospective/skills/run-retro/SKILL.md`
- `packages/jtbd/skills/update-guide/SKILL.md`
- `packages/risk-scorer/skills/update-policy/SKILL.md`

### Ordering Constraint

All in-scope skills MUST instruct the primary agent to follow this sequence when committing:

1. Stage the completed files with `git add`
2. Delegate to `wr-risk-scorer:pipeline` (subagent_type: `wr-risk-scorer:pipeline`) to assess the staged changes
3. If all scores are within appetite (`RISK_BYPASS: reducing` or score ≤ 4): commit using `git commit`
4. If any score is above appetite: use `AskUserQuestion` to ask the user whether to commit anyway, remediate first, or park the work. Per ADR-013 Rule 6, if `AskUserQuestion` is unavailable, skip the commit and report the uncommitted state clearly in the response.

### Commit Message Convention

| Operation | Format | Example |
|-----------|--------|---------|
| New problem created | `docs(problems): open P<NNN> <title>` | `docs(problems): open P025 foo-bar-baz` |
| Transition to Known Error | `docs(problems): P<NNN> known error — <root cause summary>` | `docs(problems): P023 known error — skills emit no-commit instruction` |
| Problem closed | `docs(problems): close P<NNN> <title>` | `docs(problems): close P023 governance-skills-commit` |
| Review / WSJF re-rank | `docs(problems): review — re-rank priorities` | _(literal)_ |
| Fix implemented (with problem transition) | `fix(<scope>): <description> (closes P<NNN>)` | `fix(itil): remove no-commit instruction (closes P023)` |
| New incident opened | `docs(incidents): open I<NNN> <title>` | `docs(incidents): open I004 login-500s` |
| Incident mitigated | `docs(incidents): I<NNN> mitigated — <mitigation summary>` | `docs(incidents): I004 mitigated — feature flag off` |
| Incident restored | `docs(incidents): I<NNN> restored — <action>` | `docs(incidents): I004 restored — rollback v1.4.3` |
| Incident closed | `docs(incidents): close I<NNN>` | `docs(incidents): close I004` |

All commit messages must follow the conventional-commit format (`<type>(<scope>): <description>`) and reference the problem or incident ID.

### Non-Interactive Fail-Safe

When `AskUserQuestion` is unavailable (non-interactive context, `--channels` flag, CI):
- If risk is within appetite: proceed to commit silently
- If risk is above appetite: skip the commit, clearly report "Commit skipped — risk above appetite and user confirmation unavailable. Stage and commit manually when ready."

## Confirmation

- [ ] `packages/itil/skills/manage-problem/SKILL.md` contains no "Do not commit" instruction
- [ ] `packages/itil/skills/manage-incident/SKILL.md` contains no "Do not commit" instruction
- [ ] `packages/itil/skills/manage-problem/SKILL.md` contains the `work → score → commit` ordering sequence
- [ ] `packages/itil/skills/manage-incident/SKILL.md` contains the `work → score → commit` ordering sequence
- [ ] Both SKILL.md files reference `AskUserQuestion` at the above-appetite commit branch point
- [ ] A BATS functional test (mocked `git commit` invocation, not a source-grep) asserts the commit instruction path in at least one in-scope skill — deferred to P012 skill testing harness until that harness is resolved

## Related

- P023: `docs/problems/023-governance-skills-should-commit-completed-work.open.md` — the problem this ADR resolves
- P024: `docs/problems/024-risk-scorer-wip-flag-uncommitted-completed-work.open.md` — complementary risk-scorer improvement; once skills auto-commit, P024 becomes a safety net for cases where auto-commit fails or is skipped
- ADR-013: `docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md` — AskUserQuestion rule at branch points; ADR-014 extends this to the commit-gate branch point
- ADR-011: `docs/decisions/011-manage-incident-skill.proposed.md` — manage-incident skill; its Confirmation criteria do not cover commit behaviour; ADR-014 fills that gap for in-scope skills
- ADR-009: `docs/decisions/009-gate-marker-lifecycle.proposed.md` — gate marker lifecycle; ADR-014's ordering sequence respects the bypass-marker mechanism defined here
- `packages/risk-scorer/hooks/risk-score-commit-gate.sh` — the commit gate hook that enforces score-before-commit
