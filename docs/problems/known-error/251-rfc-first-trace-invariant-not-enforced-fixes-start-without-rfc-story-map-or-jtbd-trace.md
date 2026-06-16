# Problem 251: RFC-first trace invariant not enforced — fixes start without RFC, story map, or JTBD trace

**Status**: Known Error
**Reported**: 2026-05-17
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-008
**Persona**: solo-developer
**RFCs**: RFC-005 (accepted — the fix vehicle)

## Reconcile (AFK work-problems iter 21, 2026-06-16) — Open → Known Error

Root cause **confirmed** and core fix mechanism **released**, so this ticket advances Open → Known Error per ADR-022 (root cause + workaround documented + fix in progress).

- **Root cause confirmed**: the asymmetry in ADR-060's I-series. I1 enforced the RFC→Problem trace at *capture* time; the inverse Problem→RFC trace at *fix* time was never added. That gap was closed by the **I13 invariant** (ADR-060, added under RFC-006 slice 4, corrected under P314) — RFC required at the propose-fix step on a Known Error.
- **Core gate released**: P314 iter 11 / RFC-005 **B3/B4/B5** shipped in `@windyroad/itil@0.50.0`:
  - **B3** — `packages/itil/scripts/check-fix-rfc-trace.sh` (+ `bin/wr-itil-check-fix-rfc-trace` ADR-049 shim): deterministic predicate scanning `docs/rfcs/` for any RFC whose `problems:` array claims the PID; emits a `no-rfc-trace: P<NNN>` auto-create directive when none does; **exits 0 unconditionally — never blocks** (ADR-073 auto-create-not-block).
  - **B4** — `/wr-itil:manage-problem` Known-Error fix traversal runs the predicate as an I13 propose-fix gate preamble (auto-create via `/wr-itil:capture-rfc`, no consent gate per P132).
  - **B5** — `/wr-itil:work-problems` covers the AFK surface transitively (fix dispatched *through* manage-problem) + structured-logs the auto-create event.
- **Carve-out repudiated**: ADR-071 made RFC-first **unconditional** (no effort threshold, no override hatch — the original F2 atomic-fix carve-out is removed, not relocated). ADR-071/072/073 are user-ratified (P314 oversight drain), so no born-proposed decision blocks this transition (ADR-074 clear).
- **Why Known Error and not Verifying**: the full fix is not yet released. RFC-005 remaining slices: **B2** (problem-ticket `rfcs: []` frontmatter schema + template/capture-problem/manage-problem population), **B6** (auto-create-fires SKILL-orchestration bats — partial; harness-gap honestly recorded), **B7** (migration survey), **B8** (forward dogfood), **B9** (retro reassessment-criterion wiring), **B10** (held-changeset graduation). Full closure rides RFC-005 completion — tracked there, not lost (P184 conditional-deferral discipline). These slices are RFC-005-scoped and are best worked when RFC-005 is the iter target; not pulled into this P251 reconcile iter (B8/B10 are release-gated under AFK).

## Description

We have a RFC process and fixes for each problem MUST be captured through a RFC (instead of as task list), PRIOR to the work on fixing it commencing, but I'm not seeing that happening. Instead problems have task lists and no RFC and most importantly, no user story mapping or tracing to JTBD.

JTBD-008 names "Trace invariant — every RFC traces back to a problem (no orphan RFCs). The trace is gate-enforced at capture time, not advisory" as a desired outcome. The current framework enforces RFC→Problem trace at RFC capture time per ADR-060 I1 invariant. But the inverse direction — Problem→RFC trace at fix-time — is NOT enforced. Agents (and AFK orchestrator iters) routinely start fix work on a problem ticket using a task-list inline in the ticket body (`## Root Cause Analysis` / `### Investigation Tasks` / `### Fix Strategy`) without first authoring an RFC, without a story map, and without a JTBD trace on the underlying problem.

JTBD-008 § Desired Outcomes also names "The decomposition decision happens at capture time, not as drift mid-flight." The current behaviour treats decomposition as drift — task lists accrete in the problem body as fix work uncovers scope, rather than the agent stopping to scope an RFC + story map + JTBD trace before commencing.

## Symptoms

(deferred to investigation)

Initial observations:

- Most `Open` and `Known Error` tickets in `docs/problems/` carry `## Root Cause Analysis` → `### Investigation Tasks` and `## Fix Strategy` sections with checkbox task lists, NOT an RFC reference in the `## Dependencies` or `## Related` section.
- `/wr-itil:work-problems` orchestrator iter prompts dispatch the iter against the highest-WSJF problem ticket directly via `/wr-itil:manage-problem`, with no step that checks "does this problem have an associated RFC?" before commencing fix work.
- `/wr-itil:manage-problem` SKILL.md does not gate Step 7 (transition Open → Known Error → Fix Released) on the presence of a linked RFC + story map + JTBD trace.
- The problem-ticket template (per `/wr-itil:capture-problem` + `/wr-itil:manage-problem`) has no `**RFC**:` frontmatter field on problems classified `type: user-business` — even though ADR-060 Phase 4 made JTBD trace required on user-business problems, the RFC trace was not made symmetric.
- Recent fix-shipped tickets (search the `closed/` and `verifying/` subdirectories) show fix commits landing without an `RFC-<NNN>` cross-reference in either commit message or ticket body — confirming the gap is observable, not theoretical.

## Workaround

(deferred to investigation)

Possible interim workarounds (to validate):

- Author RFC-first for any multi-slice problem (Effort ≥ L); accept atomic-fix problems (Effort ≤ M) commencing without RFC ceremony per JTBD-008 § Persona Constraints "Atomic-fix shapes pay no ceremony".
- Manual cross-check during `/wr-itil:review-problems` Step 4a / 4b to flag tickets that have started fix work without RFC trace.

## Impact Assessment

- **Who is affected**: solo-developer persona (primary anchor of JTBD-008), tech-lead persona (secondary). AFK orchestrator iters most acutely — they cannot pause to author an RFC; they default to the task-list-inline shape.
- **Frequency**: high — observable across most Open / Known Error / fix-shipped tickets.
- **Severity**: (deferred to investigation) — degrades JTBD-008 outcomes but does not break atomic shipping; ranking-and-prioritization decisions decouple from user-anchored sequencing because the JTBD trace and story-map sequencing are missing.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — **confirmed (iter 21)**: candidate (4) is the root cause — ADR-060 shipped the RFC→Problem direction (I1) without the symmetric Problem→RFC-at-fix-time direction. Closed by I13 (ADR-060, RFC-006 slice 4 / P314). Candidates (1)/(2) are the surfaces the gate now fires at (manage-problem propose-fix + work-problems dispatch, RFC-005 B4/B5). Candidate (3) ticket-body-task-list shape is addressed by RFC-005 B2 (pending).
- [x] Identify which lifecycle transition should require the RFC trace — **decided (ADR-072, P314)**: the **propose-fix step on a Known Error**, NOT `Open → Known Error` and NOT a new state. Conforms to ADR-022 Known Error semantics.
- [x] Identify the atomic-fix carve-out shape — **decided (ADR-071, P314)**: **no carve-out**. RFC-first is unconditional; no effort threshold, no override hatch. The original F2 / JTBD-101 carve-out is removed.
- [ ] Survey current Open / Known Error tickets — how many would need retroactive RFC authoring? **= RFC-005 B7 (migration survey, pending).**
- [ ] Create reproduction test — predicate behaviour covered by `packages/itil/scripts/test/check-fix-rfc-trace.bats` (RFC-005 B6 done); auto-create-fires SKILL-orchestration assertion is the documented harness-gap (RFC-005 B6 partial / B8 dogfood).

## Dependencies

- **Blocks**: (none — observation ticket; fix design TBD)
- **Blocked by**: (none)
- **Composes with**: [[P170]] (RFC framework parent), [[P196]] (agent reports RFC-document completion as fix-shipped — premature-completion class), [[P189]] (agent invents deferred framing — different surface of "skip the contract" class-of-behaviour)

## Related

- **JTBD-008** (`docs/jtbd/solo-developer/JTBD-008-decompose-fix-into-coordinated-changes.proposed.md`) — Desired Outcomes "Trace invariant" + "Capture-time scoping" both speak directly to this problem. This ticket is the load-bearing symptom that JTBD-008 outcomes are not being delivered at the fix-time surface.
- **ADR-060** (`docs/decisions/060-...accepted.md`) — Phase 3 + Phase 4 in-scope amendment 2026-05-13 shipped I1 (RFC→Problem trace at capture), I6 (Story→Problem trace at capture), I9 (Story→JTBD trace at capture), I12 (JTBD trace required on user-business problems). The symmetric Problem→RFC trace at fix-time is NOT in the I-series — this ticket names that gap.
- **P170** (`docs/problems/known-error/170-problem-tickets-strain-as-fixes-decompose-into-multiple-coordinated-changes-need-rfc-framework.md`) — parent / RFC framework driver. P170 Phase 2 shipped the framework; this ticket reports a Phase 3 / Phase 4 enforcement gap.
- **P196** (`docs/problems/open/196-agent-reports-rfc-document-completion-as-fix-shipped-premature-completion-on-multi-slice-rfcs.md`) — sibling; agents complete RFC docs without shipping the slices. This ticket is the inverse — agents skip the RFC entirely.
- **P189** (`docs/problems/open/189-...md`) — sibling; agent invents "deferred" framing on tracked phases without user direction. Same class-of-behaviour at a different SKILL surface (`/wr-itil:work-problems` / `/wr-itil:manage-problem` vs ADR-060 phase tracking).
- (captured via /wr-itil:capture-problem; expand at next investigation)

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-005 | accepted | RFC-first trace invariant not enforced at fix-time |
| RFC-006 | verifying | Implement ADR-070 + ADR-071 — re-home RFC decisions to ADRs and make RFC-first unconditional |
