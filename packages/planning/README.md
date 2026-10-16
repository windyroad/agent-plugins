# @windyroad/planning

**Keep the outcome clear while the plan evolves.** Confirm a SMART objective,
deliver one reviewed increment, then verify, learn and replan Now, Next and Later.
*Maturity: Experimental.*

Part of [Windy Road Agent Plugins](../../README.md).
Read the [outcome-led planning guide](https://windyroad.github.io/agent-plugins/outcome-led-planning/).

## Install

For Claude Code:

```bash
npx @windyroad/planning
```

For Codex:

```bash
npx @windyroad/planning --runtime codex --scope user
```

Use `--runtime both` for both runtimes. Restart the runtime after installation
and check its plugin and skill lists.

This package installs one skill, with no hooks or reviewer agents. ITIL is not
required. The planning workflow requires independent architecture, JTBD and risk
reviews of every executable plan revision. Use available independent reviewers,
or install the [architect](../architect/), [JTBD](../jtbd/) and
[risk-scorer](../risk-scorer/) plugins for your runtime. If a substantive review
cannot be obtained, the skill reports the missing capability and holds dependent
implementation.

## Use

In Claude Code:

```text
/wr-planning:outcome-led-planning
```

In Codex:

```text
$wr-planning:outcome-led-planning
```

Describe the result you want and any constraints. The agent asks one question
at a time when information is missing, then plays back the complete objective
and waits for your confirmation before planning. It makes one Now increment
INVEST-shaped without requiring story documents unless your project needs them.
After delivery it verifies the result, learns and reassesses the revised plan.

| Skill | Purpose | Maturity |
| --- | --- | --- |
| `/wr-planning:outcome-led-planning` | Confirm a SMART outcome and iteratively deliver through reviewed Now, Next and Later increments | Experimental |

## Existing installations

The existing `/wr-itil:outcome-led-planning` and
`$wr-itil:outcome-led-planning` commands remain usable through the full
compatibility skill bundled in ITIL. They do not require this package. New
installations can choose planning independently.

An existing personal `$outcome-led-planning` skill remains separate. Installing,
updating or uninstalling this plugin does not replace that personal skill.

## Update or remove

```bash
npx @windyroad/planning --update
npx @windyroad/planning --uninstall
```

Include the same runtime and scope flags used for installation.

## Maintain the source

The canonical workflow lives in `skills/outcome-led-planning/SKILL.md`. In the
monorepo, run `npm run sync:planning-skill` after changing it; the checked sync
keeps the ITIL compatibility body equivalent while preserving its old name.
The personal skill is user-managed and is not a synchronization target.
