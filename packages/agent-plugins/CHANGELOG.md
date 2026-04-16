# @windyroad/agent-plugins

## 0.1.6

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.1.5

### Patch Changes

- 6eeef94: Rename `@windyroad/problem` → `@windyroad/itil` (plugin `wr-problem` → `wr-itil`, skill `/wr-problem:update-ticket` → `/wr-itil:manage-problem`). Makes room for peer ITIL skills (incident, change) under the same plugin. Hard rename, no shim — per ADR-010.

  **Migration**: if you had `@windyroad/problem` installed, uninstall it (`npx @windyroad/problem --uninstall`) then install `@windyroad/itil`. The skill command changes from `/wr-problem:update-ticket` to `/wr-itil:manage-problem`. `@windyroad/retrospective`'s dependency is updated automatically.

## 0.1.4

### Patch Changes

- 93527a5: Add connect plugin for cross-repo collaboration between Claude Code sessions via Discord (experimental)

## 0.1.3

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.

## 0.1.2

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
