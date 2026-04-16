# @windyroad/connect

## 0.3.5

### Patch Changes

- 8a15336: Fix `--update` flag failing with "Plugin not found" (P025). The `updatePlugin` command was missing the `@windyroad` marketplace suffix and `--scope project`, causing all `npx @windyroad/<pkg> --update` invocations to fail. The correct command is now used: `claude plugin update "<name>@windyroad" --scope project`.

## 0.3.4

### Patch Changes

- 24597ed: Update BLOCKED notice to link to canonical upstream issue #42292 (our filing #48216 was a duplicate).

## 0.3.3

### Patch Changes

- a0ecdf3: Add BLOCKED notice to README — setup skill is currently unusable due to upstream claude-code#48216 removing AskUserQuestion/EnterPlanMode/ExitPlanMode from `--channels` sessions. Runtime (send/receive) still works; only guided setup is affected.

## 0.3.2

### Patch Changes

- 05e9e2a: Setup skill now requires AskUserQuestion tool (no plain-prompt fallback). If the tool is unavailable, the skill stops and asks the user to restart Claude Code.

## 0.3.1

### Patch Changes

- c65757b: Break setup skill into fine-grained checkpoints — one action per question instead of multi-step chunks. Agent now pauses after every instruction to confirm.

## 0.3.0

### Minor Changes

- 45882d8: Rewrite setup skill to match Discord plugin flow: /discord:configure for token, --channels for connection, DM pairing, allowlist lockdown. Each repo gets its own bot named after org/repo. Session-start hook detects Discord plugin config instead of env var.

## 0.2.1

### Patch Changes

- 1fa0e46: Improve setup skill: interactive AskUserQuestion at each step, suggest wr-connect bot name, enable reaction intents, support .env file and 1Password CLI for credential storage

## 0.2.0

### Minor Changes

- 93527a5: Add connect plugin for cross-repo collaboration between Claude Code sessions via Discord (experimental)
