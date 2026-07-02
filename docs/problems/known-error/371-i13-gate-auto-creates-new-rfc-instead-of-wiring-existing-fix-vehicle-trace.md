# Problem 371: manage-problem I13 propose-fix gate auto-creates a new RFC instead of wiring an existing fix-vehicle's trace edge

**Status**: Known Error
**Reported**: 2026-06-17
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 = 9. Rated at review 2026-07-02: redundant RFC creation on rework tickets.
**Origin**: internal
**Effort**: M. WSJF = (9 × 1.0) / 2 = 2.25.
**JTBD**: JTBD-001, JTBD-008
**Persona**: plugin-developer

## Description

The `/wr-itil:manage-problem` Known Error fix-implementation traversal runs the I13 propose-fix RFC-trace gate (`wr-itil-check-fix-rfc-trace`) as a preamble. The gate directive offers exactly two branches: empty stdout → proceed; non-empty (`no-rfc-trace: P<NNN>`) → auto-create a problem-traced skeleton RFC via `/wr-itil:capture-rfc`. It has **no branch for the case where an existing RFC is already the ticket's fix vehicle but simply hasn't wired the problem's trace edge** into its `problems:` frontmatter array. Following the literal directive in that case auto-creates a redundant duplicate RFC, fragmenting the fix across two RFCs.

Evidence (P314 iter 2, 2026-06-17): working P314 Phase 2 (RFC-005 B2), the I13 gate predicate fired `no-rfc-trace: P314`. RFC-005 WAS P314's fix vehicle — P314's entire Phase 2 is RFC-005's B-task implementation, cited throughout P314's Resolution + Dependencies sections — but RFC-005's `problems:` array named only the original driver P251, not P314. The architect (this iter) confirmed the framework-correct resolution is to **wire P314 into RFC-005's existing `problems:` array** (existing-vehicle-trace), NOT to auto-create a new skeleton RFC — ADR-073's auto-create is intended ONLY when no vehicle exists. The iter applied that wiring manually (committed `a8360fe9`), but the SKILL directive does not instruct the agent to do so; an agent following the directive literally would have created the redundant RFC.

**Recurring class**: every rework / follow-on Known Error whose fix IS an existing RFC's task set hits this — the gate fires because the RFC's `problems:` array names the original driver problem, not the rework / follow-on ticket. The auto-create directive's "no vehicle exists" precondition is implicit in ADR-073 but not surfaced as an explicit pre-auto-create check in the SKILL.

## Symptoms

- I13 gate predicate emits `no-rfc-trace: P<NNN>` for a Known Error whose fix is an existing RFC's B-tasks (because that RFC's `problems:` array names the original driver, not this ticket).
- The manage-problem gate directive's only non-empty-stdout branch is "auto-create a new skeleton RFC" — literal compliance produces a redundant RFC fragmenting the fix.

## Workaround

Manually wire the problem's trace edge into the existing fix-vehicle RFC's `problems:` array (edit the RFC frontmatter `problems: [...]` to include the ticket ID), then re-run `wr-itil-check-fix-rfc-trace` to confirm the gate passes (empty stdout). Applied this way on P314 → RFC-005 in commit `a8360fe9`. Run `update-problem-rfcs-section.sh` afterward so the ticket's derived `## RFCs` section reflects the wired trace.

## Impact Assessment

- **Who is affected**: agents working any rework / follow-on Known Error whose fix is an existing RFC's tasks (interactive manage-problem AND AFK work-problems, since work-problems dispatches through the same traversal).
- **Frequency**: every such rework/follow-on fix-proposal; deterministic, not intermittent.
- **Severity**: Moderate — produces redundant duplicate RFCs (fix fragmentation + reverse-trace noise) when the directive is followed literally; mitigated today only by agent judgement (which is exactly what a SKILL directive should encode, not leave to chance).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Add a pre-auto-create branch to the manage-problem I13 gate directive (Known Error traversal) — DONE 2026-06-28: `packages/itil/skills/manage-problem/SKILL.md` non-empty-stdout branch split into (a) existing-vehicle-untraced → wire the trace edge + `wr-itil-update-problem-rfcs-section` + re-run predicate, vs (b) no-vehicle → auto-create (existing behaviour). `packages/itil/skills/work-problems/SKILL.md` constraint #3 carries the brief carve-out clause. Predicate's directive text left unchanged (see next task — kept SKILL-prose, no script signal).
- [x] Consider whether the `check-fix-rfc-trace.sh` predicate should itself surface candidate-vehicle RFCs — CONSIDERED, decided NO (kept SKILL-prose branch; architect-endorsed 2026-06-28). Distinguishing "fix vehicle" from "merely related / composes-with" is a judgement read of citation context, NOT deterministic from grep (P371 itself proves it: it cites RFC-005 in `## Related` as the *thing being fixed*, which a naive script "cited-RFC → vehicle" heuristic would mis-wire). Per ADR-060 I1 the deterministic membership question stays in the predicate; the vehicle-vs-related judgement is orchestrated skill-side. A deterministic *candidate-surfacing* enrichment (grep RFC-NNN tokens out of the ticket body) remains a clean possible follow-on if agent re-derivation proves costly, but is not required.
- [x] Create reproduction / behavioural coverage (a Known Error citing an existing RFC as its fix vehicle → gate directs wire-existing, not auto-create-new) — DONE for the load-bearing manage-problem surface 2026-06-28: paired Tier-A case added to `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml`, **3 consecutive runs GREEN** (paraphrase-proof anchors: wires into the cited vehicle's `problems:` array + runs `wr-itil-update-problem-rfcs-section` + names RFC-005; an over-tight "not auto-create" negation regex was dropped per the P270 brittleness lesson). This discharges the R009 in-source commit floor (the fix commit landed within appetite). **Still pending** (the held changeset's remaining reinstate criterion): a paired work-problems eval case for constraint #3's AFK carve-out at `packages/itil/skills/work-problems/eval/promptfooconfig.yaml` — the changeset bumps `@windyroad/itil` for both skill edits, so the work-problems surface needs its own case before the changeset ships. Tracked under the P012 / RFC-012 harness-extension backlog (work-problems-eval sibling cohort).

## Fix Strategy

**Release vehicle**: .changeset/wr-itil-p371-i13-existing-vehicle-trace-branch.md (held in `docs/changesets-holding/` per ADR-042 Rule 2 — see Fix Implemented).

The fix is the third gate branch (existing-vehicle-untraced → wire, not auto-create). It IS RFC-005's B4 deliverable (B4 = the manage-problem I13 gate prose); the directive gap lived in B4's prose. RFC-005 is therefore P371's fix vehicle — the I13 gate's own existing-vehicle-untraced branch was dogfooded to wire P371's trace edge into RFC-005's `problems:` array rather than auto-create a redundant RFC.

## Fix Implemented (2026-06-28)

SKILL-prose-only change (no predicate/script change — the `no-rfc-trace` answer is correct; the gap was that the SKILL offered only one response):
- `packages/itil/skills/manage-problem/SKILL.md` — I13 gate non-empty-stdout branch split into existing-vehicle-untraced (wire) vs no-vehicle (auto-create).
- `packages/itil/skills/work-problems/SKILL.md` — constraint #3 carve-out clause.
- `docs/rfcs/RFC-005-...accepted.md` — `problems:` array gains P371 (dogfood of the new branch); P371 `## RFCs` section refreshed via `wr-itil-update-problem-rfcs-section`.
- `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` — paired Tier-A promptfoo case for the existing-vehicle-untraced → wire branch (3 consecutive runs GREEN); discharges the R009 in-source commit floor so the fix commit lands within appetite.

Architect APPROVED (within-decision SKILL-prose refinement; ADR-073-compliant — auto-create is the no-vehicle case only; no new ADR). JTBD PASS (JTBD-008 primary, JTBD-001, JTBD-006). External-comms + voice-tone PASS on the changeset draft. The manage-problem eval green discharges the R009 floor for the load-bearing surface → the fix commit landed within appetite. The changeset still bumps `@windyroad/itil` for the work-problems edit too, whose constraint #3 carve-out is NOT yet eval-covered → changeset moved to `docs/changesets-holding/` per ADR-042 Rule 2 pending a paired work-problems eval case (see the holding-README reinstate criterion). Ticket stays Known Error (fix landed in-source, not yet shipped) until the changeset graduates + releases → then Known Error → Verifying.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P314, ADR-073, RFC-005

## Related

- **P314** (`docs/problems/known-error/314-rework-i13-gate-placement-and-auto-create-per-corrected-known-error-semantics.md`) — the I13-gate rework Known Error; this observation surfaced while working its Phase 2 (RFC-005 B2). The genuine consolidation parent — `/wr-itil:review-problems` should evaluate whether this folds into P314 as a follow-on or stays an independent SKILL-improvement ticket. P314 sits in `known-error/`, outside the capture-problem hang-off pre-filter's open/+verifying/ scan scope, so it could not be arbitrated by the Step 2b subagent.
- **ADR-073** (`docs/decisions/073-fix-time-gate-auto-creates-missing-rfc.proposed.md`) — auto-create-missing-RFC semantics. Architect-confirmed reading (this iter): auto-create is intended ONLY when no vehicle exists; an existing-but-untraced vehicle should have its trace edge wired, not be duplicated.
- **RFC-005** (`docs/rfcs/RFC-005-rfc-first-trace-invariant-not-enforced-at-fix-time.accepted.md`) — ships the I13 gate mechanism (predicate B3 + manage-problem gate B4 + work-problems carve-out B5); the directive gap is in B4's prose.
- captured via /wr-itil:capture-problem; hang-off-check verdict PROCEED_NEW (2026-06-17) — all 5 pre-filter candidates (P161, P310, P312, P315, P339) confirmed distinct root cause / fix locus; P312 closest lexically (RFC reverse-trace) but distinct surface (reconcile-rfcs script glob bug vs manage-problem gate directive branch).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-005 | accepted | RFC-first trace invariant not enforced at fix-time |
