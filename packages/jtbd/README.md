# @windyroad/jtbd

**Jobs-to-be-done enforcement for Claude Code.** Reviews UI changes against your documented user jobs, personas, and desired outcomes before they ship.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

An AI agent building a feature doesn't know *why* the feature exists or *who* it's for. It builds what you describe, but can't validate whether the result actually serves the user's job-to-be-done.

The JTBD plugin:

1. **Detects** when an edit touches user-facing UI files
2. **Blocks** the edit until the JTBD agent has reviewed it
3. **Reviews** changes against your `docs/JOBS_TO_BE_DONE.md` and `docs/PRODUCT_DISCOVERY.md`
4. **Reports** alignment gaps -- features that don't map to a documented job, or that conflict with persona constraints

## Install

```bash
npx @windyroad/jtbd
```

Restart Claude Code after installing.

## Usage

The plugin works automatically. On first use in a project without a JTBD document, it blocks edits and directs you to create one:

```
/wr-jtbd:update-guide
```

This examines your existing features and asks about your user jobs, personas, and desired outcomes to generate a `docs/JOBS_TO_BE_DONE.md`.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `jtbd-eval.sh` | Every prompt | Evaluates whether the task involves user-facing UI |
| `jtbd-enforce-edit.sh` | Edit or Write | Blocks edits until the JTBD agent has reviewed |
| `jtbd-mark-reviewed.sh` | Agent completes | Marks the review as done (TTL: 3600s) |

## Agent

The `wr-jtbd:agent` reads your `docs/JOBS_TO_BE_DONE.md` and reviews proposed UI changes against:

- Documented user jobs and their success criteria
- Persona definitions and constraints
- Screen-to-job mappings

## Updating and Uninstalling

```bash
npx @windyroad/jtbd --update
npx @windyroad/jtbd --uninstall
```

## Licence

[MIT](../../LICENSE)
