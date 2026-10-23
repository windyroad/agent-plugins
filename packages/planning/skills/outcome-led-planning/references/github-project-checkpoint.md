# Execute a selected-Project resume checkpoint

For a join/resume checkpoint with a selected GitHub Project and working `gh`,
planning and `contribute` MUST use the bundled
`scripts/github-project-checkpoint.mjs` operation. Do not manually publish a
Project synchronization-success claim on this route. The operation reads the
records/discussion, updates the two items, verifies their saved fields and only
then generates the task's synchronization result. It does not allocate owners,
approve a plan, acknowledge another person or complete the increment.

Resolve the script relative to this installed planning skill, including when
called from `contribute`. Use the existing authenticated `gh` account and saved
project configuration; no new grants, account changes or tokens are required by
the operation. Local and GitHub Issues-only tracking keep their existing paths.

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
