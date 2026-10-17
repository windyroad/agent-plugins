# Coordinate an outcome through GitHub

Use this protocol only when GitHub tracking is selected. Preserve the confirmed SMART outcome, existing project rules and independent architecture, JTBD and risk review of each executable plan revision. GitHub does not replace those reviews or grant authority to act on other people's resources.

## Establish one shared plan

Read the repository's instructions and existing planning records. Confirm the repository and outcome issue from supplied context before writing. Use each contributor's own authenticated account and existing permissions. Inspect available tools, issue features, labels, Project fields and access instead of assuming support or requesting broader access by default.

Use GitHub Issues as the authoritative outcome plan when that is the agreed tracking choice. An optional GitHub Project mirrors those same issues for visibility; it is not a second plan. Existing architecture decisions, jobs, risk policy and technical documents remain authoritative in their own domains. If moving an existing plan into Issues, record the handover, current revision and links in both places before retiring the former plan. Do not silently migrate records or create competing plans.

Before creation, search existing open and closed issues and read likely matches. Reuse the correct existing records. After a timed-out or otherwise ambiguous mutation, read the exact remote state before retrying. Use a stable task/session marker to reconcile uncertain creates; never blindly duplicate an issue, comment, assignment or Project update.

## Outcome → increment → task

Use three linked issue levels, without introducing an epic or story tier:

| Record | Owns | Minimum shared information |
| --- | --- | --- |
| Outcome | Outcome owner | Confirmed SMART result, acceptance evidence, constraints, deadline, ordered increment links and current plan revision |
| Increment | Increment owner | Intended result, horizon, executable plan revision, acceptance, assumptions/dependencies, three review results, contribution tasks and delivery evidence |
| Task | Contributing agent | Parent increment, bounded scope, authenticated account plus distinct agent/session identity, plan revision, dependencies, status and completion evidence |

Record an explicit owner on every outcome, increment and task, or mark that owner unresolved. Do not infer a child owner from its parent. On tasks, identify the actual account and distinct agent/session. The outcome owner maintains the goal and replans across increments; an increment owner coordinates delivery within that revision. Delegation and ownership transfers require an explicit recorded handoff. If ownership is unresolved, ask the one missing ownership question before dependent coordination; do useful independent work meanwhile.

Each outcome has one coherent **Now** increment. Next and Later remain provisional. **Horizon belongs only to increments**: each planned or active increment has exactly one of Now, Next or Later. Remove completed or superseded increments from active horizons while preserving their prior position in history. **Status** separately describes execution, such as ready, in progress, blocked or done. A blocked Now increment does not automatically become Next; a completed task does not become a completed outcome. Outcomes and tasks do not inherit Horizon. Map these meanings to existing repository labels or Project fields. Replace the previous horizon when replanning rather than accumulating contradictory values.

Use native sub-issue relationships when supported; otherwise record explicit reciprocal parent/child links and disclose the limitation. When another task supplies a required result, **create and verify its native blocked-by dependency** whenever the available API and permissions support it. Record real prerequisites even when they constrain a later stage or task completion rather than the next useful step. Name the precise start, stage or completion unlock condition and required evidence. A Ready or In progress task may retain open dependencies while useful preparation proceeds; those dependencies still gate the dependent stage or completion. Never remove a real dependency merely to make preparation available. If the native capability is unavailable or denied, record the exact limitation and reciprocal dependency links; do not claim native persistence. Reconcile both directions and read back the persisted records before claiming a relationship was established. For every planning mutation, verify the actual saved issue fields and links; an accepted request alone is insufficient. Preserve unresolved owner, revision or acceptance fields as explicitly unresolved, including on provisional increments, rather than fabricating them. Optional Project membership and fields mirror issue state; do not create a Project or fields merely because the protocol mentions them.

Keep completion dependencies acyclic. A prerequisite task cannot also require its dependent's result to close. Propose corrections in the increment thread; the increment owner records revised task boundaries and acceptance with affected task owners before applying them. Obtain architecture, JTBD and risk review before executing a materially revised plan. Give each task an independently verifiable result and retain the combined results in increment acceptance. Reassess the dependent task when a prerequisite is satisfied; independently verify its evidence before clearing that condition.

Replan task boundaries at any stage when evidence changes what work is needed. Coordinate narrowed, split, replaced or dropped scope with the increment owner and affected task owners. Close redundant or superseded issues as **not planned**, with the reason and successor links; never mark undelivered work Done merely to retire it. Before removing a dependency, move still-required acceptance evidence to the appropriate task and retain it in increment acceptance. Remove only genuinely obsolete native dependencies and verify the saved result; preserve prerequisites that still constrain the revised work. Keep task briefs, links, ownership and any selected Project fields current. Routine task reconciliation within the assessed outcome and authority needs no new user approval; materially revised executable work still requires the applicable architecture, JTBD and risk reviews.

Mark a task **Blocked only when no useful, authorized next step can proceed within its scope** because a specific required input, capability or dependency is unavailable. Investigable facts, obtainable reviews and later-stage prerequisites do not block useful current preparation. Keep active work In progress and actionable unclaimed work Ready. Preserve real prerequisites before their dependent action; never invent speculative work to avoid Blocked. Record the exact missing input and what unlocks it, and reassess status when evidence changes. A blocked task does not make every contribution blocked.

## Join, claim and contribute

Before joining or resuming, read the outcome, current increment revision, increment discussion, existing tasks, dependencies and claims. Check for overlapping work before creating a contribution. Work against the current assessed revision; if your planned scope is stale, reconcile with the owner before dependent implementation.

Create one task for a separately owned contribution within the authorized, assessed increment. Assign it to the **actual authenticated GitHub account**, and record the **specific agent/session** in the task body or claim comment. Two agents sharing an account are distinct contributors. Checklists suffice for small internal steps; do not make a task for every command. An agent may create and claim a non-overlapping task within the assessed plan without another user approval ceremony.

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

Read the increment thread when joining or resuming and regularly throughout active work, including coding and waiting. Check again before dependent actions, pushes, scope or ownership changes and handovers. Read relevant new comments, acknowledge handoffs and answer questions affecting your work through already-authorized channels; keep task records current with the resulting evidence or changes. Use the increment's agreed, recorded checking cadence throughout its active work window. If none is established, propose an appropriate bounded cadence through the authorized increment thread, obtain agreement and verify its saved record; a suggested interval alone is not an agreed cadence. Pending cadence agreement does not suspend already-authorized bounded thread checks during active work or checks at existing action checkpoints. Record the pending agreement honestly and continue useful authorized preparation. Distinguish a posted message from the recipient's actual acknowledgement.

Comments and mentions **do not guarantee an idle agent wakes up**. State that limitation; do not promise automatic execution. Do not create standing pollers, scheduled jobs, messaging infrastructure or an orchestration service without explicit authorization.

When an optional Project is selected, keep its existing Status and Agent fields aligned with the actual work. Starting a contribution means setting its actual Project Status to In progress and recording the actual account and distinct agent/session. Verify the issue assignment and actual Project field values; issue labels or body text do not establish those fields. Use available authorized tools, CLI or an authorized operator rather than assuming a missing dedicated tool makes the update impossible. If access is unavailable, record the issue-side truth and the exact pending Status/Agent update. Request an authorized owner mirror it through the agreed thread when permitted and obtain the actual field readback before claiming board success. Continue useful authorized issue-side work while the mirror is pending. Missing optional board permission is not a reason to abandon all progress or invent credentials.

## Verify, learn and replan as the outcome owner

Post acceptance evidence before completing a task. The increment owner verifies the whole increment against its criteria before closing it; task completion alone does not establish delivery. Publication, installed behavior and production/customer verification remain separate evidence stages where applicable.

After a verified increment, or earlier when evidence invalidates the plan, the outcome owner:

1. Compares evidence with the confirmed outcome and records what changed understanding.
2. Rewrites the current plan revision and increment sequence from the remaining gap. Reorders, splits, replaces or drops speculative work rather than mechanically promoting Next.
3. Updates the Now/Next/Later assignment on increment issues and removes superseded horizons. Reconciles the optional Project mirror and records any update it could not make.
4. Obtains architecture, JTBD and risk reviews of the materially revised executable plan before dependent execution. Scoped contributions inside the assessed revision do not each trigger full replanning.
5. Records reassigned, dropped or superseded tasks with their reasons and explicit ownership handoffs, preserving history and evidence.

Close the outcome only when its confirmed acceptance evidence is satisfied. Stop unnecessary work. A tidy Project board, merged change or all tasks marked done does not replace the user's result. If blocked, finish useful independent work, record exact missing authority/capability/evidence and the smallest action that unlocks progress, then resume from fresh evidence without repeating completed effects.
