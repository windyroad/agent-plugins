---
status: proposed
rfc-id: verification-evidence-write-path-for-prior-session-drain
reported: 2026-07-26
human-oversight: unconfirmed
decision-makers: [Tom Howard]
problems: [P450]
adrs: [ADR-026, ADR-022, ADR-031, ADR-052, ADR-044, ADR-073, ADR-085, ADR-089, ADR-090, ADR-096]
jtbd: [JTBD-006, JTBD-001]
stories: []
---

# RFC-055: Verification-evidence write path for the run-retro Step 4a prior-session drain

**Status**: proposed
**Reported**: 2026-07-26
**Problems**: P450
**ADRs**: ADR-026 (evidence grounding), ADR-022 (lifecycle semantics + the cell's reconciliation carve-out), ADR-031 (`docs/problems/README.md` is a rendered index), ADR-052 (behavioural tests), ADR-044 (framework-resolution boundary), ADR-073 (fix-time RFC auto-create + new-approach-needs-an-ADR), ADR-085 (derived-view precedent), ADR-089 / ADR-090 / ADR-096 (story ratification gates)
**JTBD**: JTBD-006 (primary — progress the backlog while I'm away), JTBD-001 (secondary — audit-trace facet)

## Summary

The verification lifecycle has a consumer with no producer. `/wr-retrospective:run-retro` Step 4a sub-step 9 reads the `Likely verified?` column of the Verification Queue in `docs/problems/README.md`, filters to rows reading `yes — observed: …`, and closes those tickets. Nothing writes that value onto a still-verifying row when a later session exercises the fix.

The queue currently holds 129 rows. Exactly one carries evidence. The drain is not broken — it is starved, and the backlog is drained instead by occasional manual multi-agent triage passes.

This RFC scopes the missing producer, plus a guard closing a laundering path discovered while diagnosing it.

## Driving problem trace

- **P450** (`docs/problems/known-error/450-vq-evidence-cells-have-no-write-path-from-subsequent-sessions-drain-starved.md`) — Known Error. Inbound-reported (#323). Root cause confirmed 2026-07-26 across four findings: (1) a 129-row census showing 128 cells read `no — not observed`; (2) a survey of all 37 commits ever touching the evidence token showing every write is a close-time audit annotation on an already-closed row, never a producer, while the Known Error → Verification Pending render writes the `no — not observed` default and no later surface revisits it; (3) the one informal producer observed in the wild writes same-session evidence onto its own row and was laundered into a close one session later, because the drain's same-session exclusion keys off the ticket rename date rather than the cell write date; (4) a correctly-populated cell has sat undrained for eleven days, demonstrating the shape is useful and the gap is real. The clobber hypothesis (a producer wrote and a regeneration reset it) was tested with a dedicated discriminator over all 37 commits and returned zero hits, so the state is pure starvation.

## Scope

Two coupled changes, plus one decision that must be ratified before either can be implemented.

**The producer.** run-retro Step 4a sub-step 3 already collects ADR-026-grounded citations (tool invocation plus observable outcome) and sub-step 4 buckets each verifying ticket. When a ticket lands in the "exercised successfully" bucket but the close does not complete, the citation is written only to a transient retro summary table and lost at session end. The fix persists that citation as durable verification evidence so the next session's drain acts on it. The path sits downstream of sub-step 8's same-session exclusion, so same-session evidence can never reach it — this is what keeps the producer honest by construction rather than by policy prose.

The persist trigger needs a **withhold taxonomy**, which this RFC treats as in-scope design rather than implementation detail. Mechanical transport failures (the existing `dispatch-failed` and `dispatch-unavailable` outcomes) are unambiguously right to persist. A close withheld because a human wants to look at it is not — persisting it as drainable would let the next session silently convert a human hold into an auto-close, which crosses JTBD-006's constraint that the persona *"does not trust the agent to make judgment calls (verify fixes work)"* and rewrites its *"queued for my return, not guessed at"* outcome into "guessed at one session later". The taxonomy must separate the two and only the mechanical class becomes drainable.

Persisted evidence must also **bind to the release it evidences**. A citation is grounded at the moment of capture but becomes a standing claim once it crosses a session boundary. A ticket that flips back to `known-error` under the regression bucket and is later re-released returns to `verifying` still carrying evidence for the *previous* fix, and no same-session guard catches that, because the evidence's provenance session genuinely is a prior one. The record carries the release marker (already extracted by sub-step 2) and the drain rejects evidence older than the current `## Fix Released` marker.

**The anti-laundering guard.** The drain's same-session exclusion is re-keyed from "the `.verifying.md` rename was committed this session" to the evidence's write provenance, closing the path by which a fix-shipping session self-certifies and a later session closes on it. Provenance must be git-derivable rather than a self-attested in-file marker the same session could equally forge — JTBD-006's audit-trail constraint. This guard needs no ADR of its own: its intent is already ratified by sub-step 8's rule that a session cannot verify its own fix, carried by ADR-022's lifecycle semantics, and re-keying a guard from a broken proxy to the correct signal is a bug fix rather than a new decision.

**Ownership.** run-retro Step 4a is the right detector and the wrong writer — its own ownership boundary states it does not rename, edit the Status field, or commit, and ADR-014 lists it as out of scope for its own commits. The write belongs on an itil surface, reached through the same delegation contract sub-step 5 already uses.

**Read-cost.** The queue is 129 rows and this table has previously reached 134 KB, exceeding the Read-tool whole-file cap. The persist mechanism must be a targeted row rewrite rather than a whole-file read-modify-write, or Step 4a degrades as the queue grows.

### Blocking decision — where the evidence is stored

The naive design writes the `Likely verified?` cell directly. Architecture review established that this stores durable state in a **rendered projection**: ADR-031 names `docs/problems/README.md` the canonical rendered index with the per-state ticket files as source of truth, and ADR-085 re-pinned that principle for the sibling RFC surface, rejecting its own first option precisely because it stored state in the view. Every other Verification Queue column derives from the ticket body; this cell alone derives from nothing. The render path is documented to be able to reset it, `reconcile-readme.sh` is read-only by design, and ADR-022's Confirmation explicitly excludes the cell from the reconciliation invariant — so drift in this store would be undetectable by construction. The guard would additionally have to reconstruct write provenance by git archaeology over a large file, which is the same proxy-signal defect class the guard exists to remove.

The cell is already narrative-only state, ratified in passing by P186 and acknowledged by ADR-022. What this fix would introduce is the **escalation** — promoting an incidentally-narrative cell into the durable store of record for an automated close decision. That is an approach-choice no existing ADR covers, so per ADR-073's Confirmation (*"A fix whose approach-choice is not covered by existing ADRs has a new ratified ADR before implementation"*) this fix requires a **new ratified ADR** before implementation, not merely this RFC.

The candidate options and the architect's advisory lean are recorded on P450 for the ratification drain. Per ADR-070 the substantive choice homes in that ADR, not here.

**Cadence (ADR-087).** This deferral is re-surfaced by a self-firing trigger, not by an on-demand re-entry point: `packages/itil/hooks/itil-rfc-oversight-nudge.sh` is registered under `SessionStart` with `matcher: "startup"` in `packages/itil/hooks/hooks.json`, so this RFC re-surfaces at every interactive session start for as long as `human-oversight: unconfirmed` stands. Independently, the `/wr-itil:work-problems` loop pre-flight re-ranks P450 at every loop start, and P450 carries this queued decision in its Fix Strategy. Two self-firing surfaces, neither requiring anyone to remember to run a command.

**Reassessment composition (advisory).** ADR-022 (`reassessment-date: 2026-07-19`) and ADR-031 (`reassessment-date: 2026-07-20`) are both overdue as of capture, and they are the two decisions this storage choice sits directly on top of — ADR-031 supplies the rendered-index-is-a-projection principle, and ADR-022's Confirmation is what currently excludes the `Likely verified?` cell from the reconciliation invariant. If the ticket-body option is picked, the resulting ADR amends both. Worth folding the overdue reassessments into the same ratification pass rather than running them separately.

## Stories

Deliberately empty this iteration. **This is a hold, not an omission.**

The storage decision above determines the story's acceptance criteria almost entirely — one option writes a markdown cell, another adds a section to the problem-ticket data model and changes the render path in two skills. Authoring acceptance criteria against an unratified pick is the exact failure recorded as P315, where dependent work was built on a born-`proposed` decision the user later rejected and had to be reworked under P314. The substance is confirmed before the dependent work is built, not after.

This is also the only move that satisfies ADR-095 and ADR-074 simultaneously. ADR-095 requires a story to be born with a real `## User value` and at least one real acceptance criterion — no placeholders. Since one option yields "write a cell" and another yields "new ticket-body section plus render changes across two skills", any criteria authored now would be either placeholder (breaching ADR-095) or derived from an unratified pick (breaching ADR-074).

**Recorded divergence.** `packages/itil/skills/capture-rfc/SKILL.md` line 217 instructs the `--fix-time` path to author the fix's stories onto a story map and list them in `stories:`. This RFC authors none. The divergence is deliberate and was ruled compliant at architecture review: that SKILL line is a derived expression of ADR-089 / ADR-095 / ADR-096, and ADR-074 is the higher-order rule governing the collision it creates here.

When the storage decision is ratified, the story's home is the existing `STORY-MAP-002` A5 activity ("Land, release & verify → adopter value") alongside STORY-023 — reuse satisfies ADR-095 without a new map. Note that map carries an `oversight-hash`; adding a card invalidates it under ADR-090 and queues a re-ratification, which is the expected born-unconfirmed consequence of AFK authoring rather than a blocker.

Two lifecycle constraints bind this RFC in the meantime: ADR-090 bars listing an unratified story in `stories:`, and ADR-089 bars an RFC proposed for a fix from reaching `accepted` with an empty stories list. Together they hold this RFC at `proposed` — consistent with the code hold, not a deadlock.

**Cadence (ADR-087).** The story hold rides the same two self-firing triggers as the blocking decision above — the `SessionStart` `startup` registration of `packages/itil/hooks/itil-rfc-oversight-nudge.sh` (this RFC is `human-oversight: unconfirmed`, so it surfaces every interactive session start), and the `/wr-itil:work-problems` loop pre-flight re-rank of P450. The story-side detector `wr-itil-detect-unratified-stories-maps` is deliberately NOT cited: no story exists for it to detect, so citing it would be a fictional trigger.

## Behavioural coverage

Per ADR-052, and behavioural rather than structural grep on SKILL prose per P081:

1. The persist path fires when a ticket is bucketed "exercised successfully" and the close does not complete.
2. The persist path is silent on the "not exercised" bucket.
3. The guard rejects evidence written by the fix-shipping session.
4. A persisted value survives a `docs/problems/README.md` regeneration. This is the assertion that discriminates between the storage options — under the cell-as-store option it is expected to be the hard one to make green.
5. Evidence predating the current `## Fix Released` marker does not close the ticket.
6. The retro summary reports a third outcome distinct from *closed* and *dispatch-failed-and-lost*: evidence persisted, will drain next session. JTBD-006 requires the return summary to show what remains, and omitting this understates the queue's real state.

**Cadence (ADR-087).** The code hold is released by the ADR-096 story gate — implementation requires the story at `accepted`, and the `accepted` transition is what unblocks it. Until then the hold re-surfaces via the same `SessionStart` `startup` oversight nudge and the `/wr-itil:work-problems` pre-flight re-rank of P450 named above; the itil no-implement-draft gate blocks any attempt to implement ahead of ratification, so the hold is enforced rather than merely documented.

## Commits

(rendered from `git log --grep "Refs: RFC-055"` by `/wr-itil:manage-rfc` + `wr-itil-reconcile-rfcs` per ADR-085 — a git-log-derived view, not stored per-commit. At capture there are no implementation commits yet; the code is held pending the storage decision and the ADR-096 story gate.)

## Related

- **P450** — driving problem (Known Error).
- **P463** — the relevance-close evaluator over-fires, reading a bare citation as proof a fix shipped. Same evidence-versus-inference honesty concern from the opposite side: P463 is a consumer treating a citation as proof, this RFC is a producer that must never write a citation it has not observed.
- **P186** — shipped the evidence-first cell shape this RFC's producer would feed. Closed.
- **P282** — shipped the consumer (sub-step 9 prior-session drain).
- **P375** — named-re-entry versus self-firing cadence. Class-adjacent: the drain exists but its input producer never fires.
- **P311** — the no-shortcuts correction, which bears directly on the ship-now-relocate-later option.
- **P315 / P314** — dependent work built on an unratified decision, then reworked. The precedent behind holding the story.
