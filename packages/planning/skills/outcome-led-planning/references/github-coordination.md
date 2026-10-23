# Coordinate an outcome through GitHub

Use this protocol only when GitHub tracking is selected. Preserve the confirmed SMART outcome, existing project rules and the five independent plan critics for initial/material executable plan revisions. GitHub does not replace those reviews or grant authority to act on other people's resources.

## Establish one shared plan

Read the repository's instructions and existing planning records. Confirm the repository and outcome issue from supplied context before writing. Use each contributor's own authenticated account and existing permissions. Inspect available tools, issue features, labels, Project fields and access instead of assuming support or requesting broader access by default.

Use GitHub Issues as the authoritative outcome plan when that is the agreed tracking choice. An optional GitHub Project mirrors those same issues for visibility; it is not a second plan. Existing architecture decisions, jobs, risk policy and technical documents remain authoritative in their own domains. If moving an existing plan into Issues, record the handover, current revision and links in both places before retiring the former plan. Do not silently migrate records or create competing plans.

Before creation, search existing open and closed issues and read likely matches. Reuse the correct existing records. After a timed-out or otherwise ambiguous mutation, read the exact remote state before retrying. Use a stable task/session marker to reconcile uncertain creates; never blindly duplicate an issue, comment, assignment or Project update.

## Bootstrap GitHub tracking

Inspect before changing setup: the chosen repository/owner, authenticated actor,
permissions, planning configuration, linked Project, labels or issue types,
fields/options, saved views and relevant built-in workflows. Reuse equivalent
existing mappings and custom organization; names alone do not establish that
something is missing. Preserve IDs, existing options, labels, colours, layouts
and user-saved filters. Setup intent grants no new credentials, owner scope or
public visibility. Use supported APIs/CLI or an authorized browser, not guessed
view mutations or new access grants.

Project fields and views apply **only when Project tracking is selected or
repository-required**. Reuse the configured Project; create one only when that
choice requires it, none exists and existing authority permits it. GitHub
Issues-only and conversation/local tracking need no Project, views or fields.
Once selected or required, Project setup and updates are part of delivery.
Optional describes the choice to use a Project, not permission to skip that
choice after it is made. Complete missing applicable setup at the first work
checkpoint using available authorized tools. A default unfiltered View 1 is not
equivalent to the three kind-specific views below. If setup cannot be completed,
record the exact missing settings and next recovery action on the existing
increment; keep setup incomplete until its saved state is verified.
For shared Project tracking, reuse the same project-declared configuration
(default `.agents/planning.json`), following the shared project-tracking
preservation rules. Create or update only needed settings: `version: 1`, `backend: github`,
`github.repository`, `github.projectUrl` and `contributors` entries mapping each
actual contributor's `agent` and responsible `human`. Derive identities and URLs
from verified context; store no tokens or connection identifiers. Agent and human
may be the same account. Record different semantic mappings in existing project
guidance/configuration, not another registry.

Create only missing essentials, using these defaults when no equivalent mapping
is established:

- **Record kinds:** `kind:outcome`, `kind:increment`, `kind:task` labels. Reuse an
  existing equivalent issue-type/label mapping; do not migrate organization issue
  types or add a duplicate Kind field merely to follow this convention.
- **Increment horizons:** `horizon:now`, `horizon:next`, `horizon:later` labels,
  mirrored by the Horizon field. Each open planned increment has one horizon;
  outcomes/tasks have none. Clear completed/superseded increments' active horizons.
- **Status:** single-select Ready, In progress, Blocked, Reviewing, Done. An
  established equivalent such as Todo for Ready is valid. Add missing semantic
  options without replacing existing option IDs or unrelated configured values.
- **Horizon:** single-select Now, Next, Later; **Agent:** text containing the exact
  distinct agent/session or Unclaimed. Reuse native Title, Assignees, Parent
  issue, Sub-issues progress and Linked pull requests fields. Add no default
  priority, estimate, iteration or date fields without an outcome-specific need.

Create a saved view only when its equivalent is missing. These are **new-Project
defaults**, not instructions to reset existing saved layouts or filters:

1. **Outcomes:** table, filter `label:kind:outcome`; show Title, Status, Assignees,
   Agent and Sub-issues progress.
2. **Increments:** table, filter `label:kind:increment`; group by Horizon
   ordered Now/Next/Later; show Title, Parent issue, Horizon, Status, Assignees,
   Agent, Linked pull requests and Sub-issues progress. Retain closed increments
   without an active Horizon so delivery history remains accessible.
3. **Tasks:** board, filter `label:kind:task`; use Status columns and show Title,
   Assignees, Agent, Parent issue and Linked pull requests on cards as available.

Preserve existing custom views and access to closed/history records. Show
hierarchy only where it does not leak unrelated record kinds into a filtered
view; inspect actual visible items. No mandatory roadmap or per-agent view.

Apply each real issue's correct kind marker and explicitly add it to the selected
Project when creating it. Set native parent/sub-issue and genuine blocked-by
links, relevant Status/Agent and increment-only Horizon; read back the actual
saved issue and Project fields. Kind alone does not add Project membership, and
membership alone does not satisfy a saved kind filter. Verify both, then check
that the legitimate record appears in its intended view. Do not create dummy
issues to test setup or add an auto-add workflow in place of explicit membership.

Inspect relevant existing built-in automation for effects conflicting with
verified closure or manual ownership. Do not silently disable/replace it, enable
auto-close/archive or add recurring jobs/GitHub Actions merely for bootstrap.

Save changed layouts, filters, grouping and visible fields, then reopen the view
or read its persisted configuration. Verify the Project link, semantic
fields/options, view names/layouts/filters/grouping/columns and the first real
issues' kind, membership and native relationships when those issues exist.
A temporary unsaved view,
accepted API request or empty item list does not prove setup. A second pass
reuses complete setup and creates nothing. If permission or tooling cannot
configure or inspect a specific setting, record that exact gap and pending mirror;
preserve issue-side truth and continue useful authorized work. Do not claim a
view property that was not inspected or block all work on an optional mirror.

Use GitHub's current controls for [managing and saving views][github-views],
[table fields/grouping][github-table], [board columns/cards][github-board] and
[view filters][github-filters].

[github-views]: https://docs.github.com/en/issues/planning-and-tracking-with-projects/customizing-views-in-your-project/managing-your-views
[github-table]: https://docs.github.com/en/issues/planning-and-tracking-with-projects/customizing-views-in-your-project/customizing-the-table-layout
[github-board]: https://docs.github.com/en/issues/planning-and-tracking-with-projects/customizing-views-in-your-project/customizing-the-board-layout
[github-filters]: https://docs.github.com/en/issues/planning-and-tracking-with-projects/customizing-views-in-your-project/filtering-projects

## Outcome → increment → task

Use three linked issue levels, without introducing an epic or story tier:

| Record    | Owns               | Minimum shared information                                                                                                                               |
| --------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Outcome   | Outcome owner      | Its recorded owner, confirmed SMART result, acceptance evidence, constraints, deadline, ordered increment links and current plan revision |
| Increment | Increment owner    | Its recorded owner, intended result, horizon, own revision and acceptance (known or explicitly unresolved), assumptions/dependencies, contribution tasks; five critic results for executable work and delivery evidence when delivered |
| Task      | Contributing agent | Its recorded owner/account and distinct agent/session, parent increment, bounded scope, own revision and acceptance, dependencies, status and completion evidence when complete |

Do not infer a child owner from its parent. On tasks, identify the actual account and distinct agent/session. The outcome owner maintains the goal and replans across increments; an increment owner coordinates delivery within that revision. Delegation and ownership transfers require an explicit recorded handoff. Ordinary unclaimed or provisional work needs no human ownership question: contributors resolve their own task ownership by claiming it. Resolve genuinely ambiguous outcome/increment responsibility before dependent coordination; ask one missing ownership question only when it cannot be established from existing direction. Do useful independent work meanwhile.

Keep the planning responsibilities distinct:

- **Outcome issue:** owns the authoritative current Now/Next/Later plan and its revision: one coherent Now increment, with Next and Later provisional.
- **Increment issue:** owns its bounded result, revision, acceptance and task execution plan, with one horizon. Link to the outcome plan or other increments for context. Remove or clearly mark superseded any copied cross-increment plan still presented as current.
- **Replacing Now:** reconcile the outcome and affected increment records to the approved revision, carrying forward its provisional Next/Later without requiring their completion evidence. Preserve superseded history. Read back both bodies and compare their current plan, scope and ownership with that revision; fetching the records alone is not verification. Treat a needed change to the assessed sequence as replanning under the existing assessment rules, rather than silently changing it during routine reconciliation.

Give the existing planning critic the saved outcome and affected increment records, relevant tasks and any selected Project setup evidence claimed by the plan. After saving the proposed or revised records, resolve concrete record discrepancies and have the critic recheck the saved repairs before dependent work. Reuse the existing review; routine checkpoint updates do not require another five-critic cycle.

**Horizon belongs only to increments**: each planned or active increment has exactly one of Now, Next or Later. Remove completed or superseded increments from active horizons while preserving their prior position in history. **Status** separately describes execution, such as ready, in progress, blocked or done. A blocked Now increment does not automatically become Next; a completed task does not become a completed outcome. Outcomes and tasks do not inherit Horizon. Map these meanings to existing repository labels or Project fields. Replace the previous horizon when replanning rather than accumulating contradictory values.

Maintain parent/child and prerequisite relationships in this order:

1. Inspect the actual relationship and the precise result that unlocks a start,
   stage or completion. Read current native sub-issue and blocked-by state when
   supported. A native write denial proves neither presence nor absence:
   preserve known links and keep unreadable native state unknown.
2. Keep completion dependencies acyclic. A prerequisite cannot require its
   dependent's result to close. Propose changed task boundaries and acceptance
   in the increment thread; the increment owner records agreement with affected
   task owners before applying them. Obtain the five independent reviews before
   materially revised execution. Give each task an independently verifiable
   result and retain the combined results in increment acceptance.
3. After any required agreement and reviews, use native links when supported;
   create a missing required link or update a changed one when authorized.
   Verify saved native state and both relationship directions. If operations are
   unavailable, record their exact limitation plus reciprocal parent/child or
   prerequisite/dependent text links on both affected issues; text is not proof
   of native state. Request capable help through an authorized channel when
   useful, without inventing a helper or widening access.
4. Reassess actual useful work and status under the claim table below. A Ready
   or In progress task may prepare while a real prerequisite remains open;
   preserve its precise unlock condition and required evidence. Independently
   verify the prerequisite result before clearing that condition and proceeding
   with the dependent stage. Administrative issue closure is not another
   prerequisite unless recorded acceptance or a project rule requires it.

Optional Project membership and fields mirror issue state; do not create them
merely because this protocol mentions them.

Replan task boundaries at any stage when evidence changes what work is needed. Coordinate narrowed, split, replaced or dropped scope with the increment owner and affected task owners. Close redundant or superseded issues as **not planned**, with the reason and successor links; never mark undelivered work Done merely to retire it. Before removing a dependency, move still-required acceptance evidence to the appropriate task and retain it in increment acceptance. Remove only genuinely obsolete native dependencies and verify the saved result; preserve prerequisites that still constrain the revised work. Keep task briefs, links, ownership and any selected Project fields current. Routine task reconciliation within the assessed outcome and authority needs no new user approval; materially revised executable work still requires the five independent plan reviews.

### Status and contribution-claim decision

Use this table whenever work starts, blocks, finishes or is handed over. Inspect
scope, inputs and actual useful authorized in-task steps first: a stored Blocked
status alone does not establish exhaustion. Genuine assigned watcher duties
count as useful work; waiting for an unverified response or routine discussion
reads alone do not retain an exhausted implementation reservation.

| Actual state of the claimed task | Status | Assignment and saved result |
| --- | --- | --- |
| Recorded acceptance is verified with evidence | Done | Post acceptance evidence, finish and preserve attribution history. |
| Useful authorized in-task work remains | In progress | Retain the single claim and do that work. |
| A required input is unavailable and no useful authorized in-task step remains | Blocked | Save the blocker, evidence, unlock condition and handover; remove your assignment and read back its removal. Preserve historical attribution. |

One contribution claim is a ceiling, not a retention requirement. A blocked
assignment still counts until release is verified. Apply the table before
claiming another task; never reserve queued tasks. Outcome/increment ownership
does not reserve contributions. Agents sharing an account remain distinct by
their recorded agent/session. Keep actionable unclaimed work Ready/Unclaimed;
a blocked task does not block every contribution. Never invent busywork.

If assignment mutation or verification is unavailable, record the exact pending
release and known claim state, use an authorized owner/channel when available,
and do not claim release or take another task while still assigned. Reassess
when evidence changes.

## Join, claim and contribute

Use this contribution lifecycle:

1. Read the outcome, current Now revision, discussion, dependencies and claims. Reconcile stale scope before dependent work.
2. Choose a bounded useful result and announce its acceptance and file/operation boundary in the increment thread. Resolve overlap, shared operations or authority questions with affected owners. A non-overlapping task within the assessed Now needs no allocator approval.
3. Reuse a matching unclaimed task, or create your own just before work. Apply the established task-kind marker (`kind:task` by default). Assign it to the **actual authenticated account** and record the **specific agent/session** and native links; read back kind, assignment, claim and links and recheck competing work. For a selected or required Project, explicitly add the task and read back its membership and applicable fields so it matches the saved view.
4. Execute within the assessed plan and authority; apply the status and contribution-claim decision above, including saved release when exhausted.
5. Choose and document the next useful contribution from the remaining outcome gap, then repeat these checks before claiming it.

A starting battle plan exposes likely work, dependencies and parallel opportunities without precreating, assigning or reserving every future task. The increment owner keeps acceptance, sequence and integration clear and resolves overlap/dependencies. Explicit assignments and handoffs remain valid. Two agents sharing an account are distinct contributors. Checklists suffice for routine steps; do not create a task for every command. Task creation within assessed scope requires no fresh human approval.

Before declaring a contribution ready to start, complete this claim receipt: **no other contribution assignment held; parent increment; current assessed plan revision; non-overlapping scope; dependencies (or explicitly none); actual account; distinct agent/session; saved claim and reciprocal-link readback; competing-claim recheck.** Record all fields on the task, even when some are already known in conversation. Assignment does not increase authority. When explaining a proposed claim, make these required fields and the before/after overlap checks explicit.

Record scope boundaries and dependencies, then read back the claim, links and any competing claims. Issue claims are cooperative, not atomic locks: another agent may have claimed overlapping work since your first read. Reconcile that race before dependent implementation. If another contributor has claimed the same work, agree a split or handoff in the increment thread before overlapping implementation. An inactive or old claim is not permission to take over silently. If assignment is unavailable, record the intended owner and unassigned state, request the owner’s help through the agreed coordination channel when authorized, and continue only work whose ownership is clear. Never claim an assignment or board update succeeded without reading it back.

## Reconcile tracking at work checkpoints

During an active work window, follow this coordination sequence while coding
or waiting:

1. Use the agreed, saved discussion-reading cadence. If none exists, propose a
   bounded cadence through the authorized increment thread, obtain agreement
   and verify its saved record. While agreement is pending, continue regular
   bounded reads; a proposal is not agreement.
2. Also read new increment comments on joining/resuming and at the event
   checkpoints below, including before dependent actions, pushes, scope or
   ownership changes and handovers. Regular reads and event reads are both
   required; neither replaces the other.
3. Answer relevant questions and handle handoffs through the authorized channel
   and handoff rules below: actual recipient
   acknowledgement and linked task, independent verification of returned
   evidence, and updates to your task's evidence, dependency and next action.
   A posted message is not the recipient's acknowledgement.
4. If the result materially changes the executable plan, reconcile that revision
   and obtain the five independent reviews before dependent execution. Otherwise
   continue within the assessed plan. Apply the claim table when work is
   exhausted rather than retaining it for discussion reads.

These are bounded checks during active work, not a standing poller or a promise
to wake an idle agent. Use only already-authorized communication channels.

At each work checkpoint, reconcile tracking in this order:

When the affected records include an outcome, current Now, provisional Next and
a task, and `gh` works, MUST first use the [read-only hierarchy inspector](github-project-checkpoint.md#inspect-the-hierarchy).
Construct its request from those actual records and consume its findings before
claiming completeness; identical draft/remote text is not that comparison.
Do not manufacture a Next issue for this route. Its configuration report is one
source for the selection decision below, not proof of capability or acceptance.

1. **Establish selection before checking Project capability.** Reuse the
   established backend. From configuration, project requirements or explicit
   direction, choose the applicable branch:
   - **Selected/required:** verify the repository, Project and account, then
     inspect its saved setup and applicable operations. For join/resume of an
     active open task with working `gh`, MUST use the [executable Project checkpoint](github-project-checkpoint.md).
     Read its inspection and handle current discussion before applying it;
     do not manually publish synchronization-success text on that route.
     If an applicable operation is unavailable, retain its exact pending state
     under the recovery rules below. An unavailable API or bootstrap default
     does not prove a missing view, field or membership.
   - **Established none:** continue issue-side reconciliation without Project
     setup, fields or synchronization.
   - **Unresolved:** inspect available configuration, requirements, direction and
     issue records. Record the selection gap and keep Project work conditional;
     there is no established mirror operation to report pending or unsynchronized.
     Omitted information and API availability establish neither selection nor
     an explicit choice to use no Project.
2. **Inspect each affected record before classifying it.** Compare every
   outcome, increment and task with the minimum-information table. Preserve its
   own recorded owner/account, applicable agent/session, revision and acceptance,
   including provisional and completed records. Mark a required value unresolved
   only when inspection cannot establish it; omission from a scenario or summary
   does not establish that saved information is missing. Completion evidence
   does not replace the task's own revision or acceptance. Provisional ownership,
   revision and tentative acceptance imply neither an executable plan nor
   critic approval or completion evidence.
   Record actual scope, status, increment-only Horizon, dependencies/blocker,
   next action and state-appropriate evidence. For a selected/required Project,
   each item's Agent remains its verified owner/session, never an identity
   copied from its parent or child; Status reflects that item's actual work.
3. **Update and verify.** Make only necessary authorized changes to existing
   records. Read back every changed issue's fields and links, checking both
   directions of parent/dependency relationships. For a selected or required
   Project, separately read back each affected item's actual Status, Agent and
   applicable Horizon, including previously blank fields. A successful command,
   issue label, body text, local note or chat does not prove Project fields
   changed. Report reconciliation only to the extent verified; retain unresolved
   operations in the existing issue/plan record. When nothing changed, inspect
   and reuse saved state instead of posting another comment.

Share cross-task changes through the authorized increment thread. Do not post
unchanged heartbeats, copy private chat history or introduce another receipt
system.

| Checkpoint | Required reconciliation |
| --- | --- |
| Join, resume or start implementation | Read current records and discussion; correct stale status, scope and ownership before dependent implementation. Set the active task and increment In progress when useful work starts. Complete missing selected Project setup or record its precise unavailable operation. |
| Material milestone or failed verification | Record the actual result and evidence before the next dependent action. Keep In progress while useful repair remains; a failed check alone does not mean Blocked. |
| Scope, dependency, plan or horizon change | Update affected briefs, native relationships and increment horizons; remove superseded active horizons. Obtain the required reviews before materially revised execution. |
| Block, hand off, finish or yield the active work window | Apply the claim table, saving the gap, next action/owner or acceptance evidence and verifying any required release. Reconcile the increment as well as the task; do not leave stale status or next action. |

For a selected or required Project, when an operation is unavailable, record
the affected view/field/item,
actual work state, exact tool/access failure and next recovery action on the
existing increment. Revisit that pending operation at the next checkpoint using
fresh capability evidence; a stale browser binding or missing dedicated tool is
not proof that every authorized route is unavailable. Verify the target
repository, Project and account before using another tool. Do not repeat an
ambiguous mutation without readback, widen access or erase another owner's
settings. Continue useful authorized issue-side work while the mirror is
pending, but do not report selected setup or synchronization complete. Surface
the unresolved tracking gap when handing off or reporting completion.

A task assignment, issue comment or peer request does not expand access or authorize new external effects. Keep repository changes isolated, preserve others' edits and follow the project's integration rules. Trunk-based projects reconcile with current main and push normally; never force-push over another contributor to resolve a race.

## Discuss and hand off in the increment

The increment issue thread is the shared conversation across accounts and agents. Keep task-local details on the task; post cross-task questions, blockers, findings, requests, handoffs and proposed plan changes on the increment. Put substantive goal changes on the outcome for user confirmation before dependent planning.

A coordination message should include:

- Agent/session identity, task link and plan revision.
- Recipient and concrete request, or the blocked dependency.
- Relevant evidence and the next action needed.

Use existing shared records and already-authorized communication channels. Choosing a tracker does not independently authorize messages to people or other sessions; follow the host's communication rules and the user's granted authority. When a message needs additional authority, prepare the exact message and continue independent work before requesting it. Do not post private chats, credentials, tokens or sensitive customer details.

A handoff request is incomplete without identifying the upstream and dependent task links, current revision, requested evidence and recipient. Explicitly ask the receiving contributor to acknowledge in the shared thread and link the task that will address it; include these steps when explaining the proposed handoff. The receiving contributor then acknowledges and supplies that link. The dependent owner independently verifies returned evidence before clearing a blocker. An unsupported assertion of completion does not close a dependency. Link the handoff and resulting evidence in both relevant tasks.

Comments and mentions **do not guarantee an idle agent wakes up**. State that limitation; do not promise automatic execution. Do not create standing pollers, scheduled jobs, messaging infrastructure or an orchestration service without explicit authorization.

When an authorized owner must complete a pending Project operation, request it through the agreed channel only when messaging is authorized. Obtain the actual saved field/view readback before claiming synchronization; a posted request does not establish that the owner acted.

## Verify, learn and replan as the outcome owner

Post acceptance evidence before completing a task. Preserve its actual recorded acceptance: do not invent a later release check as a repair-task completion condition, or remove an established condition to finish early. At handoff, apply the claim table; an explicit ownership transfer additionally needs the identified recipient's acknowledgement. Do not report both releasing and retaining the same claim. The increment owner verifies the whole increment against its criteria before closing it; task completion alone does not establish delivery. Publication, installed behavior and production/customer verification remain separate evidence stages where applicable.

After a verified increment, or earlier when evidence invalidates the plan, the outcome owner:

1. Compares evidence with the confirmed outcome and records what changed understanding.
2. Rewrites the current plan revision and increment sequence from the remaining gap. Reorders, splits, replaces or drops speculative work rather than mechanically promoting Next.
3. Updates the Now/Next/Later assignment on increment issues and removes superseded horizons. Reconciles the optional Project mirror and records any update it could not make.
4. Iterates the materially revised executable plan with the five independent critics in the planning skill before dependent execution. Scoped contributions inside the assessed revision do not each trigger full replanning.
5. Records reassigned, dropped or superseded tasks with their reasons and explicit ownership handoffs, preserving history and evidence.

Close the outcome only when its confirmed acceptance evidence is satisfied. Stop unnecessary work. A tidy Project board, merged change or all tasks marked done does not replace the user's result. If blocked, finish useful independent work, record exact missing authority/capability/evidence and the smallest action that unlocks progress, then resume from fresh evidence without repeating completed effects.
