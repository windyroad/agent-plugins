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

If outcome information is missing, the agent asks one focused question and waits for
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

Planning and contribute share one project configuration. The agent reads the
project-declared location, or `.agents/planning.json` by default. After confirming
the outcome, it reuses a saved or explicit choice. With no choice, it asks
**GitHub Issues or Local?**, waits for your answer, then saves and reads it back.
Fresh sessions and both skills reuse that choice without asking again.

```json
{"version": 1, "backend": "local"}
```

Ask to change the choice when needed. The agent preserves unrelated settings and
contributor mappings. Invalid or unsupported settings remain intact while the
needed repair is clarified. Configuration grants no access or messaging authority.
If the runtime protects the default directory, use a writable project-declared
location such as `planning.json`; a denied write does not establish persistence.
Local planning needs no GitHub account or Project.

Saved tracking choices, contribute and the workflow below require planning
**0.4.0 or later**, or ITIL **3.4.0 or later** for the planning compatibility
command. [Update your installed plugin](../updating/) before relying on them.
The standalone planning package provides both skills; ITIL retains its planning
entrypoint.

The agent reads a bundled coordination protocol when GitHub tracking is
selected. The linked issues become the shared plan. An optional GitHub Project
mirrors those same issues. Existing architecture decisions, jobs and risk
policies continue to govern their own domains. Moving a local plan into Issues
requires a recorded handover and current revision, so agents retain one
source of planning authority.

### Set up a selected Project

Using a Project is optional. Once selected or required by the project, its setup
and updates are part of delivery. The agent reuses equivalent existing setup and
custom views. For a new Project, the defaults are:

- **Outcomes:** a table filtered to `label:kind:outcome`, with status, ownership,
  agent identity and sub-issue progress.
- **Increments:** a table filtered to `label:kind:increment`, grouped by Horizon
  in Now, Next, Later order, with status, ownership, agent identity, linked pull
  requests and progress. Closed increments remain accessible without an active
  Horizon.
- **Tasks:** a board filtered to `label:kind:task`, with Status columns and cards
  showing ownership, agent identity, parent issue and linked pull requests.

A default unfiltered View 1 does not satisfy this setup. Each real issue needs
its kind marker and explicit Project membership, plus applicable native fields
and relationships. The agent saves changed view settings, reopens the views and
checks persisted settings and real item visibility before reporting success.
It preserves existing mappings and history, and creates no dummy test issues.

If an operation is unavailable, the existing increment records the exact pending
setting and recovery action. Useful authorized issue work can continue while
that gap remains visible. The agent revisits it at the next work checkpoint and
does not claim selected setup is complete on issue-only evidence.

### Use outcome, increment and task issues

- **Outcome:** the confirmed SMART result, completion evidence, constraints and
  timeframe. Its owner maintains the authoritative current Now, Next and Later
  sequence and plan revision, with increment links.
- **Increment:** one coherent result and its bounded plan, acceptance criteria,
  assumptions, dependencies, reviews and contribution tasks. Link it to the
  outcome's current plan and context. Its owner coordinates delivery and verifies
  the whole increment.
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
in increment acceptance. Obtain independent architecture, Jobs To Be Done (JTBD),
risk, cognitive accessibility and planning reviews before executing a materially
revised plan.

### Join and contribute safely

Invoke `/wr-planning:contribute` in Claude Code or `$wr-planning:contribute` in
Codex to find useful direct or indirect help within the assessed Now. It reuses
the saved tracking choice. Contributors pull bounded work just before starting;
the owner exposes opportunities and dependencies without reserving the backlog.

Local contributions record ownership, bounded work, results and handoffs in the
existing local plan. For GitHub tracking, the contributing agent uses its own
authorized account and follows these steps.

1. Read the outcome, current increment revision, shared discussion, existing
   tasks and dependencies. Check for overlapping work and stale assumptions.
2. Hold at most one contribution claim. Finish it, obtain an acknowledged
   handover or verify its release before claiming another. A blocked assignment
   still counts until its removal is saved and read back. Do not reserve queued
   tasks. Outcome or increment coordination ownership does not reserve tasks.
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
input is unavailable and no useful in-task step remains. Assigned watcher duties
count as useful work; routine discussion reads alone do not retain an exhausted
implementation claim. Record the blocker, evidence, unlock condition and
handover, then remove the assignment and read back its removal. Preserve
historical attribution. Keep the task Blocked and leave
independently actionable work Ready/Unclaimed so another agent can contribute.

Each contributor uses their own existing access. Assignment does not grant
additional permissions. Keep shared records aligned at these checkpoints:

- **Join, resume or start:** reconcile task and increment scope, owner, status
  and next action before dependent implementation. Verify that saved issues and
  actual Project fields match current work.
- **Material milestone or failed verification:** record the result, evidence and
  next action. Keep In progress while useful repair remains possible. Link the
  actual result and read back the update.
- **Plan, dependency or horizon change:** reconcile briefs, native relationships
  and increment horizons. Verify that saved links, fields and the current
  assessed revision agree. Material plan revisions still need their reviews.
- **Block, hand off, finish or yield:** record the remaining gap and next
  owner/action, or acceptance evidence. Verify the saved handoff or completion
  record and retain unresolved operations.

For a selected Project, these transitions also update its actual Status and
Agent fields and increment-only Horizon. Reconcile each item's own verified
owner; a task contributor does not replace the increment owner. Read back each
affected issue and its Project fields, including after later completion or
handoff edits. Labels, body text, local notes and successful commands alone do
not prove that Project fields changed. Record meaningful changes; unchanged checks need
no duplicate heartbeat comments.

Revisit a pending Project operation at the next checkpoint using fresh capability
evidence. A lost browser binding does not establish that every authorized route
is unavailable. Keep the exact gap visible during handoff or completion reporting,
and continue useful authorized work without claiming synchronization succeeded.

Coordinate replaced or dropped work with the increment owner and affected task
owners. Close redundant tasks as **not planned**, with reasons and successor
links. Preserve required acceptance evidence and prerequisites before removing
an obsolete dependency; verify saved changes. Preserve retired tasks' Agent
attribution and history, updating only fields needed to reflect their retirement.

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

Obtain independent architecture, JTBD, risk, cognitive accessibility and planning
reviews before executing a materially revised plan. A scoped contribution inside
the existing assessed revision does not need another full planning cycle. Close the outcome only when its confirmed evidence
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
them. Five independent critics assess each initial or materially revised
executable plan: architecture, JTBD, risk, cognitive accessibility and planning.
Substantive failures are resolved before dependent work. When a
required independent review is unavailable, hold dependent implementation and
continue useful authorized preparation. An ordinary go-ahead does not supply
that review or waive the requirement.

The planner does not add speculative risk-mitigation tasks. The risk scorer
identifies necessary treatments from the applicable risk policy and register.
Existing required controls remain binding; agent availability or discomfort does
not justify precautionary work.

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

Before declaring an increment complete, its owner obtains a bounded independent
acceptance check through the planning critic. Reuse an equivalent check that
already covers the criteria. The critic inspects actual results and affected
authoritative plan and saved records, including selected Project state. A summary
or PASS label alone is insufficient. The owner retains the final acceptance
decision. Repair and recheck discrepancies before marking Done; keep completion
unverified when required results or the reviewer are unavailable. Individual task
completion does not trigger this increment check or another five-critic cycle.

After a verified increment, compare its results with the overall objective.
Retain useful learning, revise the remaining plan and obtain fresh reviews
before the next dependent increment. Failed verification does not count as
delivery.

The agent stops when the objective's evidence is satisfied, or reports the exact
remaining blocker after exhausting useful authorized work. A commit, green CI or
publication establishes only its own stage.

[Read the skill reference and full source](../skills/planning/outcome-led-planning/).
