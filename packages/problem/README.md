# @windyroad/problem

**ITIL-aligned problem management for Claude Code.** Track recurring incidents, perform root cause analysis, and prioritise fixes using WSJF -- all inside your coding sessions.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

Bugs recur. Incidents repeat. Without a problem management process, you fix symptoms instead of causes. This plugin brings lightweight ITIL problem management to your AI coding workflow:

- **Create problem tickets** when incidents or failures surface during a session
- **Track root cause analysis** as investigation progresses
- **Transition status** through a structured lifecycle: Open, Known Error, Closed
- **Prioritise** using Weighted Shortest Job First (WSJF) to focus on the highest-value fixes

Problem tickets live in `docs/problems/` as markdown files -- version-controlled and always accessible.

## Install

```bash
npx @windyroad/problem
```

Restart Claude Code after installing.

> **Requires:** [`@windyroad/risk-scorer`](../risk-scorer/). The installer warns if it's missing.

## Usage

**Create or update a problem ticket:**

```
/wr-problem:update-ticket
```

This supports:

- Creating new problems from an incident or observed failure
- Updating root cause analysis with investigation findings
- Transitioning status (Open -> Known Error -> Closed)
- Closing problems with resolution details

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `check-deps.sh` | Session start | Verifies that `wr-risk-scorer` is installed |

## Updating and Uninstalling

```bash
npx @windyroad/problem --update
npx @windyroad/problem --uninstall
```

## Licence

[MIT](../../LICENSE)
