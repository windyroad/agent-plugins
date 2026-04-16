# @windyroad/problem

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
