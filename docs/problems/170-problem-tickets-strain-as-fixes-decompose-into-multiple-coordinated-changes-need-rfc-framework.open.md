# Problem 170: Problem tickets strain as fixes decompose into multiple coordinated changes — need an RFC framework that ties all changes back to problems (and unifies technical with user/business problems)

**Status**: Open
**Reported**: 2026-05-04
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `docs/problems/` framework was designed when each problem mapped 1:1 to a fix — one ticket, one commit (or a tight handful), one closure. As the project has matured, that mapping no longer holds. Recent examples:

- **P168** decomposed into 3 commits (ADR-059 design + Commit 1 ab73328 + Commit 2 af5447c + Commit 3 8edaf7b) plus a deferred Commit 3' under Phase 2.
- **P159** shipped Phase 1 (load-bearing commit-hook) but explicitly deferred Phase 2-3 (12-README prose-weaving + auto-fix orchestration), each of which is a separate body of work needing its own architect/JTBD/test scope.
- **P051** has 6 separate "improve" shapes (improve-skill / improve-agent / improve-hook / improve-rule / improve-template / improve-prompt) each potentially a multi-commit workstream.
- **P169** (newly captured) is itself "Phase 1 scorer-side, Phase 2 bootstrap-side" — explicitly two coordinated workstreams under one ticket.

When fixes decompose like this, the problem-ticket structure starts carrying load it wasn't designed for: it accumulates "Fix Strategy" sections that mutate as work progresses; "Investigation Tasks" turn into multi-phase work plans; the ticket body becomes a moving target rather than a stable problem-statement-plus-RCA. The structural drift surfaced concretely when P169 was authored — the ticket was largely a workstream description ("Phase 1 updates pipeline.md…", "Phase 2 ships starter catalogue…") rather than a problem statement. User observation 2026-05-04: *"P169 is not really a problem ticket. It's more of a task masquerading in the problem ticket structure."*

The classic ITIL answer is **Request for Change (RFC)** — a controlled, scoped, time-boxed change ticket that owns the work to fix a problem. Multiple RFCs can trace to one problem when the fix is large enough to need decomposition (typical for refactors, multi-package coordination, phased migrations). User direction 2026-05-04 names two non-ITIL extensions:

1. **All RFCs MUST trace to a problem** (no orphan RFCs). ITIL allows RFCs to come from non-problem sources (continuous improvement, opportunity, regulatory mandate); Windy Road's framework treats every change as solving some problem — even a feature build is a customer's problem. The trace-to-problem invariant makes WSJF prioritisation work uniformly across the project.

2. **Technical problems and user/business problems are treated identically** in the framework. ITIL's Service Strategy / Demand Management splits "Service Request" from "Problem"; this project collapses them. A bug, a missing feature, a UX gap, an adopter's pain point, a future JTBD job — all are problems. The /wr-itil:capture-problem and /wr-itil:manage-problem skills already accept user/business problems alongside technical bugs (P078 capture-on-correction explicitly anchors on user-experience signal). Future direction: unify JTBD job statements with the problem framework so that a JTBD-001 (enforce governance) jobs-to-be-done description IS a problem ticket of class "user/business" — same WSJF, same RFC decomposition, same lifecycle.

**Story decomposition via Jeff Patton's User Story Mapping** is the candidate vehicle for breaking an RFC into stories. Backbone (the spine of the user journey) + ribs (the sub-flows) + slices (the time-ordered MVP / version-2 / version-N slices). RFC owns the scope; stories are the INVEST-shaped work items inside it; each story is JTBD-anchored where applicable (which job does this story serve?). ADRs continue to capture decisions — an RFC may reference one or more ADRs (the ADR is the "how we decided", the RFC is the "what we're shipping").

## Symptoms

- Problem tickets accumulate multi-phase Fix Strategy sections that drift from "what's the problem" to "how are we executing" — `docs/problems/168-...verifying.md` is the canonical example (3-commit Fix Strategy with Smoke-Test Finding sub-sections).
- New tickets are captured that are largely workstream descriptions rather than problem statements — P169 is the first explicitly-flagged instance.
- The lifecycle states (`Open` / `Known Error` / `Verifying` / `Closed`) don't have natural placeholders for "Phase 1 closed, Phase 2 in flight" — the workaround is to capture Phase 2 as a sibling problem (e.g. P169 sibling to P168) but this loses the parent-child trace structure.
- Deferred sub-work loses visibility — P159's deferred Phase 2-3 work sits in the ADR-051 "Out of scope" section but isn't WSJF-ranked as standalone items.
- ADR-014 single-commit-grain plus held-changeset dogfood + ADR-042 graduation criteria already imply RFC-shaped change management (multi-commit coordinated change with explicit reinstate trigger), but the framework isn't named or formalized.
- JTBD job statements in `docs/jtbd/` describe user/business problems but live in a parallel hierarchy from `docs/problems/` — the unification gap is observable but not closed.

## Workaround

Currently:
- **Multi-phase fixes ride one problem ticket with a multi-section Fix Strategy** (P168 model). Works for 2-3 commit decompositions; strains beyond that.
- **Sibling problem tickets capture explicitly-deferred phases** (P169 as P168 follow-up). Works but loses parent-child trace; future re-derivation of "what work was needed for X" requires graph traversal across tickets.
- **Workstream-shaped problem tickets are accepted with a note** (P169 with "this is task-shaped" callout). Defers the structural fix.

None of these workarounds compose well with WSJF prioritisation when the project grows. /wr-itil:work-problems iter loops select by WSJF; if Phase 2 is a sub-work-item, it should compete for WSJF attention as a first-class entity, not hide inside a parent ticket's body.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — primary: project maintainer (cost of structural drift); secondary: every adopter trying to consume the Windy Road problem-management framework as a model (adopters inherit the same scaling pain).
- **Frequency**: (deferred to investigation) — likely Possible to Likely; surfaced N=4 times in current session (P168 / P159 / P051 / P169) and ramping with project complexity.
- **Severity**: (deferred to investigation) — likely Moderate; not blocking ship, but compounding toil.
- **Analytics**: (deferred to investigation) — tickets in `docs/problems/` with multi-phase Fix Strategy sections OR explicit "Phase N" language; ratio of sibling-ticket-trees to standalone tickets.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Architect review: design the RFC framework — directory structure (`docs/rfcs/` vs `docs/problems/<P>/rfcs/`?), filename + lifecycle status conventions, schema (problem-trace + ADR-trace + scope + stories + acceptance + closure-evidence), composition with existing problem-management skills, AskUserQuestion shape for /wr-itil:capture-rfc + /wr-itil:manage-rfc.
- [ ] Architect review: define story-mapping shape — backbone/ribs/slices template, INVEST checks, JTBD trace, story-to-RFC trace, story status lifecycle, WSJF placement (RFC-level WSJF vs story-level WSJF).
- [ ] Architect review: codify "all RFCs trace to a problem" invariant — gate enforcement (manage-rfc Step N hard-block on missing problem-trace? capture-rfc require --problem flag? linter pass over docs/rfcs/?); reverse trace (problem ticket gains RFC list section auto-maintained per P094-style refresh contract).
- [ ] Architect review: design technical-vs-user/business problem unification — type field on problem ticket frontmatter? sub-directory split with shared lifecycle? JTBD-job-statements as a problem-class? Worked example: convert one JTBD-101 to a problem ticket and check whether the WSJF-rank-against-bugs makes sense.
- [ ] JTBD review: which persona jobs are served (likely JTBD-001 enforce-governance + JTBD-008 evolve-framework + JTBD-101 plugin-developer for adopters consuming the model). New JTBD: "decompose-fix-into-coordinated-changes" persona-job-to-be-done?
- [ ] ADR for the RFC framework introduction: codify the decision; considered alternatives (no-RFC unified problem framework / sub-directory split per phase / type-field-only / parallel ITIL-CAB framework lifted whole / RFC at infrastructure-as-code level only); Decision Drivers (this ticket P170 + JTBD-101 plugin-developer + ADR-014 commit grain + ADR-052 behavioural tests + ADR-051 load-bearing-from-the-start + future JTBD unification); Confirmation criteria; Out-of-scope.
- [ ] Decide: lifecycle states for an RFC — `proposed` / `accepted` / `in-progress` / `verifying` / `closed`? mirror problem-ticket states or sibling? naming convention `R<NNN>-<slug>.<state>.md` (clashes with `docs/risks/R<NNN>` shape — pick different prefix? `RFC<NNN>` or `C<NNN>` for change?).
- [ ] Decide: RFC vs ADR boundary — ADR is "how we decided to solve it" (immutable record of decision-with-alternatives); RFC is "what we're shipping to solve it" (mutable execution surface that closes when shipped). One RFC may reference multiple ADRs; one ADR may underpin multiple RFCs across multiple problems. Worked examples needed.
- [ ] Decide: WSJF at RFC vs story level — does WSJF live on the RFC (one ranking) or on each story (granular ranking)? Granular is more accurate but increases ranking maintenance cost; coarse is cheaper but loses scheduling fidelity.
- [ ] Decide: backwards-compat path — existing P168/P159/P051 tickets retroactively split into Problem + RFC + Stories, OR grandfathered as-is and the RFC framework only applies to new work? Migration cost vs framework consistency cost.
- [ ] Decide: JTBD unification roadmap — Phase 1 ship RFC framework with type-tag for tech-vs-user; Phase 2 introduce JTBD-job-statement-as-problem-ticket; Phase 3 unify the directory layouts; Phase 4 retire the parallel `docs/jtbd/` hierarchy if redundant. Or different sequencing.
- [ ] Phase 1 implementation (held changeset per ADR-042 dogfood-window): scaffold `docs/rfcs/` + `/wr-itil:capture-rfc` skill + `/wr-itil:manage-rfc` skill + ADR + initial migration of P168 retroactively to test the shape on a known multi-commit decomposition.
- [ ] Phase 2 implementation: story-mapping templates + skill (`/wr-itil:capture-story` or `/wr-itil:map-stories <RFC>`); JTBD trace gate on stories; WSJF refresh integration.
- [ ] Phase 3 implementation: technical-vs-user/business problem unification — type-field on problem frontmatter; AskUserQuestion in capture-problem to select type; review-problems WSJF treats both classes uniformly.
- [ ] Phase 4 implementation: JTBD-as-problem unification — write the migration scripts; deprecate old `docs/jtbd/` if appropriate.
- [ ] Dogfood pass per phase: convert existing live tickets through the new framework; verify lifecycle transitions; check WSJF behaviour; confirm capture-problem + capture-rfc + capture-story compose without redundant ceremony.
- [ ] Stress-test: pick a recent multi-phase ticket (P168) and a recent feature-shaped ticket (P162 dogfood-graduation criteria) and a recent observation-only ticket (P161 advisory-then-escalate observation) — run each through the new shape end-to-end; check whether the framework distinguishes these correctly without forcing artificial scaffolding.

## Dependencies

- **Blocks**: (none directly — but the longer this is deferred, the more retroactive migration cost accumulates as P168/P159/P051/P169-style multi-phase tickets pile up)
- **Blocked by**: (none — the design space is well-scoped and the user direction is clear)
- **Composes with**: P014 (ADR-032 governance-skill-aside-invocation; capture-rfc / manage-rfc would be siblings to capture-problem / manage-problem under that pattern), P051 (improve shapes — many of those would naturally become RFCs), P078 (capture-on-correction; corrections may surface RFC-shaped work, not just problem-shaped), P033 (persistent risk register — RFC framework should compose with risk-scoring at the RFC level, not just commit/push/release), P162 (dogfood-graduation criteria — RFCs are exactly the surface that should ride held-changeset dogfood windows), P169 (this ticket's first concrete victim — once RFC framework lands, P169 retroactively becomes an RFC traced to P168 + this ticket).

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- ADR-014 (commit grain — RFCs decompose into ADR-014-grain commits)
- ADR-032 (governance-skill aside-invocation pattern — capture-rfc + manage-rfc would follow the same shape)
- ADR-042 (held-area + auto-apply — RFCs ride held-changeset windows naturally)
- ADR-051 (load-bearing-from-the-start — applies to RFC-introducing controls themselves)
- ADR-052 (behavioural tests — RFC stories carry behavioural acceptance)
- ADR-059 (consume-catalog + bootstrap-from-reports — first multi-commit ADR landed under the strain pattern this ticket addresses)
- JTBD-001 (enforce-governance), JTBD-008 (evolve-framework), JTBD-101 (plugin-developer)
- P168 / P169 (substantive design + operationalisation pair — first explicit Problem→workstream-decomposition example session-surfaced)
- P159 (Phase 1 shipped, Phase 2-3 deferred — second-most-pressing example of the pattern)
- P051 (6 improve shapes — third-most-pressing example)
- User direction recorded 2026-05-04: *"Capture the actual problem as P170. The ADR captures how we decide to solve it (and considered alternatives). All RFCs MUST be tied to a problem. We go beyond ITIL in this way. We consider technical problems and inherent user/business problems in the same way. In fact, even JTBD describes problems that we somehow (in the future) need to unify with the problem management framework."*
- Jeff Patton, *User Story Mapping* (O'Reilly, 2014) — backbone/ribs/slices canonical reference
- ITIL 4 Foundation: Change Enablement practice (RFC lifecycle), Service Request Management practice (request shape), Problem Management practice (root-cause shape) — informs but does not constrain (we extend per user direction)
