# @windyroad/risk-scorer

**Pipeline risk scoring, commit/push gates, and secret leak detection for Claude Code.** Scores every change for risk and blocks high-risk commits and pushes before they happen.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

The risk-scorer plugin brings ISO 31000-aligned risk management to your AI coding workflow. It:

1. **Scores risk** on every edit, assessing cumulative pipeline risk as changes build up
2. **Gates commits** -- blocks `git commit` when cumulative risk exceeds your policy threshold
3. **Gates pushes** -- blocks `git push` for high-risk changesets (use `npm run push:watch` instead)
4. **Detects secrets** -- scans edits for API keys, tokens, passwords, and other credentials before they're written
5. **Reviews plans** -- scores implementation plans for risk before you start building

All thresholds are configurable through your project's `RISK-POLICY.md`.

## Install

```bash
npx @windyroad/risk-scorer
```

Restart Claude Code after installing.

## Usage

The plugin works automatically once installed. On first run in a project without a risk policy, it blocks edits and directs you to generate one:

```
/wr-risk-scorer:update-policy
```

This creates a `RISK-POLICY.md` tailored to your project, defining impact levels, likelihood scales, risk appetite, and the risk matrix -- all aligned to ISO 31000.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `risk-score.sh` | Every prompt | Injects risk scoring context |
| `secret-leak-gate.sh` | Edit or Write | Blocks writes containing secrets |
| `wip-risk-gate.sh` | Edit or Write | Blocks edits if WIP risk hasn't been assessed |
| `risk-policy-enforce-edit.sh` | Edit or Write | Blocks edits if no `RISK-POLICY.md` exists |
| `git-push-gate.sh` | Bash (git push) | Blocks direct `git push`; requires `npm run push:watch` |
| `risk-score-commit-gate.sh` | Bash (git commit) | Blocks commits when risk exceeds threshold |
| `risk-score-plan-enforce.sh` | ExitPlanMode | Ensures plans are risk-scored before execution |
| `plan-risk-guidance.sh` | EnterPlanMode | Injects risk guidance into plan mode |
| `wip-risk-mark.sh` | After edit | Records WIP risk assessment |
| `risk-score-mark.sh` | Agent completes | Marks risk review as done |
| `risk-hash-refresh.sh` | After Bash | Refreshes content hashes |
| `risk-score-reset.sh` | Session end | Cleans up risk markers |
| `risk-policy-reset-marker.sh` | Session end | Cleans up policy markers |

## Agents

The plugin includes five specialised agents:

| Agent | Purpose |
|-------|---------|
| `wr-risk-scorer:agent` | Routes to the appropriate mode-specific agent |
| `wr-risk-scorer:wip` | Assesses cumulative risk after each edit |
| `wr-risk-scorer:pipeline` | Scores pipeline actions (commit, push, release) |
| `wr-risk-scorer:plan` | Reviews implementation plans for risk |
| `wr-risk-scorer:policy` | Validates `RISK-POLICY.md` for ISO 31000 compliance |

## Updating and Uninstalling

```bash
npx @windyroad/risk-scorer --update
npx @windyroad/risk-scorer --uninstall
```

## Licence

[MIT](../../LICENSE)
