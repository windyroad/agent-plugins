# @windyroad/architect

**Architecture decision enforcement for Claude Code.** Ensures every code change is reviewed against your project's architecture decisions before it lands.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

The architect plugin prevents architectural drift by gating edits behind an architecture review. When you have a `docs/decisions/` directory, the plugin:

1. **Detects** your architecture decisions on every prompt
2. **Blocks** edits to project files until the architect agent has reviewed the proposed changes
3. **Reviews** changes against your existing ADRs (Architecture Decision Records) and flags conflicts
4. **Flags** when a new decision should be documented

No decisions directory yet? The plugin stays silent until you create one.

## Install

```bash
npx @windyroad/architect
```

Restart Claude Code after installing.

## Usage

Once installed, the plugin works automatically. You don't need to invoke it -- it intercepts edits and runs the review before allowing changes through.

**Create a new Architecture Decision Record:**

```
/wr-architect:create-adr
```

This walks you through creating an ADR in [MADR 4.0](https://adr.github.io/madr/) format. It examines your existing decisions, asks about the problem and options, and writes a properly formatted record to `docs/decisions/`.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `architect-detect.sh` | Every prompt | Checks for `docs/decisions/` and injects the review instruction |
| `architect-enforce-edit.sh` | Edit or Write | Blocks the edit if the architect hasn't reviewed yet |
| `architect-plan-enforce.sh` | ExitPlanMode | Ensures plans are reviewed before execution |
| `architect-mark-reviewed.sh` | Agent completes | Marks the review as done (TTL: 1800s) |
| `architect-refresh-hash.sh` | After edit | Refreshes the content hash so the next edit triggers a fresh review |

## Agent

The `wr-architect:agent` reviews proposed changes against existing decisions in `docs/decisions/` and reports:

- Whether changes comply with or violate existing decisions
- Whether a new ADR should be created
- Whether existing decisions are stale and need reassessment

## Updating and Uninstalling

```bash
npx @windyroad/architect --update
npx @windyroad/architect --uninstall
```

## Licence

[MIT](../../LICENSE)
