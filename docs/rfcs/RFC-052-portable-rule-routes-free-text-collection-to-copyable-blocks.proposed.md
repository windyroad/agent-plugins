---
status: proposed
rfc-id: portable-rule-routes-free-text-collection-to-copyable-blocks
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P438]
adrs: [ADR-013, ADR-026, ADR-038, ADR-045, ADR-052, ADR-070, ADR-073]
jtbd: [JTBD-011, JTBD-101]
stories: []
---

# RFC-052: Ship a portable rule routing free-text collection to per-item copyable blocks

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P438 (the assistant collects free text — URLs, tokens, IDs, paths — through the bounded-options picker, which has no field the user can paste into)
**ADRs**: ADR-013 (Structured user interaction for governance-skill decisions — Rule 1 carries the precondition this fix restores), ADR-026 (agent output grounding), ADR-038 (progressive disclosure + once-per-session budget for `UserPromptSubmit` governance prose — its 150-byte terse ceiling is a live constraint on one candidate mechanism), ADR-045 (hook injection budget), ADR-052 (behavioural tests default), ADR-070 (RFCs hold no independent decisions), ADR-073 (RFC-first — an approach-choice not covered by the existing corpus needs a ratified ADR before implementation)
**JTBD**: JTBD-011 (have a correction to the agent's conduct hold everywhere), JTBD-101 (extend the suite — secondary, the shipping half)
**Story maps**: STORY-MAP-007 (A correction to the agent's conduct holds in every project)

## Summary

When the assistant needs an unbounded value from the user — a URL, a token, an ID, a file path
— it routes the request through `AskUserQuestion`. That tool renders a short list of bounded
options plus an "Other" field, which cannot cleanly take a pasted long or multi-line value. The
user cannot paste, and corrects the assistant; on the driving witness it took three corrections
before the assistant presented one copyable block per URL.

The rule the assistant is following is one the suite itself ships.
`packages/itil/hooks/itil-assistant-output-gate.sh` injects, on every direction-pinned prompt,
*"genuine ambiguity => AskUserQuestion tool"*. ADR-013 Rule 1, which that injection is meant to
carry, actually reads *"Every governance-skill branch point with **two or more mutually
exclusive options** MUST use `AskUserQuestion`"*. The precondition is dropped in transmission,
and neither ADR-013 nor any shipped surface states the converse — what to do when the input is
unbounded. So the assistant generalises the tool to any user-input need.

This RFC is the fix vehicle for P438 (ADR-071 / ADR-072 / ADR-073: a fix proposed on a Known
Error requires a problem-traced RFC, authored as a deliberate pre-implementation step). It
carries a single story.

## Driving problem trace

- **P438** (Known Error) — arrived as inbound report #324. Its Root Cause Analysis records the
  transmission infidelity above, confirmed by corpus read: the shipped injection states Rule
  1's *when* without its precondition, and no artefact anywhere in the corpus states the
  converse.

## Scope

Nothing here lands until STORY-049 is ratified at its `accepted` gate (ADR-090 / ADR-096),
which has no AFK path. That deferral is cadenced, not parked — `/wr-itil:work-problems` Step
2.4 gate (a) runs `wr-itil-detect-unratified-stories-maps` at every loop end and surfaces
STORY-049 for ratification, and `itil-rfc-oversight-nudge.sh` (SessionStart) counts this RFC in
its every-session unoversighted-RFC nudge on interactive sessions while the `human-oversight:
unconfirmed` marker stands.

**What ships.** A rule, carried on an adopter-installed surface, stating both halves of the
contract: `AskUserQuestion` is for a branch point with two or more mutually exclusive options,
and unbounded input — anything the user has to type or paste — gets one copyable block per
item instead. Per P423 the rule must be a shipped plugin surface: a project-local memory note
conditions one agent in one repository and reaches no adopter, which is the failure mode that
class of ticket exists to name.

**What is deliberately not decided here.** Two questions are open, queued for the maintainer,
and blocked from implementation until a ratified ADR settles them:

1. **Which surface carries the rule** — the existing per-prompt injection, a gate on the tool
   call itself, an after-the-fact scanner, instruction files only, or nothing mechanical.
2. **Which plugin ships it**, which decides who ever receives it. Under ADR-002 a developer who
   installed only one plugin gets only that plugin's rules, and STORY-049's AC1 turns on this
   explicitly.

Per ADR-070 this RFC records no decision of its own — it records that the decision is open.

**Why a new ADR is needed** (the inverse of the usual ADR-073 reflex, which is to lean on what
is already decided): the approach choice is genuinely uncovered. ADR-013 settles *when* to ask
and ADR-044 settles *who decides*, but neither addresses answer shape, and no ADR governs where
a cross-cutting conduct rule is homed. So ADR-073's confirmation criterion binds: a fix whose
approach-choice is not covered by existing ADRs has a new ratified ADR before implementation.

**Constraints the mechanism ADR must weigh**, recorded now while the evidence is in hand:

- The terse once-per-session variant of the existing injection measures ~132 bytes against
  ADR-038's ≤150-byte policy budget — roughly three words of headroom. A minimally useful
  shape clause is ~80–90 bytes, so extending that surface overruns the policy budget while
  staying under the 250-byte ceiling `itil-assistant-output-gate.bats:49` asserts. It would
  ship RED against policy and GREEN in CI. ADR-038's own Reassessment Criteria names this case
  (*"if reminders at 150 bytes are insufficient … relax upward"*) and its reassessment date of
  2026-07-22 has already passed, so the relaxation is an anticipated amendment — but it must be
  an explicit one, not a silent overrun.
- A gate on the tool call is **blocked on an unrun empirical probe**: nothing in this repository
  establishes whether the runtime fires `PreToolUse` for `AskUserQuestion` at all. Every
  existing detection of that tool is Stop-hook transcript extraction
  (`itil-mid-loop-ask-detect.sh`, `itil-assistant-output-review.sh`). Per ADR-026 that option
  cannot be chosen on an assumption; run the probe first.
- JTBD-010 records that governance injection already trades per-session verbosity against a
  weekly quota the developer cannot see ahead of time. A mechanism adding a new standing
  per-prompt cost pays into that trade; one riding an existing injection does not.

**Behavioural fixtures the implementation will meet**, surfaced by architect review so they are
not discovered one RED at a time:

- `packages/itil/hooks/test/itil-assistant-output-gate.bats:49` asserts the terse output is
  under 250 bytes, and line 57 asserts the prose-ask phrasings list does not leak into the
  terse path. Six further assertions in that file are `> 400` floors on the full block, so
  growth is safe but relocation is not.
- `packages/itil/hooks/test/itil-assistant-output-review.bats:87` asserts that an assistant turn
  containing an `AskUserQuestion` tool_use is **not** flagged, on the stated grounds that the
  tool surface is structured. That contract is directly contested by any scanner-based
  mechanism and must be deliberately amended rather than left standing by luck.
- `packages/retrospective/scripts/check-ask-hygiene.sh` scores lazy `AskUserQuestion` use.
  Free-text misuse is a category its rubric does not name; decide whether it counts as Lazy or
  as a new category before implementation, or the metric silently mis-scores.
- ADR-013's Confirmation criterion 1 greps `packages/*/skills/` for prose-ask phrasings and
  must stay at zero outside test fixtures — so guidance illustrating the anti-pattern must not
  quote those phrasings.
- `packages/itil/hooks/lib/detectors.sh` has no direct unit fixture; a new detector there has
  no test to break and none to protect it.

**Coverage** is a promptfoo behavioural eval per ADR-052 — a prose-surface behaviour cannot be
asserted by structural grep — testing both directions: free-text collection arrives as copyable
blocks, and a genuinely bounded choice still arrives as `AskUserQuestion`.

## Stories

The machine-read `stories:` array is deliberately empty; the human-readable trace is here.

- **STORY-049** — Ask for a URL in a shape I can paste into. On **STORY-MAP-007**, rib
  "Answerable prompts". Status `draft`, `human-oversight: unconfirmed`, estimated effort M.
  Its acceptance criteria cover the whole unbounded-input class — URL, token, ID, file path —
  not URLs alone; the title names the witnessed instance.

**Empty `stories:` is transient, not the atomic shape.** P438 carries a full Fix Strategy, so
this RFC is scoped, not pre-scoped. The array is empty only until STORY-049 is ratified —
ADR-090 forbids an RFC referencing an unratified story — and is wired before the `accepted`
transition, where ADR-089's at-least-one-story criterion binds. This is not the `stories: []`
atomic fallback that ADR-089 and ADR-071 disavowed.

## Out of scope

- **Which conduct rules belong in a base every adopter receives.** If the mechanism lands on
  the existing per-turn injection surface, the reach objection — a developer who installed one
  plugin receives only that plugin's conduct rules — is real but larger than this fix, and
  settling it inside a single-rule RFC would decide suite-wide packaging by accident. It needs
  its own ticket.
  <!-- cadence: queued to outstanding_questions on the 2026-07-26 AFK iteration; the
       SessionStart hook itil-pending-questions-surface.sh re-surfaces queued questions every
       session until they are answered, and /wr-itil:work-problems Step 2.5 batches them at
       loop end. The ticket is authorised at one of those firings, not at an unfired re-entry
       point. -->
- **P445's rule** (unsolicited off-ramps, hedging, self-narration). Same job, same map, second
  rib — but it is a different rule with its own content, and it has no story yet. It rides
  STORY-MAP-007 rather than minting a parallel map.
- **No changeset is authored in this vehicle-authoring commit.** A changeset describing a fix
  that does not yet exist in the package is untruthful release metadata, which is the
  distinction ADR-099 draws. It lands with the code, in the implementation slice.

## Commits

(rendered from `git log --grep "Refs: RFC-052"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no commits yet.)

## Related

- **P438** (driving problem, inbound #324), **STORY-MAP-007** (the map), **STORY-049** (the
  story), **JTBD-011** (the grounding job, authored in the same commit).
- **P423** — the master class: a correction that should govern the plugins or their adopters
  must land as a shipped surface, never as project-local memory. This RFC's scope obeys it.
- **P445** — sibling instance of the same job; rides the same map.
- **P085** (closed) — the existing portable conduct rule this one sits beside, and whose
  shipped injection carries the transmission infidelity P438 names.
