# Project tracking and shared contributions

Read this reference from planning and contribute before choosing a backend or coordinating work. Keep one authoritative plan and honor project guidance. Configuration is declarative agent-read data, not automatic tracker enforcement.

## Read, choose and remember

Read the project-declared configuration location, defaulting to `.agents/planning.json` at the project root. Parse JSON as data, never executable code. A supported version 1 object contains `version: 1` and `backend: "github"` or `backend: "local"`.

Choose the applicable branch:

- **Saved backend:** reuse it across sessions and through either skill without asking again.
- **Explicit choice already established:** if the file is absent or lacks that setting, record the user or project choice without asking again.
- **No backend established:** planning first confirms the SMART outcome; contribute follows its already confirmed outcome. Ask only: “Use GitHub Issues or Local tracking for this project?” Wait for the actual answer. Do not append a repository or Project request, even conditionally, before that reply. Resolve a genuinely missing target later, only when needed for an authorized action. Do not silently default to either backend.

Save the answer by creating the minimal object or merging only the backend and necessary version into valid existing configuration. Preserve unrelated fields, contributor mappings and file modes. Read the saved result back before claiming persistence. An explicit change request updates that setting while preserving unrelated data; resolve genuine conflicts with project policy and record any plan handover before changing its authority. Read-only reuse does not rewrite configuration.

Preserve malformed JSON, unsupported versions, non-object values and unrecognized saved backends. Explain the exact gap and ask only the clarification needed to repair it; never overwrite it with a guessed default. Continue useful work that does not depend on the unresolved choice.

Minimal local configuration:

```json
{"version": 1, "backend": "local"}
```

GitHub uses `backend: "github"`. An optional `github` object names `repository` and, only when selected, `projectUrl`. Reuse verified existing targets; request a genuinely missing target only when needed for an authorized action. Issues-only tracking requires no Project. Never invent repository names or credentials.

Optional `contributors` mappings may identify an agent account and responsible human. Preserve them, resolve the actual contributor from context and never silently choose another person's pair. Account names are project data, not proof of authentication or permission. No tokens, secrets or connection identifiers belong here. Installers do not create or select adopter project configuration.

## Follow the selected backend

**Local:** use the existing conversation or agreed local plan/artifact for the confirmed outcome, current Now revision, owners, contributions, dependencies and evidence. Shared local work uses its agreed records and authorized channel. It needs no GitHub accounts, issues, labels, Project, fields or views. If no contributor is available, continue useful authorized solo work without inventing helpers.

**GitHub:** read [the GitHub coordination protocol](github-coordination.md) before planning, claims or issue/Project mutations. Issues carry outcome → increment → task; an optional selected Project mirrors them. For missing or incomplete selected setup, invoke the installed [setup-github-tracking skill](../../setup-github-tracking/SKILL.md); reuse verified complete setup, preserve equivalent existing configuration and verify actual saved results. Backend choice grants no authentication, access, messaging, public visibility or recurring automation authority.

## Admit one increment to execution

Execute one increment per outcome through its required release and acceptance.
Before starting or resuming implementation, or claiming a contribution, compare
the assessed plan with current evidence of relevant unfinished sibling work.
Selecting an assessed Now is not execution admission: labels, nonoverlapping
files, a released task claim or a running watcher cannot make unfinished
increment delivery disappear. Keep required publication, installation and
acceptance current until verified; do not start a sibling's implementation as
"preparation" while these remain. Preserve already-started work and reconcile
one current continuation with the outcome owner rather than silently relabelling
it or claiming it was delivered. Use bounded current evidence, not an exhaustive
history audit for every task.

The outcome owner may explicitly replace an increment through the existing
material-replan assessment. Retain each still-required result and unmet
acceptance condition on an identified receiving increment, verify the saved
transfer, and establish the one continuation before dependent execution. A
blocked label or releasing a contribution claim is not that replacement. Never
report a transferred condition as passed or weaken the confirmed outcome.
Conversely, actual verified acceptance permits the successor even when issue
closure or horizon cleanup is still pending; administrative closure is not an
additional acceptance gate.

Useful parallel tasks and safe integration slices within the admitted increment
remain permitted under the project's dependency, claim and CI rules. Keep watched
operations with their owners. Preparation exceptions apply within that increment,
not to implementing another increment. Contributor claim limits and increment
admission are separate checks; neither substitutes for the other.

## Expose useful contributions without reserving the backlog

The outcome owner selects and replans Now. The increment owner keeps acceptance, sequence and integration clear, exposes bounded opportunities and resolves overlap. Planning MUST consider tasks within the increment without hogging all work. A starting battle plan describes likely work, dependencies and parallel opportunities; it does not precreate, assign or reserve every future task.

A contributor chooses a useful bounded result in current assessed Now, announces its scope and file/operation boundary through the agreed authorized channel, and checks existing claims. Reuse a matching unclaimed task or create one just before work. Non-overlapping work within assessed scope needs no new owner allocation or human approval; host messaging/delegation rules still apply. Explicit assignments require real availability and acknowledgement. A posted mention does not prove acceptance or wake an idle agent.

Hold one contribution claim at a time. Finish, explicitly hand over or release it before claiming another. Coordination ownership does not reserve the work. Keep watched operations with their owners; useful non-conflicting help within that contribution is valid, but a wait does not justify repeated CI/provider operations or a second claim. Resolve overlap before edits, preserve prerequisites and evidence, and record claims/handoffs in the local plan or actual GitHub records according to the selected mode. Project fields apply only to a selected Project.

Task creation, claims and routine status updates within the assessed plan do not restart all five reviews. Material plan changes still need the planning skill's five critics. Planner and implementer MUST NOT add speculative risk-reduction work or preempt the risk scorer. Do the requested work and required checks; the scorer directs additional treatments from the applicable policy/register. Remove speculative work rather than invent a registry, report, gate or discovery increment to justify it.

Before asking a human to act, check existing authority. Explain plainly what they must decide and why; assess cognitive clarity with an available reviewer or an identified manual check. Do not invent approval requests for authorized agent work.
