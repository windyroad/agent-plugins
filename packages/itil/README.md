# @windyroad/itil

**ITIL-aligned IT service management for Claude Code.** Track recurring incidents, perform root cause analysis, and prioritise fixes using WSJF -- all inside your coding sessions.

Part of [Windy Road Agent Plugins](../../README.md).

## What It Does

Bugs recur. Incidents repeat. Without a disciplined process, you fix symptoms instead of causes — or worse, jump to conclusions during a live outage. This plugin brings lightweight ITIL service management to your AI coding workflow:

**Problem management** — track underlying causes and prioritise fixes:

- **Create problem tickets** when incidents or failures surface during a session
- **Track root cause analysis** as investigation progresses
- **Transition status** through a structured lifecycle: Open, Known Error, Closed
- **Prioritise** using Weighted Shortest Job First (WSJF) to focus on the highest-value fixes

**Incident management** — restore service fast with an audit trail:

- **Declare incidents** when production is actively broken
- **Evidence-first discipline** — hypotheses must cite evidence before any mitigation
- **Reversible mitigations first** — rollback, feature flag, restart, route away
- **Automatic handoff** to problem management once service is restored

Tickets live in `docs/problems/` and `docs/incidents/` as markdown files — version-controlled and always accessible.

Room is reserved for peer ITIL skills (change, continual improvement) under the same plugin as they are added.

## Install

```bash
npx @windyroad/itil
```

Restart Claude Code after installing.

> **Requires:** [`@windyroad/risk-scorer`](../risk-scorer/). The installer warns if it's missing.
>
> **Renamed from `@windyroad/problem`** — see [ADR-010](../../docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md). If you had the old package installed, uninstall it (`npx @windyroad/problem --uninstall`) before installing `@windyroad/itil`.

## Usage

**Manage a problem ticket:**

```
/wr-itil:manage-problem
```

Supports creating new problems, updating root cause analysis, transitioning status (Open → Known Error → Closed), and closing problems with resolution details.

**Manage an incident:**

```
/wr-itil:manage-incident
```

Supports declaring new incidents, recording evidence-first observations and hypotheses, logging mitigation attempts, transitioning lifecycle (Investigating → Mitigating → Restored → Closed), and automatically handing off to `manage-problem` when service is restored.

See [ADR-011](../../docs/decisions/011-manage-incident-skill.proposed.md) for the incident-vs-problem split and [JTBD-201](../../docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md) for the job this serves.

## How It Works

| Hook | Trigger | What it does |
|------|---------|-------------|
| `check-deps.sh` | Session start | Verifies that `wr-risk-scorer` is installed |

## Updating and Uninstalling

```bash
npx @windyroad/itil --update
npx @windyroad/itil --uninstall
```

## Licence

[MIT](../../LICENSE)
