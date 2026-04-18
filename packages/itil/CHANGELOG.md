# @windyroad/problem

## 0.4.0

### Minor Changes

- a36a084: Add `wr-itil:work-problems` AFK batch orchestrator skill and document a commit-gate fallback in `wr-itil:manage-problem` (JTBD-006).

  - **New skill** `wr-itil:work-problems` — loops through ITIL problem tickets by WSJF priority, delegating each iteration to `wr-itil:manage-problem` non-interactively. Stops gracefully when nothing remains actionable. Emits `ALL_DONE` sentinel for external detection. Deterministic Step 4 classification rules (skip known-errors with Fix Released; work everything else).
  - **Fix** `wr-itil:manage-problem` commit gate now documents a two-path delegation (closes P035). Primary: delegate to `wr-risk-scorer:pipeline` subagent-type via the Agent tool. Fallback: invoke `/wr-risk-scorer:assess-release` via the Skill tool when the subagent-type is unavailable (e.g., when `manage-problem` is itself running inside a spawned subagent). Per ADR-015 both produce equivalent bypass markers. Non-interactive fail-safe preserved for the risk-above-appetite branch only — silent-skip for delegation-unavailable is no longer sanctioned.

## 0.3.3

### Patch Changes

- 83b8be7: fix(manage-problem): add Parked lifecycle status and README.md fast-path cache (closes P027)

  - Adds `.parked.md` suffix and Parked status to problem lifecycle table
  - `problem work` checks README.md freshness before triggering full 18-file re-scan
  - Step 9e writes/overwrites `docs/problems/README.md` after every full re-rank
  - Parked problems excluded from WSJF ranking; shown in separate Parked table

## 0.3.2

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.1

### Patch Changes

- e8216b1: Governance skills now commit their own completed work (P023, ADR-014).

  **@windyroad/itil**: `manage-problem` and `manage-incident` skills no longer end with "Do not commit — the user will commit when ready." They now instruct the agent to stage files, delegate to `wr-risk-scorer:pipeline` for a risk assessment, and commit automatically using a conventional commit message referencing the problem or incident ID. If risk is above appetite, an `AskUserQuestion` prompt is presented before committing. Non-interactive fail-safe per ADR-013 Rule 6.

  New ADR-014 documents the cross-skill commit pattern, commit message convention, and risk-gate delegation sequence.

## 0.3.0

### Minor Changes

- e5eb0bd: Add `manage-incident` skill for evidence-first incident response with automatic handoff to problem management.

  The new `/wr-itil:manage-incident` skill implements an ITIL-aligned incident workflow focused on **restoring service fast** while keeping a disciplined audit trail. Hypotheses must cite evidence before any mitigation. Reversible mitigations (rollback, feature flag, restart) are preferred over forward fixes. On restoration, the skill automatically invokes `manage-problem` to create or update the underlying root-cause ticket, linking the incident to a `P###`.

  Incidents use a separate `I###` namespace in `docs/incidents/` so lifecycles, prioritisation (severity for incidents, WSJF for problems), and audit trails stay clean. See ADR-011 and JTBD-201 for the full design.

### Patch Changes

- 23d0d10: Require structured `AskUserQuestion` prompts at all governance-skill decision branches (P021, ADR-013).

  **@windyroad/itil**: `manage-problem` skill now requires `AskUserQuestion` for WSJF tie-breaks, problem selection, and scope-change decisions. Prose "(a)/(b)/(c)" option lists are prohibited.

  **@windyroad/risk-scorer**: All three scorer agents (pipeline, wip, plan) now enforce below-appetite silence — no advisory prose, "Your call:", or suggestions when scores are within appetite. Above-appetite output uses structured `RISK_REMEDIATIONS:` blocks instead of free-text suggestions.

  New ADR-013 establishes the cross-cutting standard: every governance-skill branch point with ≥2 options must use `AskUserQuestion`; scoring agents stay pure output-only.

## 0.2.0

### Minor Changes

- 6eeef94: Rename `@windyroad/problem` → `@windyroad/itil` (plugin `wr-problem` → `wr-itil`, skill `/wr-problem:update-ticket` → `/wr-itil:manage-problem`). Makes room for peer ITIL skills (incident, change) under the same plugin. Hard rename, no shim — per ADR-010.

  **Migration**: if you had `@windyroad/problem` installed, uninstall it (`npx @windyroad/problem --uninstall`) then install `@windyroad/itil`. The skill command changes from `/wr-problem:update-ticket` to `/wr-itil:manage-problem`. `@windyroad/retrospective`'s dependency is updated automatically.

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
