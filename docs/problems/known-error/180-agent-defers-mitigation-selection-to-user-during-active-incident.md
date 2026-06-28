# Problem 180: Agent defers mitigation selection to user during active incident — surfaces mitigation choice as user-authority when SKILL contract empowers agent-driven reversible mitigations

**Status**: Known Error
**Reported**: 2026-05-10
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)

## Description

During the I002 incident-management session (2026-05-10), the agent ended Step 14 reporting with the literal phrasing:

> *"I'll wait for your direction on which mitigation to attempt."*

That phrasing surfaced **mitigation selection** as user-authority territory at a stage where the `/wr-itil:manage-incident` SKILL contract has already framework-resolved the decision: the agent owns mitigation selection within the reversibility-preference + cited-evidence + within-appetite envelope. The user corrected verbatim:

> *"mitigations don't belong to me. You are empowered."*

JTBD-201 (Restore Service Fast with an Audit Trail) names "reversible mitigations are preferred" as a desired outcome — so the SKILL's empowerment of agent-driven mitigation is **documented**, not implicit. The deferral re-asked a decision JTBD-201 had already mediated, adding latency to the very job the SKILL exists to accelerate.

This is a **class-of-behaviour pattern**, sibling-but-distinct from existing tickets:

- **`feedback_dont_defer_at_session_wrap.md`** (memory) — covers session-wrap deferral ("session-side recommendations" framing). P180 is mid-flow during active incident, not session-wrap.
- **P132** (`Agents over-ask in interactive sessions — conflating mechanical-stages with user-interactive-stages`) — covers the inverse-P078 trap where defensive over-asking from upstream corrections re-introduces friction in mechanical stages. P180 is a fresh manifestation of the P132 class on the *mitigation-selection* surface specifically — distinct framework-resolution-boundary location, same root cause family.
- **P078 family** (`Assistant does not offer problem ticket on user correction`) — capture-on-correction OFFER pattern. P180 is the captured-on-correction observation; P078 is the meta-process that produced this ticket.
- **P179** (`Agent defers requested work into untracked phases — phases are fine, but unticketed phases never get implemented`) — sibling deferral pattern around requested-work phases. P180 is the deferral-pattern-mirror at the mitigation-selection surface.

Distinct surface: **mitigation-choice-during-active-incident**, not session-wrap, not declaration-fields, not requested-work-phases.

### Verbatim evidence

- Agent closing report on I002 commit `ef61039`, final paragraph: `"I'll wait for your direction on which mitigation to attempt."`
- User correction immediately following: `"mitigations don't belong to me. You are empowered"`
- Suggested-next-moves block in the same closing report enumerated three options (re-run I001 mitigation H3 / address P162 deeper defect / hybrid) and ended with the deferral phrase above — i.e., the agent prepared the analysis but stopped short of acting on the obvious mitigation.

### Architectural context

- ADR-044 (Decision-Delegation Contract) is the framework-resolution-boundary artefact. Mitigation selection within reversibility-preference + cited-evidence is a category-4 (silent-framework) surface, NOT category-1 (direction-setting). The deferral mis-classified it as category-1.
- ADR-011 (manage-incident SKILL) Step 7 + Step 8 explicitly delegate mitigation execution to `/wr-itil:mitigate-incident`. The skill contract treats mitigation as agent-action, not user-decision.
- ADR-013 Rule 5 (policy-authorised silent proceed) — within-appetite reversible mitigations are policy-authorised; no `AskUserQuestion` is required.
- JTBD-201 desired outcome wording ("Reversible mitigations [...] are preferred") makes the empowerment explicit per documented persona-job.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### RCA reconciliation finding (2026-06-16, AFK work-problems iter 23)

Root cause confirmed and the deferral reconciled against the closed P132 class. **Open → Known Error**: root cause identified, declarative-layer permanent fix committed, structural-enforcement layer deferred per anti-BUFD (recurrence-gated), this ticket is the scheduled-future-surface for that enforcement.

**1. P180 is a fresh manifestation of the closed P132 inverse-P078 over-ask class — on the mitigation-selection surface specifically.** P132 (`docs/problems/closed/132-...md`) closed with a three-layer fix: (a) CLAUDE.md MANDATORY rule *"when a SKILL contract names a stage as mechanical, do not ask"*; (b) per-skill derive-first dispatch on the **declaration-field** surfaces (Step 4 of manage-incident / manage-problem, Step 1.5 capture-problem, Step 2 create-adr); (c) a structural Stop hook (`itil-mid-loop-ask-detect.sh`) for the **orchestrator-main-turn-between-iters** surface. **None of those three layers cover the mitigation-selection surface** — Step 4 is declaration-field backfill, the Stop hook is orchestrator-main-turn-scoped, and the CLAUDE.md rule binds only to SKILL contracts that *explicitly name a stage as mechanical*. The `mitigate-incident` / `manage-incident` "Reversible preference" ladder IS the framework resolution for *which* mitigation, but it was framed as a "preference", not labelled as an ADR-044 no-ask carve-out — so the CLAUDE.md P132 rule had nothing to bind to and the I002 agent mis-classified selection as category-1 (direction-setting).

**2. The substance is directly user-confirmed — NOT a born-proposed unmade decision (ADR-074 clear).** Unlike P179's residual (where the enforcement-FORM decision — hard-test vs cultural — is genuinely user-judgment-bound and queued), P180's substance question ("is mitigation-selection agent-owned or user-authority?") was resolved verbatim by the user at capture time: *"mitigations don't belong to me. You are empowered."* (2026-05-10). Plus ADR-011 (reversible-preference ladder + evidence-first rule), JTBD-201 ("reversible mitigations are preferred"), ADR-013 Rule 5 (policy-authorised silent proceed), and ADR-044 (confirmed 2026-05-25). Queue+skip would itself be a P180 recurrence — deferring an agent-owned, user-confirmed action. So the fix was implemented this iter.

**3. Declarative-layer fix committed (this iter).** Added an explicit *"Mitigation SELECTION is agent-owned"* ADR-044 framework-mediated / category-4-silent-framework-family annotation to both the `mitigate-incident` "Reversible preference" section and the `manage-incident` "Mitigation preference" section, plus matching ADR-044-surface entries in both SKILLs' References. The annotation bans both `AskUserQuestion` AND the prose-ask deferral ("I'll wait for your direction on which mitigation to attempt") for mitigation selection, while explicitly preserving the genuine user-authority surfaces (evidence-gate bypass cat-2, risk-above-appetite commit cat-3). This is the exact declarative-first shape P132 Phase 2c shipped. Architect verdict PASS (no new ADR — ADR-044/011/013 authorise; ADR-051 is superseded and does not govern enforcement sequencing; ADR-077 compendium-refresh N/A for SKILL-only edits). JTBD verdict PASS (JTBD-201 primary; tech-lead persona auditability + lightweight-workflow constraints both served; build-upon guard clean — JTBD-201 + tech-lead persona both `human-oversight: confirmed`). All 38 manage-incident-adr-044-contract + mitigate-incident-contract bats green (edits additive).

**4. Structural-enforcement layer DEFERRED per anti-BUFD (recurrence-gated; this ticket is the scheduled-future-surface).** The I002 over-ask was a *prose-ask* in an *interactive* incident session — the existing P085 prose-ask Stop detector (`itil-assistant-output-review.sh`) is the natural enforcement extension target. Per the P132 Phase 2b precedent (declarative-first; build the hook only when the R6 numeric gate / observed recurrence fires), extending that detector to flag mitigation-selection prose-asks is held until recurrence is observed. Not built speculatively. The recurrence trigger: any future incident session where the agent again defers "which mitigation" → re-select P180 at orchestrator WSJF and ship the P085-detector extension.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause (2026-06-16 RCA): confirmed fresh P132-class manifestation on the mitigation-selection surface; the "Reversible preference" ladder was un-annotated as a no-ask carve-out, so the closed P132 layers did not bind. See RCA reconciliation finding above.
- [x] Create reproduction test — N/A as a behavioural test: mitigation selection is pure agent-judgment guided by SKILL prose (no executable helper, unlike P132's derive-first-dispatch.sh), so a SKILL-content grep would be a structural test (rejected per P081 / `feedback_behavioural_tests.md`). The fix is declarative-layer (CLAUDE.md P132 rule + SKILL contract annotation); enforcement-behaviour testing belongs with the deferred P085-detector extension (Task below). Verified the declarative annotation does not break the 38 existing ADR-044 / contract bats assertions.
- [x] Sibling-tree audit (2026-06-16): `/wr-itil:mitigate-incident` "Reversible preference" + `/wr-itil:manage-incident` "Mitigation preference" both annotated this iter. `/wr-itil:restore-incident` + `/wr-itil:close-incident` are lifecycle-transition forwarders with no mitigation-selection surface (out of scope). `/wr-itil:work-problem` selection + ADR-042 auto-apply are already covered by their own framework-mediation (WSJF + ADR-042 auto-apply loop; explicitly no-AskUserQuestion per existing SKILL text).
- [ ] **DEFERRED (anti-BUFD, recurrence-gated): extend the P085 prose-ask Stop detector (`itil-assistant-output-review.sh`) to flag mitigation-selection prose-asks** during interactive incident sessions. Build only on observed recurrence per the P132 Phase 2b precedent. This ticket is the scheduled-future-surface (P179 carve-out): re-select at orchestrator WSJF if the deferral recurs.

## Dependencies

- **Blocks**: (none direct)
- **Blocked by**: I002 (this ticket itself was captured via the bypass-the-broken-halt-and-route path because `/wr-itil:capture-problem` Step 0 hit a stale-cache phantom-drift halt — the cache is stale because RFC-002 T4 dual-tolerant reconcile script is held in `docs/changesets-holding/` and never reached npm; I002 mitigation will let the cache refresh and unblock the canonical capture path)
- **Composes with**: P078 (capture-on-correction), P132 (over-ask in interactive sessions), P179 (defers requested work into untracked phases), ADR-044 (framework-resolution boundary)

## Related

- **I002** (`docs/incidents/I002-release-pressure-and-wip-limit-controls-not-firing.investigating.md`) — the active incident in which this pattern was observed; commit `ef61039` carries the verbatim Step 14 closing report.
- **ADR-011** — manage-incident SKILL contract empowers agent-driven mitigation execution.
- **ADR-013 Rule 5** — policy-authorised silent proceed for within-appetite reversible mitigations.
- **ADR-032** — capture-problem Step 4 deferred-placeholder template (this ticket's shape).
- **ADR-044** — Decision-Delegation Contract (framework-resolution boundary).
- **P078** — capture-on-correction OFFER pattern (the meta-process that produced this ticket).
- **P132** — Agents over-ask in interactive sessions — the parent class of behaviour; P180 is a fresh manifestation on the mitigation-selection surface.
- **P179** — sibling deferral pattern (untracked phases for requested work).
- **JTBD-201** — Restore Service Fast with an Audit Trail; "reversible mitigations are preferred" desired outcome wording is the load-bearing JTBD evidence that SKILL empowerment is documented.
- `feedback_dont_defer_at_session_wrap.md` (user-memory feedback) — sibling pattern at session-wrap surface; this ticket extends the family to mid-flow active-incident surface.
