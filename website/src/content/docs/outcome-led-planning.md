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
The agent preserves your stated timing. When the outcome is ready for
confirmation, it asks you to confirm or change that playback before discussing
implementation choices.

Before executable planning, the agent plays back the complete objective,
completion evidence and material constraints. Confirm it or suggest changes.
A substantive later change to the objective requires confirmation again;
ordinary replanning of the means does not.

## Choose where to track the plan

Conversation or local planning remains available. For shared work, you can
choose **GitHub Issues tracking** after confirming the outcome. The agent honors
an existing choice; when a choice is needed, it asks one question and waits.
It does not ask again just because a different agent joins or a session resumes.
Without an existing GitHub choice or evidence that shared coordination adds
value, the agent keeps conversation or local tracking.

The full coordination requirements in this guide use planning **0.3.0 or later**,
or the ITIL compatibility command in **3.3.0 or later**. [Update your installed
plugin](../updating/) before relying on it.

The agent reads a bundled coordination protocol when GitHub tracking is
selected. The linked issues become the shared plan. An optional GitHub Project
mirrors those same issues. Existing architecture decisions, jobs and risk
policies continue to govern their own domains. Moving a local plan into Issues
requires a recorded handover and current revision, so agents retain one
source of planning authority.

### Use outcome, increment and task issues

- **Outcome:** the confirmed SMART result, completion evidence, constraints,
  timeframe and increment links. Its owner keeps the goal clear and replans.
- **Increment:** one coherent result, its plan revision, acceptance criteria,
  assumptions, dependencies, reviews and contribution tasks. Its owner
  coordinates delivery and verifies the whole increment.
- **Task:** one agent's bounded contribution, with its parent increment,
  current plan revision, scope, dependencies, account and distinct agent or
  session identity, status and evidence.

Record an owner for every outcome, increment and task, or state that ownership
is unresolved. A child issue does not inherit its parent's owner.

**Horizon** means Now, Next or Later and belongs to planned or active increments.
**Status** describes execution, such as in progress, blocked or done. For example,
a Now increment waiting for input has **Horizon: Now** and **Status: blocked**.
It does not become Next automatically. Outcomes and tasks have no Horizon.
Completed or superseded increments leave active horizons while retaining history.

Use native sub-issues where supported. When another task supplies a required
result, create and verify its native dependency where tools and permissions
support it. This includes prerequisites for a later stage or task completion.
Name the exact unlock condition and required evidence. Useful preparation can
remain Ready or In progress while those dependencies stay open; verify the
prerequisite before the dependent stage or completion.

When a native relationship is unavailable or denied, use reciprocal links and
record the exact limitation. Read back saved records before claiming a
relationship or update succeeded.

A prerequisite task must not require its dependent task's result to finish.
Propose corrections in the increment thread. The increment owner records revised
task boundaries and acceptance with affected task owners before applying them.
Give each task an independently verifiable result and retain the combined result
in increment acceptance. Obtain architecture, Jobs To Be Done (JTBD), and risk
reviews before executing a materially revised plan.

### Join and contribute safely

The contributing agent uses its own authorized account and follows these steps.

1. Read the outcome, current increment revision, shared discussion, existing
   tasks and dependencies. Check for overlapping work and stale assumptions.
2. Hold only one contribution task at a time, including a blocked assignment.
   Finish it, explicitly hand it over or release it before claiming another.
   Do not reserve queued tasks. Outcome or increment coordination ownership does
   not reserve contribution tasks.
3. Claim a separately owned contribution within the authorized, reviewed plan.
   Assign its task to your actual GitHub account and record the particular agent
   or session. Two agents sharing an account remain distinct contributors.
   If assignment is unavailable, record the account and agent or session in the
   task, state the exact limitation, and verify the saved record before contributing.
4. Record scope, parent, revision and dependencies, including when there are
   none. Verify the saved claim and links, then recheck competing claims before
   implementation. Claims are cooperative; they are not atomic locks.
5. Agree an explicit split or handoff before taking over someone else's work.
   An old claim does not grant ownership. Small internal steps can remain a
   checklist instead of becoming separate task issues.
6. Attach completion evidence to the task and hand off cross-task results in
   the increment thread. A finished task does not by itself finish the increment
   or outcome.

Mark a task **Blocked only when no useful, authorized next step remains within
its scope** because a required input or capability is unavailable. Investigable
facts, obtainable reviews and later-stage prerequisites do not block useful
current preparation. Do not invent speculative work to avoid Blocked.

Reassess available inputs and useful authorized in-task work before releasing
a blocked assignment. A stored Blocked status alone does not establish
exhaustion. Continue useful work; release with a handover only when the required
input is unavailable and no useful in-task step remains. Record the blocker,
evidence and next step. Keep the blocked task Blocked and unassigned. Leave
independently actionable work Ready/Unclaimed so another agent can contribute.

Each contributor uses their own existing access. Assignment does not grant
additional permissions. When an existing Project is selected, verify its actual
Status and Agent fields. Labels and issue-body text do not establish Project
field values. Use available authorized tools, a CLI or an authorized operator,
then read back the saved fields. Record a pending mirror update honestly and
continue useful issue-side work.

Keep task scope, ownership, status, dependencies, next action and verified
evidence current. Coordinate replaced or dropped work with the increment owner
and affected task owners. Close redundant tasks as **not planned**, with reasons
and successor links. Preserve required acceptance evidence and prerequisites
before removing an obsolete dependency; verify saved changes.

### Coordinate in the increment thread

Keep task-local details on the task. Use the increment issue's discussion for
cross-task requests, blockers, findings, handoffs and proposed plan changes.
Include the agent or session, task and dependency links, current revision,
recipient, concrete request and relevant evidence. The recipient acknowledges
and links the task that will address the request; the dependent owner verifies
returned evidence before clearing a blocker.

Use communication channels the user has authorized. Choosing a tracker does not
independently authorize messages to people or other sessions. Keep private chats,
credentials and sensitive customer details out of shared threads.

Read relevant increment comments regularly throughout coding and waiting, and
before dependent actions, pushes, scope or ownership changes and handovers.
Acknowledge handoffs and answer questions affecting owned work through
authorized channels. Agree and record a bounded cadence for the active work
window; a suggested interval remains a proposal until agreement and its saved
record are established. Pending agreement does not suspend authorized bounded
checks or existing action checkpoints. A posted message does not prove recipient
acknowledgement. **Comments and mentions do not guarantee an idle agent wakes.**
Standing pollers, scheduled jobs and orchestration services need explicit
authorization.

### Replan as the outcome owner

After a verified increment, compare its evidence with the overall outcome and
record what you learned. Rewrite the plan from the remaining gap:
reorder, replace, split or drop increments instead of automatically promoting
old Next. Update active horizons and the optional Project mirror, preserving
history and recording any update that could not be made.

Obtain architecture, JTBD and risk reviews before executing a materially revised
plan. A scoped contribution inside the existing assessed revision does not need
another full planning cycle. Close the outcome only when its confirmed evidence
is satisfied. A tidy board or all tasks marked done cannot replace that result.

[Read the full GitHub planning requirements](https://github.com/windyroad/agent-plugins/blob/main/packages/planning/skills/outcome-led-planning/references/github-coordination.md).

## Work through Now, Next and Later

- **Now:** one coherent increment with scope, assumptions, verification and a
  clear delivery boundary. INVEST checks that it is independently deliverable,
  negotiable within the confirmed goal, valuable, estimable, small and testable.
- **Next:** provisional subsequent increments, with less detail.
- **Later:** broad direction where uncertainty remains highest.

Choose the smallest result that is useful on its own. State who benefits and
the observable improvement, validated decision or capability they receive.
Split Now again if a smaller result still provides business value. Shared code
does not justify bundling separate useful results.

Keep the security, integrity, recovery and acceptance checks needed for that
result. A completed technical activity alone is insufficient. Promotion from
test to production is a delivery process; its stages do not automatically
become separate increments. A foundation needs explicit value and limits.
Deliver the verified minimum, then replan before adding work. Repeat this size
check whenever Now changes.

When uncertainty prevents a bounded implementation increment, choose focused
discovery or qualification. Define a finite inspection pass, concrete output and
stopping condition. Give the pass itself a qualitative effort estimate grounded
in that limited scope; keep later implementation uncertainty separate. Record
unavailable inputs precisely and continue useful authorized alternatives.
Authorized preliminary reading can inform the plan; executing a formal discovery
increment still requires its reviews.

INVEST does not require story documents unless your project already requires
them. Architecture, JTBD and risk reviewers assess every executable plan
revision. Substantive failures are resolved before dependent work. When a
required independent review is unavailable, hold dependent implementation and
continue useful authorized preparation. An ordinary go-ahead does not supply
that review or waive the requirement.

## Work through obstacles

The agent treats a recoverable failure as a problem to solve: diagnose it,
use an available equivalent or make a bounded reversible repair, and continue
useful independent work. It adapts the means while preserving the confirmed
outcome and required evidence.

Routine choices do not need another approval. Real gaps in authority or
capability still need a precise handoff after useful authorized alternatives
have been exhausted. Required reviews still apply to materially revised plans.

Use the project's established delivery and environment-promotion process.
Planning does not add speculative operator preflights, predicted resource or
diff allowlists, approval gates, scripts or pipelines. Preserve required checks,
inspect actual results, and investigate observed interference or material risk.

## Verify, learn and replan

After each delivered increment, compare actual evidence with both that increment
and the overall objective. Retain useful learning, revise the remaining plan and
obtain fresh reviews before the next dependent increment. Failed verification
does not count as delivery.

The agent stops when the objective's evidence is satisfied, or reports the exact
remaining blocker after exhausting useful authorized work. A commit, green CI or
publication establishes only its own stage.

[Read the skill reference and full source](../skills/planning/outcome-led-planning/).
