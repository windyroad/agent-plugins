---
status: draft
story-id: test-claims-against-the-tree-and-label-the-untested-ones
reported: 2026-07-26
decision-makers: [Tom Howard]
problems: [P434]
jtbd: [JTBD-002, JTBD-006]
rfcs: [RFC-057]
story-maps: [STORY-MAP-010]
estimated-effort: L
human-oversight: unconfirmed
---

# STORY-053: Test claims against the tree at capture and label the untested ones

**Status**: draft
**Reported**: 2026-07-26
**Problems**: P434
**JTBD**: JTBD-002 (secondary: JTBD-006)
**RFCs**: RFC-057
**Story Maps**: STORY-MAP-010
**Estimated effort**: L

## User value (required, INVEST Valuable)

In order to be able to trust a problem ticket as a statement of what is actually true, rather than
a transcript of what somebody asserted, as a developer who plans fixes from those tickets and has
no separate review step to catch a wrong premise, I want capture to test the claims that can be
tested against the tree, and to mark the ones it could not test as guesses instead of writing them
in the same voice as findings.

The cost of not doing this is already on the record. One inbound report asserted a component was
missing when it was in fact exported, and the resulting ticket was a phantom that no capture check
would have caught. Another stated a root-cause mechanism nobody had executed; it was replicated
across the ticket body and came close to steering a fix at a problem that did not exist. Both
surfaces already verify carefully — they check for duplicates, and they ask whether a parent ticket
should absorb the scope — but every check they run asks a question about the backlog, and none asks
whether the ticket is true. This story adds the missing question at the one moment it is cheap to
answer.

## Acceptance criteria (accepted-gate, INVEST Testable)

- [ ] Given a description asserting that a named file, package path or symbol is missing, absent,
  not exported or does not exist, where that thing IS present in the tree, the captured ticket body
  carries a line identifying the claim, what the tree actually shows, and the command whose output
  established it. Given the same description where the named thing genuinely is absent, no such line
  is emitted.
- [ ] The ticket is created in both cases. A falsified premise never suppresses the capture, because
  a wrong premise routinely wraps a real friction worth recording (P401 never-discard).
- [ ] Given a description asserting a root-cause mechanism with no cited evidence, the captured
  ticket records that claim under `## Hypotheses` in the incident surface's existing entry shape,
  carrying `Evidence: none — unexecuted` and a confidence marker, and `## Root Cause Analysis` does
  not contain the claim.
- [ ] Given a description containing no existence claims and no mechanism claims, the captured output
  is byte-identical to the pre-change behaviour. The common capture path pays no structural change.
- [ ] The pass exits without blocking on every input, including a description it cannot parse and a
  tree read that fails, so no capture can be halted by it (ADR-013 Rule 6 queue-and-continue).
- [ ] The same behaviour is reached through both capture surfaces — `/wr-itil:capture-problem` and
  the `/wr-itil:manage-problem` new-problem path — from a single implementation rather than two
  transcriptions. A test drives each surface and asserts the same emitted ticket shape.
- [ ] Whatever detection lands in committed shell is reachable from a shell whose `PATH` contains
  only the installed plugin's `bin/`, with no repo checkout present, proving the ADR-049 shim
  resolves for an adopter and not merely inside this monorepo.
- [ ] The pass completes within ADR-032's lightweight-capture flow budget on a description naming
  several tokens. Capture is an aside surface, and a check that blows the budget defeats the surface
  it protects.
- [ ] Every assertion above is exercised by bats driving the scripts and the skills against fixture
  trees, asserting on emitted lines and written ticket bodies. No test asserts on the prose content
  of a SKILL.md (ADR-052 / P081).

## Implementation notes

Scope, the two bricks, and what is deliberately excluded are in RFC-057. The decision itself is
ADR-100 — read it before implementing, because two of its three axes are open and they determine
what gets built.

**This story cannot be implemented until ADR-100 is ratified**, and that is not incidental
sequencing. Axis 1 decides what a falsified premise does to the capture: the criteria above are
written for capture-with-banner, and a ratification landing on halt-and-report-to-reporter would
rewrite the second criterion outright. Axis 2 decides how much of the pass is committed shell versus
a fresh-context subagent per ADR-032's fifth invocation pattern, which changes what the coverage
criteria can assert against. The architect leaned toward the subagent split on the strength of P463,
where a structurally similar fully-mechanical world-space check is running at a 76% false-positive
rate — worth reading before choosing, since it is the closest evidence available about how this kind
of check behaves in the field.

Brick 2 is a port, not an invention: the `Evidence:` and `Confidence:` entry shape already ships on
the incident surface under ADR-011, and reusing it verbatim is what keeps one evidence vocabulary
across incidents and problems. Resist inventing a lighter inline sentinel — ADR-100's Axis 3 records
why the alternatives lose.

The ratification of ADR-100 is the same event that moves this story to `accepted`, so it is not a
separate blocker to track.
</content>
