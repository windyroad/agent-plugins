---
status: "proposed"
date: 2026-05-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-08-26
problems: [P251, P314, P399]
---

# RFC-first: a problem's fix implements its RFC; no implementation without a pre-existing RFC

> **Filename is legacy.** This file is named `073-fix-time-gate-auto-creates-missing-rfc` after an earlier stance that has now been reversed (see History). The decision this ADR records is **RFC-first**: an RFC is a hard precondition for fix work, not something the gate fabricates at fix time.

> ## History (the stance evolved — and the middle two were wrong)
>
> 1. **Original (RFC-006).** Hard-block + skip: the propose-fix gate refused to proceed without an RFC and skipped to the next ticket, deferring RFC authoring to the user.
> 2. **2026-05-26 (P314) — WRONG.** Rewritten to **auto-create the RFC at fix-time and never block** (a skeleton tracing the problem), on the rationale that ADR-071 already pins "every fix goes through an RFC" so a missing RFC is just a vehicle to instantiate. This optimised for AFK-loop velocity (JTBD-006).
> 3. **2026-06-28 (P399) — STILL WRONG.** Amended the auto-create to author a full `## Scope` + `## Tasks` from the problem instead of a skeleton, after skeletons proved systematically under-scoped (the "flesh out later" step never self-fires — P375).
> 4. **2026-06-29 (this rewrite) — CORRECTED.** User flagged the load-bearing error in (2) and (3): **the problem MUST have an RFC *before* fix work starts — you cannot fix and then create the RFC retrospectively.** Implementing a fix for a problem *is* implementing that problem's RFC. The RFC is **stories in a user story map** (ADR-060), not a `Scope`+`Tasks` prose blob. Where the fix's approach involves genuine options, the RFC's choice is captured in an **ADR that must be ratified before implementation**. "Auto-create at fix-time and never block" is rejected: it permits implementation to commence without a real, pre-existing, options-resolved RFC — the exact invariant violation. The P399 mechanism (`capture-rfc --fix-time` authoring scope/tasks as a byproduct of the fix) is therefore **held, not shipped**, pending rework to this corrected model. **Lockstep:** ADR-072 (gate placement, currently `confirmed`) and ADR-060's I13 invariant (currently `accepted`) still encode the rejected auto-create/never-block stance and require matching amendment — see Related + the lockstep note in Consequences.

## Context and Problem Statement

ADR-071 makes an RFC mandatory for every fix; ADR-072 places the propose-fix gate at the point fix work commences on a Known Error; ADR-060 establishes the Problem → RFC → Story framework (an RFC is **comprised of stories in a user story map**). This ADR decides the **ordering and authorship contract**: when may fix implementation begin relative to the RFC's existence?

The user's invariant (2026-06-29): **a problem must have an RFC before any fix work starts; fixing the problem is implementing that RFC; you cannot fix first and write the RFC after.**

## Decision Drivers

- **Process integrity over loop velocity.** The RFC (story map) is the *plan*; implementation *executes the plan*. A plan authored after the fact is not a plan — it is a hollow trace. The user has explicitly prioritised this correctness over the AFK loop's "never stall" (JTBD-006).
- **The trace must be genuine.** ADR-071's "every fix goes through an RFC" means the fix is *driven by* its RFC, not retro-fitted to one. A skeleton or fix-time-fabricated RFC satisfies the trace structurally while being hollow.
- **The RFC leans on existing ADRs; a new decision is the exception, not the rule.** The RFC should derive its plan from the already-decided corpus wherever it can. A new ADR is needed **if and only if** the fix requires a decision that existing ADRs do not cover. An *uncovered* choice among ≥2 viable approaches is a cat-1 decision (ADR-044) and an independent decision (ADR-070) — it belongs in a new **ADR ratified before implementation**, not silently picked by the orchestrator; a *covered* choice is settled direction the RFC simply cites.
- **An RFC is stories in a user story map** (ADR-060) — its content is a story decomposition, not free-prose scope.

## Considered Options

1. **RFC-first precondition (chosen).** No fix implementation may begin until the problem has an RFC (stories in a user story map). The RFC is authored after root-cause identification and before fix work; where the fix involves options, an ADR captures + ratifies the choice before implementation.
2. **Auto-create at fix-time, never block** (the 2026-05-26 / 2026-06-28 stance — rejected). Lets implementation proceed and fabricates the RFC during/after — violates the RFC-first invariant; produces hollow traces; silently picks among options with no ratified ADR.
3. **Hard-block + skip-to-next** (the original — rejected as a *whole* answer). Correct that it blocks, but it defers ALL authoring to the user and just skips the ticket, which strands the work rather than advancing it to "author the RFC next".

## Decision Outcome

Chosen option: **RFC-first — an RFC is a hard precondition for fix implementation.**

When fix work is proposed on a Known Error (ADR-072's gate point):

1. **If an RFC already traces the problem** → proceed to implement it. Implementing the fix *is* implementing the RFC's stories.
2. **If no RFC exists** → fix implementation MUST NOT begin. The required next action is to **author the RFC first** — a user-story-map decomposition of the fix, derived from the problem's Root Cause Analysis. Only once the RFC exists does implementation (of its stories) begin.
3. **The RFC leans on existing ADRs; a new ADR is needed IFF the decision is outside their coverage.** When authoring the RFC surfaces a genuine choice for the fix approach (≥2 viable paths), first check the existing decision corpus:
   - **If existing ADRs already resolve the choice** → the RFC **cites them and proceeds**. No new ADR — minting one would re-decide a settled question (the P132 / inverse-P078 anti-pattern). This is the common case and should be the default reflex: lean on what's already decided.
   - **If and only if the decision falls outside the coverage of existing ADRs** (a genuinely new decision) → it is captured in a **new ADR, ratified before implementation**. The orchestrator does **not** make an out-of-coverage decision itself; it surfaces it for ratification.

**Authorship.** The agent/orchestrator MAY author the RFC's story-map decomposition when the fix is unambiguous *or* when its choices are already covered by existing ADRs — this is framework-mediated *derivation of the agreed fix's plan* (the direction is pinned by ADR-071 and any cited ADRs), done as a deliberate pre-implementation step (NOT a byproduct emitted during/after the fix). It MUST NOT author past a genuine, **uncovered** decision: that escalates to a new ratified ADR first. **Retrospective RFC creation (implement-then-document) is prohibited.**

This **supersedes** both the "skeleton auto-create" (P314) and the "full-scope fix-time authoring" (P399) stances. The `capture-rfc --fix-time` mechanism shipped under P399 is held pending rework to author the RFC as a pre-implementation story map (not a fix-time Scope/Tasks byproduct), and to route option-bearing fixes through a ratified ADR.

### ADR-044 boundary (corrected — retracts the P399 framing)

The P399 amendment asserted that auto-creating AND fully authoring the RFC is **all** framework-mediated, and that the authored RFC "carries no Considered-Options block precisely to stay on the framework-mediated side." That over-broad claim is **retracted**. The correct split:

- Authoring the RFC's **story decomposition for a fix that is unambiguous OR whose choices are already covered by existing ADRs** (ordering already-decided work) = **framework-mediated**. The orchestrator may do this autonomously, as a pre-implementation step, **citing the ADRs it leans on**.
- **Choosing among ≥2 viable fix approaches that existing ADRs do NOT cover** = **cat-1 direction-setting** (ADR-044) and an **independent decision** (ADR-070) → a **new** ADR, **ratified before implementation**. The orchestrator may NOT decide this.

The pivot is **coverage by the existing decision corpus**, not merely "are there options." A choice that existing ADRs already resolve is settled direction the RFC *derives from* (framework-mediated — cite and proceed); a new ADR is needed **if and only if** the decision lies outside existing coverage. This is the same boundary test ADR-070 already draws (an *independent, uncovered* choice among ≥2 viable options → ADR; ordering of already-decided work → stays in the RFC) and the same "don't re-ask a decision the framework already made" discipline (P132). ADR-044's six-class taxonomy is unchanged (no `amends:`); this ADR corrects *where* it previously placed the cat-1 line.

## Consequences

### Good
- The RFC is always a real, pre-existing plan; the fix implements it; the trace is genuine, not a hollow retrospective artefact.
- Option-bearing fixes get a ratified ADR before any code is written (the ADR-074 substance-confirm-before-build discipline, made structural here).
- The RFC is a story map (ADR-060-shaped), the framework's canonical unit of planned work.

### Bad / cost
- The AFK loop can no longer start building the instant it selects a Known Error: it must author the RFC (story map) first, and STOP for ADR ratification when options exist. This trades loop velocity for process correctness — the user's explicit priority over JTBD-006's never-stall.
- More work reaches a genuine stop (option-bearing fixes block for ratification) than under "never block".
- **Lockstep cost.** ADR-072 (`confirmed`) and ADR-060's I13 invariant (`accepted`) currently characterise the missing-RFC response as auto-create-never-block and must be amended to match (each in its own architect-gate pass to avoid the multi-decision-file edit deadlock; ADR-072 and the I13 behavioural-test wording both change). Until those land, ADR-031 makes *this* ADR's Decision Outcome the authoritative substance, but an `accepted` invariant (I13) carrying the opposite rule is an integrity hazard, not a cosmetic lag — the I13 rewrite is required, not optional.

### Neutral
- The agent still authors the RFC's stories autonomously for unambiguous fixes; only genuine option-choices escalate to a ratified ADR.

## Confirmation

- The propose-fix gate (interactive + AFK) refuses to begin fix implementation when no RFC traces the problem; the required next action is RFC authoring (a user-story-map decomposition), not fix code.
- An authored RFC is comprised of stories in a user story map (ADR-060), not a `Scope`+`Tasks` prose blob.
- A fix whose approach-choice is **not covered** by existing ADRs has a **new** ratified ADR before implementation; a fix whose choice **is covered** proceeds, citing the existing ADRs, with **no new ADR**. The orchestrator does not make an uncovered decision.
- A behavioural test asserts: (a) implementation of a fix on an RFC-less Known Error is refused / routed to RFC authoring; (b) a fix with an **uncovered** approach-choice blocks for a **new** ratified ADR; (c) a fix whose choice is **covered** by existing ADRs proceeds (RFC cites them, no new ADR).

## Pros and Cons of the Options

### Option 1 — RFC-first precondition (chosen)
- Good: process integrity; genuine trace; options ratified before build; RFC-as-story-map honoured.
- Bad: the loop stalls for RFC authoring + option-ratification — slower, but correct (the user's priority).

### Option 2 — auto-create at fix-time, never block (rejected)
- Good: maximal loop velocity; never stalls.
- Bad: violates the RFC-first invariant; hollow traces; silently picks among options (no ratified ADR) — the error this rewrite corrects.

### Option 3 — hard-block + skip-to-next (rejected)
- Good: blocks (correct).
- Bad: strands the work (skips the ticket) instead of advancing it to "author the RFC next"; defers all authoring to the user.

## Reassessment Criteria

Revisit if RFC-first proves to stall the loop so severely that throughput collapses with no offsetting quality gain (i.e. if unambiguous fixes routinely block where autonomous story-map authoring should have advanced them) — that would indicate the framework-mediated authorship carve-out is too narrow, not that RFC-first is wrong. The invariant itself (RFC before implementation; no retrospective RFC) is user-pinned and not subject to velocity-based reassessment.

## Related

- **ADR-071** — every fix goes through an RFC (the mandate this ordering enforces). `confirmed`.
- **ADR-072** — RFC required at the propose-fix step on a Known Error (the gate point). **Requires lockstep amendment**: its body (auto-create / never-block characterisation) contradicts this rewrite; `confirmed` → `unconfirmed` + P357 re-ratify.
- **ADR-070** — RFCs hold no independent decisions (options live in an ADR, ratified before implementation — consistent here, and the boundary test cited above).
- **ADR-060** — Problem → RFC → Story framework; **an RFC is comprised of stories in a user story map**. Its **I13 invariant (accepted)** still encodes auto-create-skeleton-rather-than-block + the mandated behavioural test — **requires lockstep rewrite**.
- **ADR-044** — decision-delegation contract; this ADR sets the cat-1 boundary: unambiguous story-decomposition = framework-mediated; option-choice = direction-setting (ratified ADR before implementation).
- **ADR-074** — substance-confirm before building dependent work; RFC-first + options→ratified-ADR makes that discipline structural for fixes.
- **JTBD-006** — Progress the Backlog While I'm Away; deliberately subordinated to process correctness here.
- **P251** — RFC-first trace invariant not enforced at fix-time (driving problem).
- **P314** — the rework ticket that introduced the (now-rejected) auto-create stance.
- **P399** — the amendment ticket whose full-scope fix-time authoring is superseded by this RFC-first correction; its `--fix-time` changeset is held pending rework.
- **P375** — the "deferred step never self-fires" cadence-rot that made skeletons hollow (one symptom of the deeper RFC-first violation).
- **RFC-005** — the implementation RFC for the fix-time mechanism; its tasks need reworking from "author at fix-time" to "RFC-first as a pre-implementation gate".
