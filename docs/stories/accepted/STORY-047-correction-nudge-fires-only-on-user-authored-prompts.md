---
status: accepted
story-id: correction-nudge-fires-only-on-user-authored-prompts
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P430]
jtbd: [JTBD-006]
rfcs: [RFC-050]
story-maps: [STORY-MAP-005]
estimated-effort: S
---

# STORY-047: Gate the correction nudge on prompt authorship

**Reported**: 2026-07-26
**Problems**: P430
**JTBD**: JTBD-006
**RFCs**: RFC-050
**Story Maps**: STORY-MAP-005
**Estimated effort**: S

## User value (required, INVEST Valuable)

In order to keep the capture-on-correction nudge meaningful — so that seeing it means a real
correction happened, rather than the framework's own iteration prompt containing the words
"do not" — as a developer running autonomous backlog loops, I want the detector to know who
authored the prompt, so an absent user is never nudged to capture a correction they did not
make, and a real correction still lands as a durable problem record.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [x] `packages/itil/hooks/itil-correction-detect.sh` exits silently when
  `WR_SUPPRESS_CORRECTION_DETECT=1`, with the guard placed ahead of the `jq` parses so the
  suppressed path costs one string comparison.
- [x] Only the literal value `1` suppresses; `0`, `true`, empty, and unset all leave the
  detector firing normally.
- [x] No announce marker is written on the suppressed path, so the once-per-session
  progressive-disclosure budget is not burned by a prompt that produced no output.
- [x] `packages/itil/skills/work-problems/SKILL.md` Step 5 exports
  `WR_SUPPRESS_CORRECTION_DETECT=1` before each `claude -p` iter spawn, alongside the two
  guards already exported there, with a comment citing P430 and JTBD-006 in the prose shape
  the neighbouring guard blocks use.
- [x] The hook header comment records why this is a distinct guard class rather than a split
  of `WR_SUPPRESS_OVERSIGHT_NUDGE` (the ADR-068 / ADR-047 constraint), so the next reader
  does not mistake it for a violation.
- [x] Behavioural bats in `packages/itil/hooks/test/itil-correction-detect.bats`: a
  user-authored correction still emits the MANDATORY block with the guard unset; the same
  prompt under `WR_SUPPRESS_CORRECTION_DETECT=1` emits nothing and writes no marker; a
  non-`1` value does not suppress.
- [x] `setup()` and `teardown()` in that suite `unset WR_SUPPRESS_CORRECTION_DETECT`, so the
  existing positive-detection cases do not false-RED when the suite runs inside an AFK iter
  that exports the guard (the P391 hermeticity class).
- [x] `docs/briefing/afk-subprocess.md` lists three exported iter guards, not two.
- [x] A `.changeset/*.md` bumps `@windyroad/itil` minor — the change introduces a new public
  env-var contract that adopter orchestrators can set.

## Driving problem trace (required — I7 invariant)

- **P430** — the detector is content-only, with no signal for prompt authorship, so
  framework-authored iteration prompts carrying ordinary imperatives trip it. Confirmed in
  situ: the iter that worked this ticket received the full block on `\bDO NOT\b`.

## JTBD trace (accepted-gate — I8 invariant)

Serves JTBD-006 (progress the backlog while I'm away): a nudge that fires on nearly every
iteration with nothing behind it is noise in the one channel that is supposed to mean
something, and it costs context budget in every iter that pays for it. Secondary JTBD-001 —
governance that fires when it should not is the "manually police AI output" friction the
`developer` persona is documented as intolerant of.

## Implementation notes

Dispatcher-side provenance, not content sniffing: provenance is a property of the process
that spawned the prompt, and only that process can assert it. This follows four existing
precedents — `WR_SUPPRESS_PENDING_QUESTIONS`, `WR_SUPPRESS_OVERSIGHT_NUDGE`,
`WR_SUPPRESS_DEFERRAL_CENSUS`, `WR_SUPPRESS_DEFERRAL_CADENCE_GATE` — each of which chose an
env-var self-suppress over a heuristic. P078 is preserved because a real correction is typed
into the **orchestrator** session, where the guard is not set.

## Related

- RFC-050 (the fix vehicle), STORY-MAP-005 (the map), P430 (the driving problem), inbound #257.


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
