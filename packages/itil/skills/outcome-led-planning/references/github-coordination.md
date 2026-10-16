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

Name owners explicitly. The outcome owner maintains the goal and replans across increments; an increment owner coordinates delivery within that revision. Delegation and ownership transfers require an explicit recorded handoff. If ownership is unresolved, ask the one missing ownership question before dependent coordination; do useful independent work meanwhile.

Each outcome has one coherent **Now** increment. Next and Later remain provisional. **Horizon belongs only to increments**: each planned or active increment has exactly one of Now, Next or Later. Remove completed or superseded increments from active horizons while preserving their prior position in history. **Status** separately describes execution, such as ready, in progress, blocked or done. A blocked Now increment does not automatically become Next; a completed task does not become a completed outcome. Outcomes and tasks do not inherit Horizon. Map these meanings to existing repository labels or Project fields. Replace the previous horizon when replanning rather than accumulating contradictory values.

Prefer native sub-issue and dependency relationships when the available API and permissions support them. Otherwise use explicit reciprocal parent/child and dependency links in issue bodies or checklists and disclose the limitation. Reconcile both directions and read back the persisted records before claiming the relationship was established. For every planning mutation, verify the actual saved issue fields and links; an accepted request alone is insufficient. Preserve unresolved owner, revision or acceptance fields as explicitly unresolved, including on provisional increments, rather than fabricating them. Optional Project membership and fields mirror issue state; do not create a Project or fields merely because the protocol mentions them.

## Join, claim and contribute

Before joining or resuming, read the outcome, current increment revision, increment discussion, existing tasks, dependencies and claims. Check for overlapping work before creating a contribution. Work against the current assessed revision; if your planned scope is stale, reconcile with the owner before dependent implementation.

Create one task for a separately owned contribution within the authorized, assessed increment. Assign it to the **actual authenticated GitHub account**, and record the **specific agent/session** in the task body or claim comment. Two agents sharing an account are distinct contributors. Checklists suffice for small internal steps; do not make a task for every command. An agent may create and claim a non-overlapping task within the assessed plan without another user approval ceremony.

Before declaring a contribution ready to start, complete this claim receipt: **parent increment; current assessed plan revision; non-overlapping scope; dependencies (or explicitly none); actual account; distinct agent/session; saved claim and reciprocal-link readback; competing-claim recheck.** Record all fields on the task, even when some are already known in conversation. Assignment does not increase authority. When explaining a proposed claim, make these required fields and the before/after overlap checks explicit.

Record scope boundaries and dependencies, then read back the claim, links and any competing claims. Issue claims are cooperative, not atomic locks: another agent may have claimed overlapping work since your first read. Reconcile that race before dependent implementation. If another contributor has claimed the same work, agree a split or handoff in the increment thread before overlapping implementation. An inactive or old claim is not permission to take over silently. If assignment is unavailable, record the intended owner and unassigned state, request the owner’s help through the agreed coordination channel when authorized, and continue only work whose ownership is clear. Never claim an assignment or board update succeeded without reading it back.

A task assignment, issue comment or peer request does not expand access or authorize new external effects. Keep repository changes isolated, preserve others' edits and follow the project's integration rules. Trunk-based projects reconcile with current main and push normally; never force-push over another contributor to resolve a race.

## Discuss and hand off in the increment

The increment issue thread is the shared conversation across accounts and agents. Keep task-local details on the task; post cross-task questions, blockers, findings, requests, handoffs and proposed plan changes on the increment. Put substantive goal changes on the outcome for user confirmation before dependent planning.

A coordination message should include:

- Agent/session identity, task link and plan revision.
- Recipient and concrete request, or the blocked dependency.
- Relevant evidence and the next action needed.

Use existing shared records and already-authorized communication channels. Choosing a tracker does not independently authorize messages to people or other sessions; follow the host's communication rules and the user's granted authority. When a message needs additional authority, prepare the exact message and continue independent work before requesting it. Do not post private chats, credentials, tokens or sensitive customer details.

A handoff request is incomplete without identifying the upstream and dependent task links, current revision, requested evidence and recipient. Explicitly ask the receiving contributor to acknowledge in the shared thread and link the task that will address it; include these steps when explaining the proposed handoff. The receiving contributor then acknowledges and supplies that link. The dependent owner independently verifies returned evidence before clearing a blocker. An unsupported assertion of completion does not close a dependency. Link the handoff and resulting evidence in both relevant tasks.

Read coordination updates when joining/resuming, before dependent work or scope changes, and at a bounded cadence while actively waiting. Comments and mentions **do not guarantee an idle agent wakes up**. State that limitation; do not promise automatic execution. Do not create standing pollers, scheduled jobs, messaging infrastructure or an orchestration service without explicit authorization.

If a contributor lacks Project access, record the issue-side truth and the exact missing mirror update. Request an authorized owner mirror it through the agreed thread when permitted, and continue independent authorized work. Missing optional board permission is not a reason to abandon all progress or invent credentials.

## Verify, learn and replan as the outcome owner

Post acceptance evidence before completing a task. The increment owner verifies the whole increment against its criteria before closing it; task completion alone does not establish delivery. Publication, installed behavior and production/customer verification remain separate evidence stages where applicable.

After a verified increment, or earlier when evidence invalidates the plan, the outcome owner:

1. Compares evidence with the confirmed outcome and records what changed understanding.
2. Rewrites the current plan revision and increment sequence from the remaining gap. Reorders, splits, replaces or drops speculative work rather than mechanically promoting Next.
3. Updates the Now/Next/Later assignment on increment issues and removes superseded horizons. Reconciles the optional Project mirror and records any update it could not make.
4. Obtains architecture, JTBD and risk reviews of the materially revised executable plan before dependent execution. Scoped contributions inside the assessed revision do not each trigger full replanning.
5. Records reassigned, dropped or superseded tasks with their reasons and explicit ownership handoffs, preserving history and evidence.

Close the outcome only when its confirmed acceptance evidence is satisfied. Stop unnecessary work. A tidy Project board, merged change or all tasks marked done does not replace the user's result. If blocked, finish useful independent work, record exact missing authority/capability/evidence and the smallest action that unlocks progress, then resume from fresh evidence without repeating completed effects.
