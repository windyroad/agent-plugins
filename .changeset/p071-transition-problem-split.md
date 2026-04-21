---
"@windyroad/itil": minor
---

P071 split slice 4: new `/wr-itil:transition-problem` skill (+ manage-problem forwarder)

`/wr-itil:manage-problem <NNN> known-error` / `<NNN> verifying` / `<NNN> close`
is deprecated; the transition-a-ticket user intent now has its own skill so
Claude Code `/` autocomplete surfaces it directly (JTBD-001 + JTBD-101).
This is phase 4 of the P071 phased-landing plan.

- `packages/itil/skills/transition-problem/SKILL.md` — NEW thin-router
  selection skill. Arguments: `<NNN>` (ticket ID) + `<status>` (one of
  `known-error`, `verifying`, `close`). Both are data parameters per the
  P071 split rule (ADR-010 amended); neither is a word-subcommand.
  Execution delegates to `/wr-itil:manage-problem <NNN> <status>` via the
  Skill tool — the authoritative Step 7 block (pre-flight checks + P057
  staging trap + P063 external-root-cause + P062 README refresh) stays
  on the host skill.
- `packages/itil/skills/transition-problem/test/transition-problem-contract.bats`
  — NEW 14 contract assertions (ADR-037 pattern; @problem P071 +
  @jtbd JTBD-001 + @jtbd JTBD-101 traceability).
- `packages/itil/skills/manage-problem/SKILL.md` — Step 1 parser updated
  to distinguish bare `<NNN>` (update flow, handled inline by Step 6)
  from `<NNN> <status>` (transition — delegated to the new skill). New
  "Forwarder for `<NNN> <status>` transitions" section added to the
  Deprecated-argument forwarders block, with the canonical deprecation
  notice (per ADR-010 amended template).
- `packages/itil/skills/manage-problem/test/manage-problem-transition-forwarder.bats`
  — NEW 5 contract assertions for the forwarder contract.

Deprecation window: until `@windyroad/itil`'s next major version per
ADR-010 amendment.

Remaining phased-landing slices tracked on P071: `list-incidents`,
`mitigate-incident`, `restore-incident`, `close-incident`,
`link-incident` (the `manage-incident` splits).

**Recovery note:** this slice shipped after the iter-5 AFK halt per P036.
The iteration subagent wrote the files correctly (19/19 bats green) but
returned prematurely without committing, triggering Step 6.75's
dirty-for-unknown-reason branch. Work verified sound post-hoc and
committed here as the halt recovery. A follow-up ticket captures the
iteration-worker-must-not-ScheduleWakeup contract gap (separate from
P077's delegation-mechanism fix).
