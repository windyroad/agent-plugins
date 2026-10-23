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

This package installs planning, contribute and GitHub tracking setup, with no hooks
or reviewer agents.
ITIL is not required. Initial and materially revised executable plans require
five independent critics: architecture, JTBD, risk, cognitive accessibility and
planning. Use available independent reviewers,
or install the [architect](../architect/), [JTBD](../jtbd/) and
[risk-scorer](../risk-scorer/) plugins for your runtime. If a substantive review
cannot be obtained, the skill reports the missing capability and holds dependent
implementation.

Arrange the cognitive accessibility and planning critics through available
independent reviewers too. Routine task claims and status updates within an
assessed plan do not restart all five reviews.

Before an increment is declared complete, its owner obtains an independent
acceptance check through the planning critic. The critic inspects actual results
and affected saved records; discrepancies are repaired and rechecked. An existing
independent review covering these criteria is reused. Individual task completion
does not trigger this increment-level check.

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

## Remember the project's tracking choice

Planning and contribute read the same project configuration. Use the location
declared by the project, or `.agents/planning.json` by default. When no choice
exists, the skill asks **GitHub Issues or Local?** and waits. It saves and reads
back your answer, then reuses it across skills and fresh sessions. An existing
explicit choice needs no repeat question.

```json
{"version": 1, "backend": "local"}
```

Use `"github"` for GitHub Issues. Ask to change the project tracking choice when
needed; the agent preserves unrelated fields and contributor mappings. Invalid
or unsupported settings are preserved while their repair is clarified.
Configuration is agent-read data and grants no authentication or permissions.
Installers do not create an adopter project's configuration.

Local mode uses the agreed plan and channel without GitHub setup. A runtime may
protect the default configuration directory from writes. Use a permitted
project-declared location, such as `planning.json`, or obtain the required write
access; a denied write does not establish persistence.

With GitHub selected, the agent loads its bundled protocol and uses outcome →
increment → task issues. Increments have Now, Next or Later horizons; execution
status is separate. Contributors check existing claims, identify their account
and agent/session, and coordinate dependencies and evidence in the increment
thread. The outcome owner verifies delivery and replans. A GitHub Project can
mirror those issues when available; it is optional. Conversation and local
planning remain available. For missing selected setup, planning and contribute
call the bundled setup skill. Complete setup and equivalent custom mappings are
reused; Project fields and views apply only to a selected or required Project.

Each contributor uses their own access. Tracker selection does not authorize
new messaging, broader permissions or persistent automation. Issue comments
do not guarantee an idle agent will wake up.

## Set up GitHub tracking

Invoke `/wr-planning:setup-github-tracking` in Claude Code or
`$wr-planning:setup-github-tracking` in Codex when you need to configure or repair
selected GitHub tracking. Planning and contribute call it when setup is missing
or incomplete. It reuses the same project configuration and returns to the
current work without interviewing you about the outcome again.

Issues-only tracking needs no Project. For a selected Project, the skill reuses
equivalent setup and configures missing fields and Outcomes, Increments and Tasks
views. Increments uses a table grouped by Horizon with **Show hierarchy On**.
Changed settings are saved and reopened; related task children remain accessible
beneath their increment. Existing custom views, ownership and history are preserved.
Local tracking bypasses this setup.

## Join an outcome with contribute

Invoke `/wr-planning:contribute` in Claude Code or `$wr-planning:contribute` in
Codex. It reuses the saved backend and finds useful direct or indirect help
within the current assessed Now. Contributors inspect current work and claims,
then create or reuse one bounded task just before starting it. The owner keeps
acceptance, sequence and integration clear without allocating every task.

A starting battle plan exposes useful opportunities and dependencies; it does
not precreate or reserve the whole backlog. Finish, hand over or release one
claim before taking another. Planning MUST NOT add speculative risk-mitigation
tasks: the risk scorer derives necessary treatments from the applicable policy
and register. Existing required controls remain binding.

Saved project tracking and contribute require planning **0.4.0 or later**.

| Skill | Purpose | Maturity |
| --- | --- | --- |
| `/wr-planning:outcome-led-planning` | Confirm a SMART outcome and iteratively deliver through reviewed Now, Next and Later increments | Experimental |
| `/wr-planning:contribute` | Find and carry out useful bounded help within the current assessed increment | Experimental |
| `/wr-planning:setup-github-tracking` | Configure missing selected GitHub issue tracking and Project views | Experimental |

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

Canonical planning and GitHub setup live under `skills/`. In the monorepo, run
`npm run sync:planning-skill` after changing either; the checked sync keeps both
ITIL compatibility skills and their supporting resources equivalent while
preserving their names.
The personal skill is user-managed and is not a synchronization target.
