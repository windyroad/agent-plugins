# @windyroad/retrospective

**Session retrospectives for Claude Code.** Captures learnings at the end of each session and creates problem tickets for failures and friction.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

Every coding session produces learnings -- things that went well, things that broke, things that were harder than expected. Without a retrospective, those learnings evaporate.

The retrospective plugin:

- **Reminds** you to run a retro when a session ends
- **Updates** `docs/BRIEFING.md` with session learnings so future sessions start with context
- **Creates problem tickets** (via [`@windyroad/problem`](../problem/)) for failures and friction encountered during the session

## Install

```bash
npx @windyroad/retrospective
```

Restart Claude Code after installing.

> **Requires:** [`@windyroad/problem`](../problem/) and [`@windyroad/risk-scorer`](../risk-scorer/). The installer warns if they're missing.

## Usage

**Run a session retrospective:**

```
/wr-retrospective:run-retro
```

This walks through the session's work, identifies what went well and what didn't, updates `docs/BRIEFING.md`, and creates problem tickets for any failures.

The plugin also triggers a reminder via a `Stop` hook when a session ends naturally.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `check-deps.sh` | Session start | Verifies that `wr-problem` and `wr-risk-scorer` are installed |
| `retrospective-reminder.sh` | Session end | Reminds you to run a retrospective |

## Updating and Uninstalling

```bash
npx @windyroad/retrospective --update
npx @windyroad/retrospective --uninstall
```

## Licence

[MIT](../../LICENSE)
