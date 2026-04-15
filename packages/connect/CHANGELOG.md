# @windyroad/connect

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
