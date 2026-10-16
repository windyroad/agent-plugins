---
title: Plan toward a verified outcome
description: Confirm a SMART objective, then deliver and learn through Now, Next and Later.
---

Outcome-led planning keeps the result you want as the reference point while
the plan changes through delivery and learning. The outcome is the objective.

## Start the workflow

[Install planning and arrange the required reviews](../runtimes/), then invoke:

```text
/wr-planning:outcome-led-planning
```

For an installed Codex plugin, use `$wr-planning:outcome-led-planning`.
Describe the result you want and any constraints you already know.

Planning installs independently of ITIL and has no hooks or bundled reviewer
agents. Existing ITIL planning commands and personal `$outcome-led-planning`
skills remain usable; you do not need to remove them to install this plugin.

## Establish and confirm the objective

The skill uses SMART: specific, measurable through observable evidence,
achievable against known constraints, relevant to your job, and time-bound.
Qualitative evidence can establish completion; arbitrary numerical targets are
not required.

If information is missing, the agent asks one focused question and waits for
your answer. It uses existing context before asking for details again. If you
decline a deadline, it records that exception rather than inventing one.

Before executable planning, the agent plays back the complete objective,
completion evidence and material constraints. Confirm it or suggest changes.
A substantive later change to the objective requires confirmation again;
ordinary replanning of the means does not.

## Work through Now, Next and Later

- **Now:** one coherent increment with scope, assumptions, verification and a
  clear delivery boundary. INVEST checks that it is independently deliverable,
  negotiable within the confirmed goal, valuable, estimable, small and testable.
- **Next:** provisional subsequent increments, with less detail.
- **Later:** broad direction where uncertainty remains highest.

INVEST does not require story documents unless your project already requires
them. Architecture, JTBD and risk reviewers assess every executable plan
revision. Substantive failures are resolved before dependent work.

## Work through obstacles

The agent treats a recoverable failure as a problem to solve: diagnose it,
use an available equivalent or make a bounded reversible repair, and continue
useful independent work. It adapts the means while preserving the confirmed
outcome and required evidence.

Routine choices do not need another approval. Real gaps in authority or
capability still need a precise handoff after useful authorized alternatives
have been exhausted. Required reviews still apply to materially revised plans.

## Verify, learn and replan

After each delivered increment, compare actual evidence with both that increment
and the overall objective. Retain useful learning, revise the remaining plan and
obtain fresh reviews before the next dependent increment. Failed verification
does not count as delivery.

The agent stops when the objective's evidence is satisfied, or reports the exact
remaining blocker after exhausting useful authorized work. A commit, green CI or
publication establishes only its own stage.

[Read the skill reference and full source](../skills/planning/outcome-led-planning/).
