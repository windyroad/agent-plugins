---
status: draft
story-id: have-my-reviewer-read-the-version-i-actually-have
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P439]
jtbd: [JTBD-011, JTBD-101]
rfcs: [RFC-053]
story-maps: [STORY-MAP-007]
estimated-effort: M
---

# STORY-050: Have my reviewer read the version I actually have

**Reported**: 2026-07-26
**Problems**: P439
**JTBD**: JTBD-011 (secondary: JTBD-101)
**RFCs**: RFC-053
**Story Maps**: STORY-MAP-007
**Estimated effort**: M

## User value (required, INVEST Valuable)

In order to get a review of the version I actually have — so that a round-trip is spent on
problems that are still real rather than on ones I fixed before I asked — as a developer, I want
the assistant to establish that an outside reviewer can reach the current content before it
relays anything to them.

The title names the witnessed instance, an external code review. The criteria below cover the
whole class: any relay of a repository artefact to a party outside the session, and both
staleness routes — commits that exist only locally, and a reader whose copy is older than the
working tree.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] In a project that has installed the plugin carrying the rule, and with no other
  `@windyroad/*` plugin installed, a fresh session in which the agent is asked to relay a
  repository artefact to a party outside the session first establishes that the recipient can
  reach the current content — by handing over the current committed content directly, or by
  naming what is unpushed and offering to push. The install-scope wording is deliberate: it must
  not presume a single plugin home, since which plugin ships the rule is an open decision.
- [ ] The rule fires on the relay moment, not on every turn. No new standing per-prompt injection
  and no per-turn `git log origin..HEAD` probe is introduced. Measured against the session's
  existing governance-injection cost, the per-turn overhead is unchanged on turns that relay
  nothing.
- [ ] A relay from a clean tree, with nothing unpushed and no reason to doubt the recipient's
  copy, completes without a freshness ceremony. The correction must not over-swing into
  narrating a check the user did not need.
- [ ] Coverage is a promptfoo behavioural eval per ADR-052 asserting both directions on a
  scenario that tempts the failure — a prose-surface behaviour cannot be asserted by structural
  grep, and a passing eval is third-party evidence the default changed rather than a promise
  that it will.
- [ ] Whatever surface carries the rule stays inside its governing injection budget (ADR-038's
  ≤150-byte terse ceiling, ADR-045's bands), or that budget is amended explicitly rather than
  silently overrun.

## Driving problem trace (required — I7 invariant)

- **P439** — the assistant relays a repository artefact to an external reviewer while assuming
  the copy the reviewer can see is the copy it just read. With commits unpushed or the
  reviewer's buffer stale, the reviewer re-flags already-fixed problems and the round-trip is
  wasted. Root cause confirmed by corpus read: no shipped surface anywhere in the suite states a
  handover-freshness rule, and the only unpushed-commit material in the corpus governs the
  pipeline's posture toward unpushed work (P116, ADR-018, ADR-020) rather than the agent's
  posture toward a third party reading it. Arrived as inbound report #326.

## JTBD trace (accepted-gate — I8 invariant)

Serves **JTBD-011** (have a correction to the agent's conduct hold everywhere), against which
each criterion has a named outcome:

- Outcome 6 (a repository artefact relayed outside the session is handed over verified-current,
  or what is unpushed is named with an offer to push) → AC1. This outcome is authored in the
  same commit as this story, and its ratification and this story's are the same drain event.
- Outcome 3 (a correction lands as a surface that ships, reaching a fresh session in any project
  that installs the carrying plugin) → AC1's install-scope clause.
- Outcome 2 (the correction does not over-swing) → AC3, read on this rule's axis: a clean-tree
  relay pays no ceremony.
- Outcome 4 (acknowledging a correction is not the fix; the next turn's default changes) → AC4.
- Outcome 5 (no measurable additional per-turn overhead beyond what governance guidance already
  spends) → AC2 and AC5.

**JTBD-101** (extend the suite) is the secondary anchor: the shipping half — packaging the rule
so an adopter's fresh session receives it — is plugin-developer work.

## Implementation notes

**The criteria are mechanism-neutral on purpose.** Which surface carries the rule, and which
plugin ships it, are two open decisions queued for the maintainer and blocked on a ratified ADR
per ADR-073. Encoding either into an acceptance criterion would silently ratify it — the
build-on-then-rejected failure ADR-074 exists to prevent. RFC-053 records the candidate shapes
and the constraints the mechanism ADR must weigh.

**AC2 is the criterion most likely to be lost.** The cheapest implementation of this rule is an
unconditional per-prompt line, and that is the one JTBD-010's constraint rules out: governance
injection already trades per-session verbosity against a weekly quota the developer cannot see
ahead of time, and this behaviour fires on a minority of turns. Conditioning on the relay moment
is a requirement, not a preference.

**This story cannot be implemented while `draft`** (ADR-096), and its `accepted` transition
carries the ADR-090 ratification that has no AFK path. RFC-053's `stories:` array stays empty
until then, because ADR-090 forbids an RFC referencing an unratified story. Ratify this story's
acceptance criteria together with JTBD-011's sixth outcome — the criteria encode that outcome,
so confirming the job alone would leave the criteria unconfirmed while looking confirmed.

## Related

- RFC-053 (the fix vehicle), STORY-MAP-007 (the map, rib "Current handovers"), P439 (the
  driving problem), JTBD-011 (the grounding job), inbound #326.
- **P423** — the master class: a correction governing the plugins or their adopters must land as
  a shipped surface, never as project-local memory. This story's AC1 install-scope clause is
  that rule made testable.
- **STORY-049** — the sibling story on the same map's first rib, blocked on the same mechanism
  ADR. If the two rules land on different carriers by default rather than by decision, the suite
  acquires two portable conduct-rule surfaces with no stated boundary between them.
- **P116** (closed) — the adjacent unpushed-commit surface. Its subject is which commit CI
  blames for a regression, not what a human reviewer can see.


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
