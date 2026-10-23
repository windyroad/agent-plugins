# Inspect and reconcile GitHub records

Resolve `scripts/github-project-checkpoint.mjs` relative to this installed
planning skill, including when called from `contribute`. Use the existing
authenticated `gh` account and saved project configuration. The default is
`.agents/planning.json`; an existing project-declared configuration path may be
supplied last. These operations require no new grants, account changes or tokens.
Local tracking keeps its existing path.

## Inspect the hierarchy

When reconciling an outcome, current Now, an affected provisional Next and a
task together with working `gh`, planning and `contribute` MUST first use the
read-only hierarchy inspector. Supply those actual distinct issue numbers;
do not invent a Next issue to satisfy the command. Other record sets retain
their existing coordination path.

```json
{
  "outcome": 1,
  "increment": {"issue": 2},
  "next": {"issue": 3},
  "task": {"issue": 4}
}
```

Run `node <installed-planning-skill>/scripts/github-project-checkpoint.mjs inspect-hierarchy request.json`.
This reads the four actual issues and their returned comments. It writes
nothing and makes no Project or native-link request. Read the raw records and
consume `findings` before claiming that the records are correct:

- `projectSelection` reports configuration facts. `not-recorded` means selection
  is unresolved from that configuration, not an explicit choice to use no
  Project. `recorded` does not prove capability; consider actual project
  requirements and explicit direction too. Preserve invalid configuration.
- Each record's `inspection` reports literal owner, revision, acceptance and
  Parent candidates with raw line evidence. `candidate` is text, not verified
  ownership or passed acceptance. `explicitly-unresolved` preserves a recorded
  unknown. Empty/missing literals, unsupported syntax and multiple candidates
  remain unestablished by this inspector; they do not prove semantic information
  is absent or that the issue is invalid. Inspect the actual prose/history
  rather than forcing a new format or choosing a historical value.
- `textLinks` compares the three requested textual relationships. A mention is
  observed text, not proof of a current native relationship. Inspect both sides
  and repair known reciprocal gaps under the existing coordination rules.
- `capabilities` are `not-probed`; do not turn that into an outage or native-link
  absence. `inspection-unavailable` means the read/report operation failed,
  not that a Project mirror is pending.

A successful command produces a diagnostic report, never a correctness or
synchronization verdict. Identical drafts and saved bodies do not establish
completeness. Before claiming completeness, account for every finding through
actual semantic review, authorized repair with saved readback where needed, or
honest unresolved recording in the existing plan or record. Follow the selection
finding's conditional next action, which targets the existing outcome issue
for saving and reading back a still-unresolved gap. Reuse an already saved gap
without an unchanged write. Configuration alone may leave the choice unresolved
while requirements or explicit direction establish it. Unsupported
syntax does not force normalization or another artifact.
Apply the existing per-record rules to known gaps, marking missing
required information unresolved rather than inventing it; preserve completed
acceptance and attribution. Read back authorized changes and compare reciprocal
links before reporting reconciliation. Unsupported syntax needs actual review,
not automatic normalization. Semantic acceptance remains with the caller and
required independent review.

## Synchronize selected Project fields

For a join/resume checkpoint on an active open task with a selected GitHub Project and working `gh`,
planning and `contribute` MUST use the bundled
`scripts/github-project-checkpoint.mjs` operation. Do not manually publish a
Project synchronization-success claim on this route. The operation reads the
records/discussion, updates the two items, verifies their saved fields and only
then generates the task's synchronization result. It does not allocate owners,
approve a plan, acknowledge another person or complete the increment.

This mutation route applies to its open outcome, increment and active task.
GitHub Issues-only tracking uses no Project field mutations.

## Inspect, decide, apply

Create a request from the actual records and Project fields. IDs below are
placeholders. Preserve each record's own verified agent/session; do not copy the
task contributor onto the increment. The status option must be the existing
In progress equivalent, never Done.

```json
{
  "outcome": 1,
  "increment": {"issue": 2, "itemId": "INCREMENT_ITEM_ID", "agent": "verified increment owner/session"},
  "task": {"issue": 4, "itemId": "TASK_ITEM_ID", "agent": "verified task owner/session"},
  "statusFieldId": "STATUS_FIELD_ID",
  "agentFieldId": "AGENT_FIELD_ID",
  "statusOptionId": "IN_PROGRESS_OPTION_ID",
  "nextAction": "the actual next step in this task"
}
```

1. Run `node <installed-planning-skill>/scripts/github-project-checkpoint.mjs inspect request.json`.
   The default configuration is `.agents/planning.json` in the project. An
   existing project-declared configuration path may be supplied as the final
   argument. Save the returned JSON in a permitted working location.
2. Read that inspection, including the increment discussion, current revision,
   dependencies and claims. Acknowledge relevant handoffs through the authorized
   channel and resolve overlap or material changes under the existing rules.
   The operation reading a comment does not mean its recipient acknowledged it.
   If that work changes these records, inspect again before applying.
3. Run `node <installed-planning-skill>/scripts/github-project-checkpoint.mjs apply request.json inspection.json`.
   Supply the same explicit configuration path last when one was used above.
   The operation rechecks inspected context, updates only task/increment
   Status/Agent, reads back the actual fields, then publishes generated task
   progress and reads it back. It preserves Horizon and the rest of the brief.
   The current brief needs a literal `Next action:` line; if absent, maintain
   that field truthfully before inspecting again. Do not erase existing content.

Use direct commands with literal paths supported by the runtime permissions.
Do not infer unavailable authority from one rejected compound command when an
already-authorized direct invocation remains available.

## Read the result

- `synchronized`: the requested fields and generated task update were read back.
  This establishes this checkpoint only, not task or increment completion.
- `changed-context`: inspect the returned facts and resolve the change. A body
  changed before publication stays untouched, even if fields already changed.
- `pending`: keep the precise affected operation and next action visible. A
  partial or ambiguous field result cannot generate synchronization success.
  The operation reads saved state before resolving uncertain writes and never
  automatically repeats a mutation. If the pending note itself could not be
  saved, its output does not prove the issue was updated.

Do not treat an exit code, assignment or local note as a saved-field result.
Keep useful authorized issue work moving while Project work is pending. If
`gh` or this operation is unavailable, use other already-authorized capabilities
under the coordination protocol, preserving the same truthful claim dependency.
Do not request broader access while an existing authorized route works, or
claim the executable operation enforced an untested browser/manual path.
