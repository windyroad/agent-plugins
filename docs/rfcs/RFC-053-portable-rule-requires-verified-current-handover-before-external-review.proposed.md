---
status: proposed
rfc-id: portable-rule-requires-verified-current-handover-before-external-review
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P439]
adrs: [ADR-002, ADR-026, ADR-038, ADR-045, ADR-052, ADR-060, ADR-070, ADR-071, ADR-073, ADR-089, ADR-090, ADR-095]
jtbd: [JTBD-011, JTBD-101]
stories: []
---

# RFC-053: Ship a portable rule requiring a verified-current handover before an external-review round-trip

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P439 (the assistant relays a repo artefact to an outside reviewer while assuming the copy that reviewer can see is the copy it just read)
**ADRs**: ADR-002 (one plugin per governance concern — under it, which plugin ships a rule decides who ever receives it), ADR-026 (agent output grounding — this rule's whole content is "establish the fact instead of assuming it"), ADR-038 (progressive disclosure + the ≤150-byte terse governance-injection budget, a live constraint on one candidate mechanism), ADR-045 (hook injection budget), ADR-052 (behavioural tests default), ADR-060 (Problem-RFC-Story framework — I1 problem trace, and the scope-boundary rationale that rules out an umbrella RFC), ADR-070 (RFCs hold no independent decisions), ADR-071 (every fix goes through an RFC), ADR-073 (RFC-first — an approach-choice not covered by the existing corpus needs a ratified ADR before implementation), ADR-089 (every RFC has at least one story), ADR-090 (an RFC may not reference an unratified story), ADR-095 (story-map membership and story-content completeness enforced at capture)
**JTBD**: JTBD-011 (have a correction to the agent's conduct hold everywhere), JTBD-101 (extend the suite — secondary, the shipping half)
**Story maps**: STORY-MAP-011 (Trust the AFK loop's autonomous conduct), rib "Current handovers"

## Summary

When the user relays a repository artefact to an external reviewer, the assistant assumes the
copy the reviewer can reach — a git remote, a shared IDE buffer — is the copy the assistant just
read. With commits still unpushed or the reviewer's buffer stale, the reviewer re-flags problems
that are already fixed. The round-trip is spent re-litigating work that is done, and the user
pays for the review twice.

The correct conduct is to establish the fact rather than assume it: hand over the current
committed content, or name what is unpushed and offer to push, before spending the round-trip.

## Driving problem trace

- **P439** (Known Error) — arrived as inbound report #326. Its Root Cause Analysis records the
  finding, confirmed by corpus read rather than inferred: a grep of `packages/*/hooks`,
  `packages/*/skills`, `packages/*/agents`, `packages/*/lib` and `docs/decisions/` for any
  statement of a handover-freshness rule returns nothing. The only unpushed-commit material in
  the corpus is risk-scoring and CI-blame — P116, ADR-018, ADR-020, the risk-scorer agents —
  which governs *the pipeline's* posture toward unpushed work, not *the agent's* posture toward
  a third party reading it. With no rule contradicting it, the assume-freshness default stands,
  which is why correcting it in conversation has never made it hold.

This RFC is the fix vehicle for P439 (ADR-071 / ADR-072 / ADR-073: a fix proposed on a Known
Error requires a problem-traced RFC, authored as a deliberate pre-implementation step). It
carries a single story.

## Scope

Nothing here lands until STORY-050 is ratified at its `accepted` gate (ADR-090 / ADR-096), which
has no AFK path. That deferral is cadenced, not parked — `/wr-itil:work-problems` Step 2.4 gate
(a) runs `wr-itil-detect-unratified-stories-maps` at every loop end and surfaces STORY-050 for
ratification, and `itil-rfc-oversight-nudge.sh` (SessionStart) counts this RFC in its
every-session unoversighted-RFC nudge on interactive sessions while the `human-oversight:
unconfirmed` marker stands.

**What ships.** A rule, carried on an adopter-installed surface, stating that before the
assistant relays a repository artefact to a party outside the session, it establishes that the
recipient can reach the content the assistant is describing — by handing over the current
committed content directly, or by naming what is unpushed and offering to push — rather than
assuming the recipient's copy is current. Per P423 the rule must be a shipped plugin surface: a
project-local memory note conditions one agent in one repository and reaches no adopter, which
is the failure mode that class of ticket exists to name.

**What is deliberately not decided here.** The same two questions RFC-052 leaves open govern
this rule too, and they are queued for the maintainer and blocked from implementation until a
ratified ADR settles them:

1. **Which surface carries the rule** — an existing per-prompt injection, a gate on the relaying
   tool call, an after-the-fact scanner, instruction files only, or nothing mechanical.
2. **Which plugin ships it**, which decides who ever receives it. Under ADR-002 a developer who
   installed only one plugin gets only that plugin's rules, and STORY-050's AC1 turns on this
   explicitly.

Per ADR-070 this RFC records no decision of its own — it records that the decision is open, and
carries no rejected-alternatives block.

**Why this is a second RFC rather than an extension of RFC-052.** Architect review 2026-07-26
ruled the grain, and the ruling is recorded here rather than left implicit. P371's
anti-fragmentation test is whether *this ticket's fix IS an existing RFC's already-scoped work*;
shipping RFC-052's rule — free-text collection routes to copyable blocks — does not fix P439.
Every multi-problem RFC precedent in this repo is one scope with many problems, never many
scopes in one RFC. RFC-052's own Out-of-scope section excludes P445's rule on grounds that apply
identically here ("a different rule with its own content"), and warns that settling packaging
inside a single-rule RFC would decide it by accident; ADR-060 rejected its Option E for exactly
the lost scope-boundary. So P439 is the I13 gate's branch (b), no-vehicle. What the two RFCs
*do* share is the map (STORY-MAP-011), the grounding job (JTBD-011), and the mechanism ADR both
are blocked on. Widening RFC-052 into a "portable agent-conduct rules" umbrella was considered
and rejected on those grounds; so was minting an RFC for the shared mechanism blocker, which is
structurally illegal — ADR-060's I1 requires every RFC to trace a problem and no packaging
problem ticket exists, and ADR-070 puts a choice among viable options in an ADR rather than an
RFC.

**Constraints the mechanism ADR must weigh**, recorded now while the evidence is in hand:

- **The trigger must be conditional, not standing.** JTBD-011's sixth desired outcome and
  JTBD-010's constraint both bind: governance injection already trades per-session verbosity
  against a weekly quota the developer cannot see ahead of time. A rule implemented as an
  unconditional per-prompt injection — or worse, a `git log origin..HEAD` probe on every turn —
  pays into that trade on every turn to serve a behaviour that fires on a minority of them.
  Conditioning activation on the relay/handover moment is a requirement, not a preference.
- **Reach must be argued, not assumed.** JTBD-003 records that a developer may install only two
  or three plugins. RFC-052's sibling rule has a natural carrier in
  `packages/itil/hooks/itil-assistant-output-gate.sh`; this rule's trigger is not ITIL-shaped,
  so if it lands on a narrower surface the reach argument has to be made explicitly.
- **The two rules should not each mint their own mechanism.** If RFC-052's rule and this one
  land on different surfaces by default rather than by decision, the suite acquires two portable
  conduct-rule carriers with no stated boundary between them. The mechanism ADR settles both, or
  states why they differ.

**Coverage** is a promptfoo behavioural eval per ADR-052 — a prose-surface behaviour cannot be
asserted by structural grep — testing both directions: a relay with unpushed commits surfaces
what is unpushed and offers to push, and a relay from a clean tree does not pay a spurious
freshness ceremony.

## Stories

The machine-read `stories:` array is deliberately empty; the human-readable trace is here.

- **STORY-050** — Have my reviewer read the version I actually have. On **STORY-MAP-011**, rib
  "Current handovers". Status `draft`, `human-oversight: unconfirmed`, estimated effort M.

**Empty `stories:` is transient, not the atomic shape.** P439 carries a full Fix Strategy, so
this RFC is scoped, not pre-scoped. The array is empty only until STORY-050 is ratified —
ADR-090 forbids an RFC referencing an unratified story, and `wr-itil-check-rfc-stories-ratified`
enforces it — and is wired before the `accepted` transition, where ADR-089's at-least-one-story
criterion binds. This is not the `stories: []` atomic fallback that ADR-089 and ADR-071
disavowed.

<!-- cadence: the empty array is drained at STORY-050's accepted gate, which
     /wr-itil:work-problems Step 2.4 gate (a) surfaces via
     wr-itil-detect-unratified-stories-maps at every loop end, and which
     itil-rfc-oversight-nudge.sh re-surfaces at every interactive SessionStart while
     human-oversight stays unconfirmed. Both are self-firing; neither waits on someone
     remembering to run a command. -->

## Out of scope

- **Which conduct rules belong in a base every adopter receives.** RFC-052 already names this as
  needing its own ticket. This RFC inherits the same boundary and does not settle it. The
  compliant path is a problem ticket for the packaging gap plus an ADR for the mechanism choice
  — not a third RFC.
  <!-- cadence: queued to outstanding_questions on the 2026-07-26 AFK iteration; the
       SessionStart hook itil-pending-questions-surface.sh re-surfaces queued questions every
       session until they are answered, and /wr-itil:work-problems Step 2.5 batches them at
       loop end. The ticket is authorised at one of those firings, not at an unfired re-entry
       point. -->
- **P445's rule** (unsolicited off-ramps, hedging, self-narration). Same job, same map, future
  third rib — a different rule with its own content, and no story yet.
- **CI blame across batched pushes** (P116, closed). It shares the unpushed-commit substrate but
  its subject is which commit CI attributes a regression to, not what a human reviewer can see.
- **No changeset is authored in this vehicle-authoring commit.** A changeset describing a fix
  that does not yet exist in the package is untruthful release metadata, which is the
  distinction ADR-099 draws. It lands with the code, in the implementation slice.

## Commits

(rendered from `git log --grep "Refs: RFC-053"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no commits yet.)

## Related

- **P439** (driving problem, inbound #326), **STORY-MAP-011** (the map), **STORY-050** (the
  story), **JTBD-011** (the grounding job).
- **RFC-052** — the sibling rule under the same job and map, blocked on the same mechanism ADR.
- **P423** — the master class: a correction that should govern the plugins or their adopters
  must land as a shipped surface, never as project-local memory. This RFC's scope obeys it.
- **P445** — sibling instance of the same job; rides the same map.
- **P116** (closed) — the adjacent unpushed-commit surface, and the reason this one needs
  stating separately.
