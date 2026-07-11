# @windyroad/agent-plugins

## 0.2.0

### Minor Changes

- 7c87fe5: Add `@windyroad/cruise` — token-quota pacing — and retire the seven-way throttle sync.

  `@windyroad/cruise` is a self-calibrating token-quota throttle for Claude Code. It reads your rate-limit usage, measures your actual burn, and paces your tool calls so you glide onto each window's pace line and converge on the reset — instead of sprinting into a hard rate-limit stop mid-session. It reserves a weekly headroom for your other Claude surfaces, never blocks, and fails open. Knobs live in a config file (`.claude/cruise.config.json` per project or `~/.claude/cruise.config.json` per machine); `WR_QUOTA_THROTTLE_DISABLE=1` pauses it.

  The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship the throttle — it now has a single home in `@windyroad/cruise`, installed as part of the default `npx @windyroad/agent-plugins` set.

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
