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

# Fix-time gate auto-creates a missing RFC (everywhere)

> **Rewritten 2026-05-26 (P314).** The original ADR-073 chose **hard-block + skip-to-next** on the rationale that RFC scope is direction-setting (ADR-044 cat-1) and the orchestrator must not author it. That was **rejected** at the `/wr-architect:review-decisions` drain (user correction: *"No, it's supposed to create the RFC if it's missing"*, scope *"Everywhere the gate fires"*). This rewrite records auto-create-everywhere. Sibling **ADR-072** (rewritten in the same pass) records the gate placement (propose-fix on a Known Error).
>
> **Amended 2026-06-28 (P399) — skeleton → full-scope authoring.** The auto-create stance above originally produced a **skeleton** RFC (empty `## Scope` placeholder, `stories: []`, no decisions), to be fleshed out later. In practice the "flesh out later" step never self-fired (P375 cadence-rot): 6 of 7 auto-created skeletons on 2026-06-28 (RFC-028/029/030/032/033/034) stayed at the empty `capture-rfc` placeholder while their traced fixes shipped — the systematically-under-scoped signal that is this ADR's own Reassessment Criterion. User ratified (2026-06-28 `/wr-itil:work-problems` loop-end decision surface): *"It's supposed to do the full work … properly create the RFCs, rather than a skeleton."* This amendment changes the Decision Outcome to **author the full RFC at fix-time** (populated `## Scope` + real `## Tasks` decomposition, derived from the already-traced problem). The substance changed, so `human-oversight` is downgraded `confirmed → unconfirmed` and the post-change ratification is queued for the next interactive drain (P357 + ADR-066 fallback — the loop-end direction authorises the *intent*, not a marker, since under AFK there is no post-change AskUserQuestion confirming the LLM's interpretation). The accepted **ADR-060 I13** invariant prose still reads "skeleton… fleshed out later" — its lockstep alignment is deferred as a tracked **RFC-005 task B11** (editing ADR-060 + ADR-073 in one pass trips the multi-decision-file architect-gate deadlock; same precedent as RFC-005's B2-followup I13 deferral). Until B11 lands, **this Decision Outcome is the authoritative substance** (ADR-031); I13's "skeleton" line is the stale derived view.

## Context and Problem Statement

ADR-071 makes the RFC mandatory for every fix; ADR-072 places the gate at the **propose-fix step on a Known Error**. This decides what happens when a fix is proposed on a Known Error and **no RFC exists**: block the work (and defer RFC authoring to the user), or auto-create the RFC?

## Decision Drivers

- ADR-071 has already pinned the direction: **every fix goes through an RFC**. A missing RFC is therefore not an open question — the mandatory vehicle simply needs instantiating.
- The RFC's scope is the **already-traced problem's fix** — auto-creating a problem-traced skeleton is instantiating the vehicle, not inventing direction.
- A hard-block stalls the AFK orchestrator and adds friction at the interactive surface; with the direction already pinned, blocking buys nothing.

## Considered Options

1. **Auto-create a problem-traced RFC if missing, everywhere the gate fires** (interactive `/wr-itil:manage-problem` + AFK `/wr-itil:work-problems`).
2. **Hard-block + skip-to-next** (the original ADR-073 — orchestrator refuses, advances to next-highest-WSJF candidate, surfaces a `capture-rfc` recovery prompt).
3. **Soft-route, orchestrator-only** (auto-create in the AFK loop only; hard-block at the interactive surface).

## Decision Outcome

Chosen option: **"Auto-create a problem-traced RFC if missing, everywhere the gate fires — authoring the full RFC, not a skeleton"** (user-ratified). When the propose-fix gate (ADR-072) fires on a Known Error with no RFC trace, the framework **auto-creates a problem-traced RFC and authors it fully from the already-traced problem context**: a populated `## Scope` (the fix being proposed plus the chosen implementation approach as prose) and a real `## Tasks` decomposition, derived from the problem's `## Root Cause Analysis` + `## Fix Strategy`. It carries **no decisions** (ADR-070-compliant: the implementation approach is chosen-path prose folded into `## Scope`, NOT a "Considered Options" / alternatives-rejected block). This fires at **every** fix-time surface: the interactive `/wr-itil:manage-problem` propose-fix action AND the AFK `/wr-itil:work-problems` orchestrator. A missing RFC is never a block anywhere.

The mechanism: `/wr-itil:capture-rfc` gains a `--fix-time` flag that authors `## Scope` + `## Tasks` from the traced problem instead of the deferred placeholders; the I13 gate in `/wr-itil:manage-problem` and the auto-create clause in `/wr-itil:work-problems` invoke it. The authored RFC is born `human-oversight: unconfirmed` (no per-RFC substance-confirm at fix-time; ratified at the `/wr-itil:manage-rfc accepted` drain). **Skeleton authoring was rejected** (the prior chosen sub-option) because the deferred "flesh out later" step never self-fires (P375), leaving the trace invariant satisfied structurally but hollow — see the 2026-06-28 amendment note above.

### ADR-044 reclassification (load-bearing)

The original ADR-073 classified orchestrator RFC-authoring as **ADR-044 category-1 (direction-setting)** — "RFC scope is direction-setting, the orchestrator must not author it." This ADR **reclassifies** *auto-creating AND fully authoring a problem-traced RFC* as **framework-mediated**, not cat-1 direction-setting: the direction (every fix goes through an RFC) is already pinned by **ADR-071**, and the RFC's scope is **derived** from the already-traced problem's RCA + Fix Strategy — not new direction *invented* by the orchestrator. The P399 amendment extends the reclassification along the same axis from "instantiate the vehicle (skeleton)" to "fully author the vehicle's scope": authoring `## Scope` + `## Tasks` from the traced problem is a *derivation* of pinned direction, not the *setting* of new direction. (The dividing line: enumerating ≥2 viable options and choosing among them — e.g. a Considered-Options block — would be cat-1 direction-setting; deriving the single fix the problem already implies is framework-mediated. The authored RFC carries no Considered-Options block precisely to stay on the framework-mediated side of that line.) This is a **scoping clarification of cat-1's boundary** — auto-creating and scoping the already-pinned mandatory vehicle is precisely the "don't re-ask a decision the framework already made" discipline (P132 / inverse-P078). **ADR-044's six-class taxonomy is unchanged** (no `amends:`); this ADR records where the cat-1 boundary sits for this surface.

This ADR records the auto-create stance. The propose-fix enforcement + auto-create mechanism ship as RFC-005's (corrected) task decomposition.

## Consequences

### Good

- The mandatory RFC vehicle (ADR-071) is always instantiated AND fully scoped — no fix is ever stalled or skipped for a missing RFC, and the trace is never hollow.
- Uniform behaviour at every fix-time surface (interactive + AFK).
- The authored RFC is ADR-070-compliant (problem-traced, chosen-path prose in `## Scope`, no Considered-Options block).
- The under-scoping failure mode is closed at authoring time rather than depending on a deferred "flesh out later" step that never self-fires (P375).

### Neutral

- Auto-authoring replaces the user-authors-it-first model; the authored RFC is born `unconfirmed` and the user ratifies/refines its scope at the `/wr-itil:manage-rfc accepted` drain (the RFC body, not its existence, is the editable surface).

### Bad

- The authored scope is the LLM's derivation of the fix from the problem trace; if the fix turns out larger than the problem implied, the RFC may still need refinement — but it starts from a real scope + task list, not an empty placeholder, so the refinement is an edit, not authoring-from-scratch.

## Confirmation

- The propose-fix gate (interactive + AFK) auto-creates a problem-traced RFC when none exists; it never hard-blocks for a missing RFC.
- The auto-created RFC carries a **populated, non-placeholder `## Scope`** (the fix being proposed) and a **real `## Tasks` decomposition** authored from the traced problem — NOT the deferred `capture-rfc` placeholder.
- The authored RFC carries no "Considered Options" block (passes the ADR-052 lint) and traces the driving problem.
- A behavioural test asserts the fix-time auto-create authors a non-placeholder `## Scope` + task list (not a skeleton).

## Pros and Cons of the Options

### Option 1 — auto-create everywhere, authoring the full RFC (chosen)

- Good: never stalls; uniform; instantiates AND fully scopes the ADR-071-mandatory vehicle; ADR-070-compliant; closes the under-scoping failure mode at authoring time rather than via a deferred step that never self-fires (P375).
- Bad: the authored scope is the LLM's derivation from the problem trace and may still need refinement at `manage-rfc accepted` — but starts from a real scope, not a placeholder. (The original skeleton sub-option — auto-create-but-defer-scoping — was rejected by the P399 amendment for systematic under-scoping.)

### Option 2 — hard-block + skip (original, rejected)

- Good: forces the user to scope the RFC up front.
- Bad: stalls the loop / adds interactive friction; treats RFC creation as user-direction when ADR-071 already pinned it — re-asking a decided question.

### Option 3 — soft-route orchestrator-only (rejected)

- Good: unstalls the AFK loop.
- Bad: partial — leaves the interactive surface hard-blocking; the user wants auto-create everywhere (uniform).

## Reassessment Criteria

The original skeleton-creation stance was revisited under exactly this criterion: auto-created skeletons were **systematically under-scoped** (6/7 on 2026-06-28; the deferred "flesh out later" step never self-fired — P375), which drove the P399 full-authoring amendment. Revisit further if the **authored** RFCs are systematically mis-scoped (a recurring "the auto-authored scope didn't match the real fix" signal at the `manage-rfc accepted` drain), or if a class of fixes emerges where auto-authoring produces noise rather than a useful vehicle.

## Related

- **ADR-071** — every fix goes through an RFC (pins the direction that makes auto-create framework-mediated, not direction-setting).
- **ADR-072** — RFC required at the propose-fix step on a Known Error (sibling; the gate placement this stance enforces).
- **ADR-070** — RFCs hold no independent decisions (the auto-created skeleton carries none).
- **ADR-044** — decision-delegation contract; this ADR reclassifies the cat-1 boundary for auto-creating a problem-traced skeleton (no taxonomy change).
- **ADR-060** — Problem-RFC-Story framework; its I13 invariant (rewritten under P314) cites this ADR for the auto-create behaviour.
- **JTBD-006** — Progress the Backlog While I'm Away; auto-create keeps the AFK loop moving rather than skipping RFC-less fixes.
- **P251** — RFC-first trace invariant not enforced at fix-time (driving problem).
- **P314** — the rework ticket that corrected this ADR's stance.
- **P399** — the amendment ticket that changed skeleton-creation to full-scope authoring (the 2026-06-28 systematic-under-scoping reassessment trigger).
- **P375** — the "flesh out later never self-fires" cadence-rot that made skeletons permanently under-scoped (the failure mode this amendment closes at authoring time).
- **RFC-005** — ships the auto-create mechanism (task decomposition; B11 lands the P399 full-authoring rework + the deferred ADR-060 I13 prose alignment).
- **RFC-006** — implementation RFC that originally extracted this decision (with the hard-block stance); P314 is its corrective follow-on.
