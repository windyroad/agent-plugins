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
2. **Increments:** table, filter `label:kind:increment is:open`; group by Horizon
   ordered Now/Next/Later; show Title, Parent issue, Horizon, Status, Assignees,
   Agent and Sub-issues progress.
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
| Outcome   | Outcome owner      | Confirmed SMART result, acceptance evidence, constraints, deadline, ordered increment links and current plan revision                                    |
| Increment | Increment owner    | Intended result, horizon, executable plan revision, acceptance, assumptions/dependencies, five critic results, contribution tasks and delivery evidence  |
| Task      | Contributing agent | Parent increment, bounded scope, authenticated account plus distinct agent/session identity, plan revision, dependencies, status and completion evidence |

Record an explicit owner on every outcome, increment and task, or mark that owner unresolved. Do not infer a child owner from its parent. On tasks, identify the actual account and distinct agent/session. The outcome owner maintains the goal and replans across increments; an increment owner coordinates delivery within that revision. Delegation and ownership transfers require an explicit recorded handoff. Ordinary unclaimed or provisional work needs no human ownership question: contributors resolve their own task ownership by claiming it. Resolve genuinely ambiguous outcome/increment responsibility before dependent coordination; ask one missing ownership question only when it cannot be established from existing direction. Do useful independent work meanwhile.

Each outcome has one coherent **Now** increment. Next and Later remain provisional. **Horizon belongs only to increments**: each planned or active increment has exactly one of Now, Next or Later. Remove completed or superseded increments from active horizons while preserving their prior position in history. **Status** separately describes execution, such as ready, in progress, blocked or done. A blocked Now increment does not automatically become Next; a completed task does not become a completed outcome. Outcomes and tasks do not inherit Horizon. Map these meanings to existing repository labels or Project fields. Replace the previous horizon when replanning rather than accumulating contradictory values.

Use native sub-issue relationships when supported; otherwise record explicit reciprocal parent/child links and disclose the limitation. When another task supplies a required result, **create and verify its native blocked-by dependency** whenever the available API and permissions support it. Record real prerequisites even when they constrain a later stage or task completion rather than the next useful step. Name the precise start, stage or completion unlock condition and required evidence. A Ready or In progress task may retain open dependencies while useful preparation proceeds; those dependencies still gate the dependent stage or completion. Never remove a real dependency merely to make preparation available. If the native capability is unavailable or denied, record the exact limitation and reciprocal dependency links; do not claim native persistence. Reconcile both directions and read back the persisted records before claiming a relationship was established. For every planning mutation, verify the actual saved issue fields and links; an accepted request alone is insufficient. Preserve unresolved owner, revision or acceptance fields as explicitly unresolved, including on provisional increments, rather than fabricating them. Optional Project membership and fields mirror issue state; do not create a Project or fields merely because the protocol mentions them.

Keep completion dependencies acyclic. A prerequisite task cannot also require its dependent's result to close. Propose corrections in the increment thread; the increment owner records revised task boundaries and acceptance with affected task owners before applying them. Obtain the five independent plan reviews before executing a materially revised plan. Give each task an independently verifiable result and retain the combined results in increment acceptance. Reassess the dependent task when a prerequisite is satisfied; independently verify its evidence before clearing that condition.

Replan task boundaries at any stage when evidence changes what work is needed. Coordinate narrowed, split, replaced or dropped scope with the increment owner and affected task owners. Close redundant or superseded issues as **not planned**, with the reason and successor links; never mark undelivered work Done merely to retire it. Before removing a dependency, move still-required acceptance evidence to the appropriate task and retain it in increment acceptance. Remove only genuinely obsolete native dependencies and verify the saved result; preserve prerequisites that still constrain the revised work. Keep task briefs, links, ownership and any selected Project fields current. Routine task reconciliation within the assessed outcome and authority needs no new user approval; materially revised executable work still requires the five independent plan reviews.

Mark a task **Blocked only when no useful, authorized next step can proceed within its scope** because a specific required input, capability or dependency is unavailable. Investigable facts, obtainable reviews and later-stage prerequisites do not block useful current preparation. Keep active work In progress and actionable unclaimed work Ready. Preserve real prerequisites before their dependent action; never invent speculative work to avoid Blocked. Record the exact missing input and what unlocks it, and reassess status when evidence changes. A blocked task does not make every contribution blocked.

## Join, claim and contribute

Use this contribution lifecycle:

1. Read the outcome, current Now revision, discussion, dependencies and claims. Reconcile stale scope before dependent work.
2. Choose a bounded useful result and announce its acceptance and file/operation boundary in the increment thread. Resolve overlap, shared operations or authority questions with affected owners. A non-overlapping task within the assessed Now needs no allocator approval.
3. Reuse a matching unclaimed task, or create your own just before work. Apply the established task-kind marker (`kind:task` by default) and explicitly add it to the selected Project so the task matches its saved view. Assign it to the **actual authenticated account** and record the **specific agent/session**, native links and any selected Project fields; read back kind, membership and claim and recheck competing work.
4. Execute within the assessed plan and authority, keeping status and evidence current. Finish with verified evidence or release with a handover stating evidence, blocker and next step.
5. Choose and document the next useful contribution from the remaining outcome gap, then repeat these checks before claiming it.

A starting battle plan exposes likely work, dependencies and parallel opportunities without precreating, assigning or reserving every future task. The increment owner keeps acceptance, sequence and integration clear and resolves overlap/dependencies. Explicit assignments and handoffs remain valid. Two agents sharing an account are distinct contributors. Checklists suffice for routine steps; do not create a task for every command. Task creation within assessed scope requires no fresh human approval.

**Each agent holds only one contribution task at a time**, including a blocked assignment. Finish, explicitly hand over or release the current assignment before claiming another. Do not reserve queued tasks. Outcome or increment coordination ownership does not reserve contribution tasks. Agents sharing an account remain distinct through their recorded agent/session identities. When no useful authorized work remains in the task and a required input cannot currently be obtained, record the blocker, evidence and next step, then release the assignment with an explicit handover. Keep a genuinely blocked task Blocked and unassigned; leave independently actionable work Ready/Unclaimed so another agent can contribute without asking the former owner.

Before releasing a blocked assignment, reassess the task scope, available inputs and useful authorized next steps. Continue any such work. A stored Blocked status alone does not establish that no useful work remains; when exhaustion is unverified, state the condition rather than asserting it. Release with a handover only when the required input is unavailable and no useful authorized in-task step remains.

Before declaring a contribution ready to start, complete this claim receipt: **no other contribution assignment held; parent increment; current assessed plan revision; non-overlapping scope; dependencies (or explicitly none); actual account; distinct agent/session; saved claim and reciprocal-link readback; competing-claim recheck.** Record all fields on the task, even when some are already known in conversation. Assignment does not increase authority. When explaining a proposed claim, make these required fields and the before/after overlap checks explicit.

Record scope boundaries and dependencies, then read back the claim, links and any competing claims. Issue claims are cooperative, not atomic locks: another agent may have claimed overlapping work since your first read. Reconcile that race before dependent implementation. If another contributor has claimed the same work, agree a split or handoff in the increment thread before overlapping implementation. An inactive or old claim is not permission to take over silently. If assignment is unavailable, record the intended owner and unassigned state, request the owner’s help through the agreed coordination channel when authorized, and continue only work whose ownership is clear. Never claim an assignment or board update succeeded without reading it back.

Keep the claimed task current throughout delivery, not only when asked for status. Record its current scope and intended result, owner/account and distinct agent/session, execution status, dependencies or exact blocker, next useful action and verified progress/evidence. Update the brief and native links when prerequisites or scope change; promptly record material milestones, failures and handovers. Share changes affecting other contributors in the increment thread so the current work is understandable without private chat history. Report pending Project field updates honestly.

A task assignment, issue comment or peer request does not expand access or authorize new external effects. Keep repository changes isolated, preserve others' edits and follow the project's integration rules. Trunk-based projects reconcile with current main and push normally; never force-push over another contributor to resolve a race.

## Discuss and hand off in the increment

The increment issue thread is the shared conversation across accounts and agents. Keep task-local details on the task; post cross-task questions, blockers, findings, requests, handoffs and proposed plan changes on the increment. Put substantive goal changes on the outcome for user confirmation before dependent planning.

A coordination message should include:

- Agent/session identity, task link and plan revision.
- Recipient and concrete request, or the blocked dependency.
- Relevant evidence and the next action needed.

Use existing shared records and already-authorized communication channels. Choosing a tracker does not independently authorize messages to people or other sessions; follow the host's communication rules and the user's granted authority. When a message needs additional authority, prepare the exact message and continue independent work before requesting it. Do not post private chats, credentials, tokens or sensitive customer details.

A handoff request is incomplete without identifying the upstream and dependent task links, current revision, requested evidence and recipient. Explicitly ask the receiving contributor to acknowledge in the shared thread and link the task that will address it; include these steps when explaining the proposed handoff. The receiving contributor then acknowledges and supplies that link. The dependent owner independently verifies returned evidence before clearing a blocker. An unsupported assertion of completion does not close a dependency. Link the handoff and resulting evidence in both relevant tasks.

Read the increment thread when joining or resuming and regularly throughout active work, including coding and waiting. Check again before dependent actions, pushes, scope or ownership changes and handovers. Read relevant new comments, acknowledge handoffs and answer questions affecting your work through already-authorized channels; keep task records current with the resulting evidence or changes. Use the increment's agreed, recorded checking cadence throughout its active work window. If none is established, continue authorized bounded thread checks regularly throughout active work and at action checkpoints while proposing an appropriate bounded cadence through the authorized increment thread. Obtain agreement and verify its saved record; a suggested interval alone is not an agreed cadence. Pending cadence agreement does not suspend already-authorized bounded thread checks during active work or checks at existing action checkpoints. Record the pending agreement honestly and continue useful authorized preparation. Distinguish a posted message from the recipient's actual acknowledgement.

Comments and mentions **do not guarantee an idle agent wakes up**. State that limitation; do not promise automatic execution. Do not create standing pollers, scheduled jobs, messaging infrastructure or an orchestration service without explicit authorization.

When an optional Project is selected, keep its existing Status and Agent fields aligned with the actual work. Starting a contribution means setting its actual Project Status to In progress and recording the actual account and distinct agent/session. Verify the issue assignment and actual Project field values; issue labels or body text do not establish those fields. Use available authorized tools, CLI or an authorized operator rather than assuming a missing dedicated tool makes the update impossible. If access is unavailable, record the issue-side truth and the exact pending Status/Agent update. Request an authorized owner mirror it through the agreed thread when permitted and obtain the actual field readback before claiming board success. Continue useful authorized issue-side work while the mirror is pending. Missing optional board permission is not a reason to abandon all progress or invent credentials.

## Verify, learn and replan as the outcome owner

Post acceptance evidence before completing a task. The increment owner verifies the whole increment against its criteria before closing it; task completion alone does not establish delivery. Publication, installed behavior and production/customer verification remain separate evidence stages where applicable.

After a verified increment, or earlier when evidence invalidates the plan, the outcome owner:

1. Compares evidence with the confirmed outcome and records what changed understanding.
2. Rewrites the current plan revision and increment sequence from the remaining gap. Reorders, splits, replaces or drops speculative work rather than mechanically promoting Next.
3. Updates the Now/Next/Later assignment on increment issues and removes superseded horizons. Reconciles the optional Project mirror and records any update it could not make.
4. Iterates the materially revised executable plan with the five independent critics in the planning skill before dependent execution. Scoped contributions inside the assessed revision do not each trigger full replanning.
5. Records reassigned, dropped or superseded tasks with their reasons and explicit ownership handoffs, preserving history and evidence.

Close the outcome only when its confirmed acceptance evidence is satisfied. Stop unnecessary work. A tidy Project board, merged change or all tasks marked done does not replace the user's result. If blocked, finish useful independent work, record exact missing authority/capability/evidence and the smallest action that unlocks progress, then resume from fresh evidence without repeating completed effects.
