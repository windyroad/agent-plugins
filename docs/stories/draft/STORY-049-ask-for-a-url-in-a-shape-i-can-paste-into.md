---
status: draft
story-id: ask-for-a-url-in-a-shape-i-can-paste-into
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P438]
jtbd: [JTBD-011, JTBD-101]
rfcs: [RFC-052]
story-maps: [STORY-MAP-007]
estimated-effort: M
human-oversight: unconfirmed
---

# STORY-049: Ask for a URL in a shape I can paste into

**Status**: draft
**Reported**: 2026-07-26
**Problems**: P438
**JTBD**: JTBD-011 (secondary: JTBD-101)
**RFCs**: RFC-052
**Story Maps**: STORY-MAP-007
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to paste a long URL without fighting a bounded-option picker — so that handing the
agent a link, a token or a path costs one gesture instead of three corrections — as a
developer, I want the assistant to present one copyable block per free-text item.

The title names the witnessed instance. The criteria below cover the whole unbounded-input
class: URL, token, ID, file path.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] In a project that has installed the plugin carrying the rule, and with no other
  `@windyroad/*` plugin installed, a fresh session in which the agent needs a URL, token, ID or
  file path from the user emits one copyable block per item and does not route the request
  through `AskUserQuestion`. The install-scope wording is deliberate — it must not presume a
  single plugin home, since which plugin ships the rule is an open decision.
- [ ] A genuinely bounded, mutually exclusive choice still arrives as an `AskUserQuestion` call,
  and `packages/retrospective/scripts/check-ask-hygiene.sh`'s lazy-ask metric does not move. The
  correction must not over-swing into prose questions.
- [ ] Coverage is a promptfoo behavioural eval per ADR-052, asserting both directions on a
  scenario that tempts the misuse — a prose-surface behaviour cannot be asserted by structural
  grep.
- [ ] The shipped rule text states both the precondition of ADR-013 (Structured user interaction
  for governance-skill decisions) Rule 1 — two or more mutually exclusive options — and its
  converse: unbounded input means one copyable block per item. The decisions corpus records that
  converse as ratified substance. Whether it lands as an in-place amendment to ADR-013 or as an
  `amends:` clause on the mechanism ADR is that ADR's call, not this story's.
- [ ] Whatever surface carries the rule stays inside its governing injection budget (ADR-038's
  ≤150-byte terse ceiling, ADR-045's bands), or that budget is amended explicitly rather than
  silently overrun.

## Driving problem trace (required — I7 invariant)

- **P438** — the assistant routes free-text collection through `AskUserQuestion`, whose "Other"
  field cannot cleanly take a pasted long value. Witnessed on the P091 unresolvable-URL
  fallback: three user corrections before the assistant presented one copyable block per URL.
  Root cause confirmed by corpus read — the shipped per-turn injection at
  `packages/itil/hooks/itil-assistant-output-gate.sh` carries ADR-013 Rule 1's *when* while
  dropping its precondition, and nothing anywhere states the converse. Arrived as inbound
  report #324.

## JTBD trace (accepted-gate — I8 invariant)

Serves **JTBD-011** (have a correction to the agent's conduct hold everywhere), against which
each criterion has a named outcome:

- Outcome 1 (an unbounded value arrives as one copyable block per item, not a bounded picker) →
  AC1.
- Outcome 2 (a genuinely bounded decision still arrives as a real single-gesture choice; no
  over-swing into prose) → AC2.
- Outcome 3 (a correction lands as a surface that ships, reaching a fresh session in any project
  that installs the carrying plugin) → AC1's install-scope clause.
- Outcome 4 (acknowledging a correction is not the fix; the next turn's default changes) → AC3.
  A passing eval is third-party evidence the default changed, not a promise that it will.
- Outcome 5 (no measurable additional per-turn overhead beyond what governance guidance already
  spends) → AC5.

**JTBD-101** (extend the suite) is the secondary anchor: the shipping half — packaging the rule
so an adopter's fresh session receives it — is plugin-developer work.

**JTBD-010's constraint is an input to the mechanism decision, not to this story**: governance
injection already trades per-session verbosity against a weekly quota the developer cannot see
ahead of time, so a mechanism adding a new standing per-prompt cost pays into that trade while
one riding an existing injection does not. Recorded in RFC-052 for the ADR to weigh.

## Implementation notes

**The criteria are mechanism-neutral on purpose.** Which surface carries the rule, and which
plugin ships it, are two open decisions queued for the maintainer and blocked on a ratified ADR
per ADR-073. Encoding either into an acceptance criterion would silently ratify it — the
build-on-then-rejected failure ADR-074 exists to prevent. RFC-052 records the candidate shapes,
the byte-budget arithmetic, the unrun `PreToolUse` probe that one candidate depends on, and the
behavioural fixtures the implementation will meet.

**This story cannot be implemented while `draft`** (ADR-096), and its `accepted` transition
carries the ADR-090 ratification that has no AFK path. RFC-052's `stories:` array stays empty
until then, because ADR-090 forbids an RFC referencing an unratified story. Ratify this story's
acceptance criteria together with JTBD-011's outcome list — the criteria encode those outcomes,
so confirming the job alone would leave the criteria unconfirmed while looking confirmed.

## Related

- RFC-052 (the fix vehicle), STORY-MAP-007 (the map, rib "Answerable prompts"), P438 (the
  driving problem), JTBD-011 (the grounding job), inbound #324.
- **P423** — the master class: a correction governing the plugins or their adopters must land as
  a shipped surface, never as project-local memory. This story's AC1 install-scope clause is
  that rule made testable.
- **P445** — the sibling instance riding the same map's future second rib.
