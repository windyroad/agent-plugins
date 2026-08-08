# Story-map ratification queue

Written 2026-08-09 overnight, for the morning ratification pass. Branch
`adr-103-map-is-the-approval-surface`, pushed, six commits ahead of main.

## Ready to ratify

Both render, both have every row carrying an identity or the pre-RFC history
marker, and nothing on either is untraced.

| Map | Title | Rows |
|---|---|---|
| **STORY-MAP-003** | Sustain my token quota across the week and across surfaces | shipped (pre-RFC) · RFC-046 |
| **STORY-MAP-004** | Close the loop with someone who reported a problem | shipped (pre-RFC) · RFC-028 · RFC-051 · RFC-061 |

Send either one and I will inline its stylesheet so it renders on a phone —
a map linked to a shared stylesheet is unstyled when it travels alone.

STORY-MAP-002 is already ratified and re-confirmed after the format change.

## Blocked, and why

Four maps refuse to render. Every one of them holds cards with no story
behind them, and a card without a story is refused rather than drawn.

| Map | Storyless cards | State |
|---|---|---|
| STORY-MAP-008 | 2 of 4 remaining | two backed overnight |
| STORY-MAP-011 | 2 | nothing proposes them |
| STORY-MAP-012 | 14 | nothing story-backed at all, including its shipped row |
| STORY-MAP-013 | 8 | same |

**The blocker is not effort, it is that no problem proposes the work.** A story
must trace a problem it solves, so a card describing something nobody has
asked for cannot become a story. For each remaining card the choice is to
write the problem it solves, or take the card off the map.

I searched the whole problem corpus for each of the six on maps 008 and 011.
Two had real problems and are now backed:

- **STORY-056** — clearing a block with a command the repository actually has.
  P435: the push gate tells an adopter to run a script that exists only here.
- **STORY-057** — getting a fix by upgrading rather than patching a cache.
  P369: a retired hook is still invoked by a stale binding, so the fix ships
  and the adopter still has to go into the plugin cache by hand.

Four have nothing proposing them, and I did not invent problems to justify
them:

- *"I install the one guardrail I want without dragging in the rest"* (008)
- *"Read a README that describes the version I just installed"* (008)
- *"The loop's choice of what to work next is legible to me afterwards"* (011)
- *"A ticket the loop writes reads as though a person wrote it"* (011)

Each reads like a real wish. None is recorded anywhere as a problem. That is
the decision waiting for you — four small ones, or one policy.

Maps 012 and 013 are a different question again: nothing on them is
story-backed, including their shipped rows, so they are 22 cards of intent
with no corpus behind them at all.

## Decisions queued for you

1. **The four unproposed cards above** — write the problems, or remove the cards.
2. **Maps 012 and 013** — 22 cards. Same question at ten times the size.
3. **STORY-056 and STORY-057 have no RFC.** Their cards sit in rows whose
   identity does not cover them: one row is scoped to making generated output
   portable and states it carries a single story, the other has no identity at
   all. Pointing a story at a release that does not name it is worse than
   leaving it empty, so the field is empty. Needs either a widened row or a
   new one.
4. **P485's shape** — whether the missing removal step is a per-change move, a
   cadenced pass over a package, or a gate that refuses a change which only
   adds. That ticket describes its own failure mode if it gets no self-firing
   trigger.

## What landed overnight

- **STORY-043 transitioned to done.** You said it was live; all four acceptance
  criteria were already ticked. Map 003's RFC-046 row still reads proposed,
  correctly — it also carries STORY-042, which is still in flight.
- **STORY-056 and STORY-057 captured** and linked onto map 008.
- **Two commits pushed** plus one for the stories. Branch is on origin.
- **The architect reviewer no longer requires amendment sections.** Before, asked
  about editing a ratified decision in place, it answered that this was
  "acceptable — and here it's required". It now refuses and names supersession.
  Both directions were run against the real agent, and the over-fire direction
  is guarded because its sibling verdict shipped without one and over-fired on
  an adopter.

## Not done, and why

- **No PR was opened.** CI runs only on main or on a PR, so nothing has
  validated this branch. I could not open one: the external-comms gate's
  marker would not match the body hash after several attempts, and forcing it
  was not worth the risk at that hour. Worth opening in the morning — the local
  suite cannot finish here, so CI is the only full-suite arbiter.
- **The near-miss worth knowing about**: my first attempt wrote the PR body with
  a heredoc in the same command as the `gh pr create` call. The gate blocked the
  whole command, so the file was never written — and `/tmp/pr-body.md` already
  held *another branch's* PR description from a different session. A diff caught
  it one command before publishing. Write outward-facing content in its own
  step, and to a session-scoped path.
