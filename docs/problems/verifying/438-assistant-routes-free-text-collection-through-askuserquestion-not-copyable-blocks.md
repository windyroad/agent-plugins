# Problem 438: Assistant routes free-text collection (URLs/tokens/IDs) through AskUserQuestion instead of per-item copyable blocks

**Status**: Verification Pending
**Reported**: 2026-07-06
**Priority**: 6 (Medium) — Impact: 2 × Likelihood: 3
**Origin**: inbound-reported (#324)
**Effort**: M. WSJF = (6 × 2.0) / 2 = 6.0.
**WSJF**: 6 — (6 × 2.0) / 2 (Known Error multiplier applied 2026-07-26; effort re-rated S → M — see the note below)
**JTBD**: JTBD-011 (secondary: JTBD-101)
**Persona**: developer

## Description

When the assistant needs to collect free-text items (URLs, tokens, IDs), it routes them through `AskUserQuestion`, whose "Other" field cannot capture pasted free-text cleanly. Witnessed on the P091 unresolvable-URL fallback: it took three user corrections before the assistant presented one copyable block per URL.

## Symptoms

- Free-text collection surfaced as AskUserQuestion options; the user cannot paste, leading to repeated corrections. The right shape is one copyable block per item.

## Impact Assessment

- **Who is affected**: the user, on any free-text collection task.
- **Frequency**: whenever free-text (not bounded options) is collected via AskUserQuestion.
- **Severity**: Medium — UX friction + repeated corrections; not incorrect action.

## Root Cause Analysis

### Root cause (confirmed 2026-07-26 by corpus read)

The suite's only per-turn behavioural injection about this tool is
`packages/itil/hooks/itil-assistant-output-gate.sh`. Its Rule 2 reads *"If the decision is
genuinely ambiguous (multiple-valid-paths, none clearly better per direction/policy), use the
AskUserQuestion tool"*, and Rule 4 collapses the whole block to *"obvious default => act;
genuine ambiguity => AskUserQuestion tool; NEVER prose-ask"*.

ADR-013 Rule 1, which that injection is carrying, actually reads: *"Every governance-skill
branch point with **two or more mutually exclusive options** MUST use `AskUserQuestion`."*

The precondition — two or more mutually exclusive options — is dropped in transmission, at the
one surface the agent reads on every turn. And ADR-013 never states the converse: what to do
when the input is unbounded. A corpus grep for any statement of that converse returns nothing.

So free-text collection has no rule routing it anywhere, and the agent generalises the
bounded-options tool to it. The defect is an infidelity in the shipped injection plus a genuine
gap in the decision it carries — not a one-off lapse in judgement, which is why in-conversation
correction has never made it stick.

### Effort re-rate, S → M (2026-07-26)

Re-rated at fix-proposal time. The original S assumed a single-file rule-text edit. The fix
carries a behavioural promptfoo eval (ADR-052 — a prose-surface behaviour cannot be asserted by
structural grep), a decisions-corpus amendment stating the converse, and a mechanism ADR that
must be ratified first. The WSJF score is unchanged at 6.0, but by a different derivation:
severity 6 now carries the Known Error multiplier 2.0 and is divided by M's divisor 2, where it
was `(6 × 1.0) / 1` before. The unchanged number is arithmetic coincidence, not a no-op edit.

### JTBD re-anchor (2026-07-26)

Re-anchored from the auto-capture default JTBD-001 (Enforce Governance Without Slowing Down) to
**JTBD-011** (Have a Correction to the Agent's Conduct Hold Everywhere), authored in the same
commit to ground this ticket, P445 and P423. JTBD-001's four desired outcomes are all
edit-review-shaped — none covers the shape in which the agent asks the developer for a value.
Persona `developer` was already correct and is unchanged.

Consequence worth naming so a later reader does not read it as a regression: JTBD-011 is born
`human-oversight: unconfirmed`, so `check-ticket-jtbd-ratification.sh` will route this ticket to
a user-answerable skip in autonomous loops until the job is ratified. That is the correct trade
— keeping the mis-anchor would have bought loop convenience with a false grounding — and one
confirm event at the next interactive drain clears it permanently.

### Investigation Tasks

- [x] Behavioural guidance: present each free-text item as its own copyable block; reserve
  AskUserQuestion for bounded, mutually-exclusive options. Confirmed as the right rule, and the
  gap it fills is located above.

## Workaround

Ask for free-text items as a plain numbered list with one copyable block per item, and reserve
`AskUserQuestion` for genuinely bounded choices. The user must re-apply this correction every
session — nothing carries it across a session boundary, which is the substance of the problem.

## Fix Strategy

Ship a portable, adopter-installed rule stating both halves of the contract: `AskUserQuestion`
is for a branch point with two or more mutually exclusive options, and unbounded input — a URL,
a token, an ID, a file path, anything the user has to type or paste — gets one copyable block
per item instead. Per **P423** the rule must be a shipped plugin surface, not project-local
maintainer memory, which conditions one agent in one repository and reaches no adopter.

Two questions are deliberately left open, because neither has a pinned direction and pinning one
here would be the build-on-then-rejected failure ADR-074 exists to prevent:

1. **Which surface carries the rule** — the existing per-prompt injection, a gate on the tool
   call itself, an after-the-fact scanner, instruction files only, or nothing mechanical.
2. **Which plugin ships it**, which decides who ever receives it under ADR-002's
   independently-installable packaging.

Both are queued for the maintainer and blocked from implementation on a ratified ADR per
ADR-073. Vehicle: **RFC-052**, carrying **STORY-049** on **STORY-MAP-007**. Nothing lands until
STORY-049 is ratified at its `accepted` gate (ADR-090 / ADR-096), which has no AFK path.

## Stories

| Story | Title | Status |
|-------|-------|--------|
| STORY-049 | Ask for a URL in a shape I can paste into | draft |

## Fix Released

Released in `@windyroad/itil@1.0.0` on 2026-08-13, via changeset `retire-afk-accept-carve-out.md`.

Awaiting user verification that the fix behaves as intended in the installed package.

## Dependencies

- **Composes with**: (distinct from the AskUserQuestion decision-surfacing tickets P340/P350/P302/P283 — this is text collection, not decision surfacing).
- **Same job as**: **P445** (the assistant offers off-ramps nobody asked for, hedges, and narrates its own conduct) and **P423** (behavioural corrections written to project-local memory reach no adopter). All three ground JTBD-011; P445 rides the same story map as a future second rib.

## Related

- Inbound issue #324.
- **RFC-052** (fix vehicle), **STORY-049** (the story), **STORY-MAP-007** (the map), **JTBD-011** (the grounding job) — all authored 2026-07-26 in the same commit as this transition.
- **P085** (closed) — the existing portable conduct rule this one sits beside, and whose shipped injection carries the transmission infidelity named in the root cause.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-052 | proposed | Ship a portable rule routing free-text collection to per-item copyable blocks |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
