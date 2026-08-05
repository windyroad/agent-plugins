---
status: proposed
job-id: corrected-conduct-holds-everywhere
persona: developer
secondary-persona: plugin-developer
date-created: 2026-07-26
human-oversight: unconfirmed
---

# JTBD-011: Have a Correction to the Agent's Conduct Hold Everywhere

> Authored 2026-07-26 to ground P438, P445 and P423 — three separately captured instances of
> the same job that had no home in the corpus and were each defaulting onto JTBD-001 (Enforce
> Governance Without Slowing Down), whose outcomes are all edit-review-shaped. Born
> `human-oversight: unconfirmed`; ratify via `/wr-jtbd:confirm-jobs-and-personas`, which the
> per-session unoversighted-job nudge surfaces until it is confirmed.

## Job Statement

When I correct how the agent conducts a turn — how it asks me for something, whether it hands
me off-ramps I never asked for, whether it narrates its own conduct instead of doing the work,
whether it hands my work to someone else without checking they can see the version I actually
have — I want the corrected behaviour to hold in my next session and in every other project I
work in, so that I never have to deliver the same correction twice.

## Desired Outcomes

- When the agent needs an unbounded value from me — a URL, a token, an ID, a file path — it
  presents the request in a shape I can act on directly: one copyable block per item, not a
  bounded picker I cannot paste into.
- A genuinely bounded, mutually exclusive decision still arrives as a real single-gesture
  choice. The correction does not over-swing into prose questions I have to answer by hand.
- A correction I deliver once lands as a surface that ships. It reaches a fresh session in any
  project that installs the carrying plugin, not only the repository where I made the
  correction.
- Acknowledging a correction is not the fix. The next turn's default changes, whether or not
  the agent says anything about it.
- The rule costs me no measurable additional per-turn overhead beyond what governance guidance
  already spends.
- When I relay a repository artefact to someone outside my session — an external reviewer, a
  colleague, a second agent — the agent hands over content it has verified is current, or names
  what is unpushed and offers to push, rather than assuming the copy the recipient can see is
  the copy it just read.

## Persona Constraints

- Wants speed without sacrificing quality: every extra round-trip spent answering a badly
  shaped question is time the agent was supposed to save.
- May install only two or three plugins relevant to the project (JTBD-003), so a rule that
  ships in a plugin the project did not install does not reach this job at all.
- Governance injection already drives per-session verbosity for quality (JTBD-010); that trade
  is correct per-session but accumulates against a weekly quota the developer cannot see ahead
  of time, so a new standing per-prompt cost is not free.
- Works across several repositories from one account, and the agent's defaults reset each
  session — so nothing held only in conversation, or only in one repository's private notes,
  survives.

## Current Solutions

- Correcting the agent in conversation, and re-correcting it the next time the behaviour
  recurs.
- Writing the correction to project-local agent memory, which conditions this agent in this
  project and reaches no adopter at all.
- Living with it: pasting a long URL into a bounded picker's free-text field, or answering in
  prose that the agent then has to re-read.

## Related

- **P438** (the assistant collects free text — URLs, tokens, IDs — through the bounded-options
  picker instead of one copyable block per item; arrived as inbound report #324), **P445** (the
  assistant offers off-ramps nobody asked for, hedges, and narrates its own conduct), **P423**
  (the assistant "fixes" recurring behavioural corrections by writing to project-local memory,
  which reaches no adopter), and **P439** (the assistant relays a repository artefact to an
  outside reviewer while assuming the copy that reviewer can reach is current; arrived as
  inbound report #326). Four independent captures, by four different routes, of one job — which
  is what makes this a job rather than an outcome bolted onto an existing one.

  The four are not identical in shape, and the coherence claim is the weaker, honest one rather
  than the tidy one. P438, P445 and P423 are corrections the *user* delivered that failed to
  persist. P439 is different: it is a first-capture inbound report of a rule never stated
  anywhere, and its repetition is the *reviewer* re-flagging, not the user re-correcting. What
  unites all four is not that each was delivered twice — it is that each needs the same thing to
  be fixed at all: a conduct rule that ships as a portable surface and changes the next turn's
  default. That is this job's third desired outcome, and it is the axis the four share.
- **JTBD-003** (Compose Only the Guardrails I Need) is about *which* guardrails you get.
  **JTBD-007** (Keep Plugins Current Across Projects) is about *whether they are current*. This
  job is about whether a correction *persists at all* — a distinct axis from both.
- **JTBD-101** (Extend the Suite with New Plugins) is the secondary anchor: the shipping half
  of this job — a correction reaching an adopter's fresh session — is packaging work that the
  plugin-developer persona owns.

## RFCs

| ID | Title | Status |
|----|-------|--------|
| RFC-052 | RFC-052: Ship a portable rule routing free-text collection to per-item copyable blocks | proposed |
| RFC-053 | RFC-053: Ship a portable rule requiring a verified-current handover before an external-review round-trip | proposed |
## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-049 | STORY-049: Ask for a URL in a shape I can paste into | draft |
| STORY-050 | STORY-050: Have my reviewer read the version I actually have | draft |


## Story Maps

| ID | Title | Status |
|----|-------|--------|
| STORY-MAP-007 | STORY-MAP-007: A correction to the agent's conduct holds in every project | archived |
| STORY-MAP-011 | STORY-MAP-011: Trust the AFK loop's autonomous conduct | draft |
