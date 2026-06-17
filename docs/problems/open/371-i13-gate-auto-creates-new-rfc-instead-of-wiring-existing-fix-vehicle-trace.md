# Problem 371: manage-problem I13 propose-fix gate auto-creates a new RFC instead of wiring an existing fix-vehicle's trace edge

**Status**: Open
**Reported**: 2026-06-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
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
- [ ] Add a pre-auto-create branch to the manage-problem I13 gate directive (Known Error traversal) + the predicate's directive text: before auto-creating, check whether an RFC cited in the ticket's `## Fix Strategy` / `## Resolution` / `## Dependencies` is the fix vehicle; if so, wire the problem's trace edge into that RFC's `problems:` array (and refresh the derived `## RFCs` section); auto-create a new skeleton ONLY when no candidate vehicle exists.
- [ ] Consider whether the `check-fix-rfc-trace.sh` predicate should itself surface candidate-vehicle RFCs (cited in the ticket body) alongside the `no-rfc-trace` directive, so the agent has the wire-target without re-deriving it.
- [ ] Create reproduction / behavioural coverage (a Known Error citing an existing RFC as its fix vehicle → gate directs wire-existing, not auto-create-new).

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P314, ADR-073, RFC-005

## Related

- **P314** (`docs/problems/known-error/314-rework-i13-gate-placement-and-auto-create-per-corrected-known-error-semantics.md`) — the I13-gate rework Known Error; this observation surfaced while working its Phase 2 (RFC-005 B2). The genuine consolidation parent — `/wr-itil:review-problems` should evaluate whether this folds into P314 as a follow-on or stays an independent SKILL-improvement ticket. P314 sits in `known-error/`, outside the capture-problem hang-off pre-filter's open/+verifying/ scan scope, so it could not be arbitrated by the Step 2b subagent.
- **ADR-073** (`docs/decisions/073-fix-time-gate-auto-creates-missing-rfc.proposed.md`) — auto-create-missing-RFC semantics. Architect-confirmed reading (this iter): auto-create is intended ONLY when no vehicle exists; an existing-but-untraced vehicle should have its trace edge wired, not be duplicated.
- **RFC-005** (`docs/rfcs/RFC-005-rfc-first-trace-invariant-not-enforced-at-fix-time.accepted.md`) — ships the I13 gate mechanism (predicate B3 + manage-problem gate B4 + work-problems carve-out B5); the directive gap is in B4's prose.
- captured via /wr-itil:capture-problem; hang-off-check verdict PROCEED_NEW (2026-06-17) — all 5 pre-filter candidates (P161, P310, P312, P315, P339) confirmed distinct root cause / fix locus; P312 closest lexically (RFC reverse-trace) but distinct surface (reconcile-rfcs script glob bug vs manage-problem gate directive branch).
