# Problem 135: Decision-delegation contract — agents over-apply ADR-013 Rule 1's interactive default to framework-resolved decisions; codify the framework-resolution boundary + AFK loop's batched-questions-as-deliverable + lazy-AskUserQuestion measurement

**Status**: Known Error
**Reported**: 2026-04-27
**Priority**: 12 (High) — Impact: Significant (4) x Likelihood: Likely (3)
**Effort**: M — bounded multi-phase plan at `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md` (5 phases, total ~16 hrs of which Phase 1+5+2+3 declarative = ~12 hrs are must-do; Phase 4 enforcement gated). M (not L) because each phase is bounded + per-phase release cadence drains risk to one phase's surface at a time per ADR-042 precedent.
**WSJF**: (12 × 1.0) / 2 = **6.0** — High severity (per-session lazy-AskUserQuestion friction is the dominant cost the framework was designed to remove; without P135, every interactive AFK-correction-rich session compounds the friction).

> Master ticket for landing the **decision-delegation contract** as architectural direction. Captures the principle, the 5-phase plan, the per-phase release cadence, the measurement surface, and the cross-references to all child tickets (P130 / P131 / P132 / P133 / P134) + the new ADR (ADR-044). Surfaced 2026-04-27 by 5 user corrections in a single session that collectively revealed agents are sub-contracting framework-resolved decisions back to the user via redundant `AskUserQuestion` consent gates. The user articulated the underlying principle in a long session-end conversation: *"the framework IS a decision-delegation contract"*.

## Description

The windyroad-claude-plugin project ships a substantial governance framework (44 ADRs including the new ADR-044, JTBDs by persona, RISK-POLICY, voice-and-tone, WSJF, lifecycle, SKILL contracts). This is **codification of decisions the user has already made**. Agents are meant to consume the codification and apply it; per-action `AskUserQuestion` calls reverse the user's investment by re-asking decisions the user already made.

Observed (2026-04-27 session): 5 user corrections in one session — each surfaced a different facet of the over-asking pattern:

1. **Subprocess dispatch in iter 9** (P130) — agent dispatched a subprocess when the user was observably interactive at the orchestrator's main turn.
2. **Grep approach for P081 implementation** (P078 trigger) — agent built a syntactic-pattern hook when the SKILL contract obviously needed an LLM-judgment agent.
3. **`.claude/` user-space writes** (P131) — agent treated gate-exclusion-as-write-permission and wrote project-generated artefacts into the user's config space.
4. **Retro cascade scope** (P132) — `run-retro` Step 4/4a's "delegates to manage-problem" was implemented as inline cascade of skill invocations; user direction *"Run the retro in the retro itself"* corrected.
5. **"Removals shouldn't be an ask"** (folded into P132) + **"What is topic file rotation?"** (folded into P132) — `run-retro` Step 3's per-removal `AskUserQuestion` and per-file Tier 3 rotation `AskUserQuestion` are over-asks.

A long session-end conversation crystallised the principle: human input is reserved for SIX categories (direction-setting / **deviation-approval** / one-time-override / silent-framework / taste / authentic-correction); everything else is framework-mediated and the agent acts and reports.

A second principle emerged: **anti-BUFD applies to framework evolution too**. Existing decisions are point-in-time; as reality changes, existing decisions may become wrong. The agent surfaces deviation candidates with evidence; user approves amend/supersession; never auto-deviate; never blindly follow against evidence. The framework grows incrementally based on actual need not speculation.

P135 is the master ticket capturing the principle + the implementation plan + the cross-references to all child tickets surfaced this session.

## Symptoms

- 2026-04-27 session: ~5-6 lazy `AskUserQuestion` calls per session (baseline) — the user-named friction surface.
- Friction compounds: more user corrections → agent's defensive habit → more asks → user surfaces the asks-as-friction → more corrections.
- Framework's investment is silently undone every interactive session; the user keeps re-deciding decisions they already made.
- Mid-loop AFK iter dispatched subprocess immediately after user answered an `AskUserQuestion` next-step decision — the dispatch shape didn't adapt to the presence-flip (P130 captures the specific surface).
- AFK iter killed when user corrected the dispatch — overcorrection wasted ~$5 + 25 min in-flight work. The handler should have let the iter complete + queued the new direction (P135's Phase 3 captures the right shape).

## Workaround

User explicitly notices and corrects the friction (this session). Pattern repeats every session unless the principle is codified.

## Impact Assessment

- **Who is affected**: every user of every windyroad SKILL with mechanical-vs-interactive stage splits. Solo-developer (JTBD-001) primarily; AFK-orchestration (JTBD-006) compounds because per-iter-redundant-asks multiply across iters; plugin-developer (JTBD-101) inherits via published packages.
- **Frequency**: every interactive session. Once the agent's defensive habit kicks in (any session with 2+ user corrections), it persists unbroken until session end.
- **Severity**: Significant — degrades user experience exactly when the user is most engaged. The mechanical-stage no-ask design is a load-bearing UX investment in the framework that defensive over-asking silently undoes.
- **Likelihood**: Likely — natural agent inference from corrections is "ask first". Without counter-pressure (declarative ADR + measurement + optionally enforcement hook), every corrective session is a candidate.
- **Analytics**: 2026-04-27 baseline ~5-6 lazy calls per session; user surfaced the friction directly. Cumulative session cost ~$70 / ~6 hrs included redundant turns spent on consent-gates the framework had already settled.

## Root Cause Analysis

### Investigation Tasks

- [x] Audit the framework for codified decisions agents over-ask about. Done in the long session-end conversation; result: the principle is "the framework IS a decision-delegation contract" with the 6-class authority taxonomy as the framework-resolution boundary.
- [x] Decide ADR shape: amend ADR-013 Rule 1 in place + sibling ADR-044 (chosen) vs supersede ADR-013 entirely (rejected — ADR-013 Rules 2-6 cited from many places). Architect Q3 verdict from earlier session: sibling+narrow.
- [x] Decide enforcement aggressiveness: warning-only Phase 4 hook (chosen) vs block (rejected — too rigid during transition; matches P132 design + ADR-040 Tier 3 advisory precedent).
- [x] Decide measurement granularity: per-session lazy count (chosen — cheapest baseline; mirrors `check-briefing-budgets.sh` advisory pattern) vs per-skill (deferred — refine if Phase 5 baseline shows skill-specific concentration).
- [x] Decide outstanding-questions storage shape: jsonl at `.afk-run-state/outstanding-questions.jsonl` (chosen — parser-friendly across iter subprocesses per ADR-026 grounding precedent) vs markdown (rejected — adds parser complexity).
- [x] Confirm CLAUDE.md addition is wrong-surface (user direction 2026-04-27) — this is a plugin-publishing project; project CLAUDE.md only affects this session, not adopters. Decision-delegation contract lives in the ADR + propagates through Phase 2 SKILL.md edits (which DO ship to adopters).
- [x] Add deviation-approval as first-class human-value category (user direction 2026-04-27) — existing decisions are point-in-time; agent surfaces deviation candidates with evidence; user approves amend/supersede; never auto-deviate.
- [x] Risk-score the plan with Plan agent: PASS at 2/4/4 within appetite after R1-R8 remediations applied.
- [x] Architect + JTBD review of Phase 1 scope: both PASS.

### Confirmed root cause

The pattern is **structural** in how an agent reasons about ADR-013 Rule 1's "interactive default = `AskUserQuestion`" guidance. Rule 1 is correct for genuine ambiguity, but agents over-generalise it to "if user is interactive, ask before deciding ANYTHING". The mechanical-stage carve-outs that explicit SKILL contracts add are designed to remove THAT friction; defensive over-asking silently re-introduces it. The fix is to (a) narrow Rule 1 with an explicit framework-resolution boundary (ADR-044 + ADR-013 amendment), (b) propagate the boundary through SKILL.md edits in `run-retro` / `work-problems` / `manage-problem` / `transition-problem`, (c) measure the regression metric (lazy-AskUserQuestion count) per-session so progress is visible, (d) optionally enforce via a PostToolUse hook if declarative is insufficient.

## Fix Strategy

**Implementation plan**: see `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md` (drafted 2026-04-27 by Plan agent; risk-scored PASS at 2/4/4 after R1-R8 remediations; user-approved 2026-04-27 via `/plan` workflow).

**5 phases** (sequenced for declarative-first + per-phase release cadence):

- **Phase 1 (Anchor, S ~2 hrs)**: NEW ADR-044 + AMEND ADR-013 Rule 1 + NEW P135 master ticket. Doc-only, no changeset, no release.
- **Phase 5 (Measurement, M ~3 hrs) — BEFORE Phase 2/3**: NEW `run-retro` Step 2d "Ask Hygiene Pass" + NEW `check-ask-hygiene.sh` advisory script + NEW behavioural bats. `@windyroad/retrospective` minor.
- **Phase 2 (Skill amendments, M ~4 hrs)**: per-skill removal of over-asks where framework resolves (`run-retro` Step 3 removals + Tier 3 rotation + Step 4a verification close + Step 4b Stage 2 fix-shape; `work-problems` Step 5 dispatch + Step 2.5 batch-as-default; `manage-problem` Step 9d; `transition-problem` Step 5 P063). Plus named bats for cross-plugin coupling (R3) + recovery paths (R5). `@windyroad/retrospective` minor + `@windyroad/itil` patch.
- **Phase 3 (AFK loop redesign, M ~3 hrs)**: `work-problems` ITERATION_SUMMARY contract gains deviation-candidate shape; between-iter aggregation persists to `.afk-run-state/outstanding-questions.jsonl`; loop-end emit becomes default deliverable; mid-loop UserPromptSubmit handler does NOT abort iter (R4); deviation-candidate shape covered by behavioural bats (R7). `@windyroad/itil` patch with **preview-tag rollout (R2)** — npm `preview` first, exercise end-to-end, only then promote to `latest` via dist-tag.
- **Phase 4 (Enforcement hook, M ~4 hrs) — GATED on Phase 1-3 declarative being insufficient (R6 numeric gate: lazy count ≥2 across 3 consecutive retros)**: NEW `itil-decision-delegation-detect.sh` PostToolUse hook with lazy-pattern matcher + behavioural bats covering false-positive resistance. `@windyroad/itil` minor.

**Per-phase release cadence (R1)** drains projected release risk to one phase's surface at a time. Phase 1 doc-only no release. Phase 5 ships its release before Phase 2 starts. Phase 2 ships before Phase 3. Phase 3 ships via preview-tag → end-to-end exercise → dist-tag promote. Phase 4 ships only if R6 gate fires.

**Confirmation criteria** (per ADR-044): 7 named bats files + measurable lazy-AskUserQuestion-count metric trending toward 0 across consecutive retros + explicit deviation-candidate behavioural assertion.

## Dependencies

- **Blocks**: every session's lazy-AskUserQuestion friction continues until P135 lands. P132 (Phase 4 enforcement hook is part of P135's plan) is structurally blocked-by P135 Phase 1-3.
- **Blocked by**: (none — Phase 1 can proceed standalone; subsequent phases sequenced per the plan)
- **Composes with**: P130 (orchestrator presence-aware dispatch — same family of agent-discipline gaps), P131 (.claude/ user-space writes — same family), P132 (inverse-P078 over-asks — P135 is the deeper principle, P132 is the enforcement implementation), P133 (zsh portability — adjacent surface from same correction-rich session), P134 (README line 3 accumulator bloat — adjacent surface), P078 (capture-on-correction — original anchor, ADR-044 category 6).

## Related

- **ADR-044** (`docs/decisions/044-decision-delegation-contract.proposed.md`) — the architectural anchor. Captures the 6-class authority taxonomy + framework-mediated surface enumeration + anti-BUFD-for-framework-evolution clause + Confirmation Criteria.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 amended in place by Phase 1 with forward pointer to ADR-044. Rules 2-6 untouched.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — commit-grain precedent. P135's per-phase work commits per ADR-014.
- **ADR-022** (`docs/decisions/022-problem-verification-pending.proposed.md`) — lifecycle-mechanical example.
- **ADR-026** (`docs/decisions/026-cost-source-grounding.proposed.md`) — grounding requirement; deviation-candidate shape uses ADR-026's tool-invocation + observable-outcome citation discipline.
- **ADR-032** (`docs/decisions/032-governance-skill-invocation-patterns.proposed.md`) — sub-pattern parent. AFK loop's deviation-candidate queue uses ADR-032's pending-questions artefact precedent.
- **ADR-040** (`docs/decisions/040-progressive-disclosure-tier-policy.proposed.md`) — declarative-first precedent. Phase 4 gating mirrors ADR-040 Tier 3 advisory-not-fail-closed.
- **ADR-042** (`docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — auto-apply precedent. Per-phase release cadence mirrors ADR-042 Rule 5 halt + bounded-vocabulary discipline.
- **ADR-043** (`docs/decisions/043-progressive-context-usage-measurement.proposed.md`) — measurement precedent. Phase 5 Step 2d "Ask Hygiene Pass" mirrors ADR-043's cheap-layer measurement shape.
- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction; the original pattern. P132 is its inverse; P135 is the deeper principle.
- **P130** (`docs/problems/130-...open.md`) — orchestrator presence-aware dispatch.
- **P131** (`docs/problems/131-...open.md`) — `.claude/` user-space writes.
- **P132** (`docs/problems/132-...open.md`) — inverse-P078 over-asks. P132's Phase 4 enforcement hook is the load-bearing implementation of ADR-044's framework-resolution boundary; P135 is the master coordinating ticket.
- **P133** (`docs/problems/133-...open.md`) — zsh portability gap.
- **P134** (`docs/problems/134-...open.md`) — README line 3 accumulator bloat.
- `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md` — the approved 5-phase implementation plan.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — primary persona served.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — primary persona served.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-the-suite-with-new-plugins.proposed.md`) — composes via Phase 2 SKILL.md edits that ship to adopters.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-audit-trail.proposed.md`) — composes via Step 2d lazy-count metric audit surface.
- 2026-04-27 session evidence: 5 user corrections in one session (P130/131/132 captured + 2 in-conversation observations folded into P132); long session-end conversation crystallised the principle; Plan agent drafted the 5-phase implementation plan; risk-scorer:plan PASS at 2/4/4 after R1-R8 remediations; architect + JTBD PASS on Phase 1 scope; user approved via `/plan` workflow.
- **Upstream report pending** — false positive; detection misfire (the `@windyroad/retrospective` and `@windyroad/itil` references are this project's own published packages — P135's Phase 2/3/5 fixes ship them, not external dependencies).

## Phase status (Known Error transition — 2026-04-28)

All declarative phases shipped to npm; Phase 4 enforcement is R6-gated.

- **Phase 1 (Anchor)** — landed `e703656`. ADR-044 proposed + ADR-013 Rule 1 amended + P135 master ticket opened. Doc-only, no release.
- **Phase 5 (Measurement)** — landed `5d414fc`. NEW `run-retro` Step 2d "Ask Hygiene Pass" + `packages/retrospective/scripts/check-ask-hygiene.sh` + `run-retro-step-2d-r6-auto-flag.bats` + `check-ask-hygiene.bats`. Released as `@windyroad/retrospective` minor. Reassessment Trigger automation (R6 auto-flag) landed `258ac25`.
- **Phase 2 (Skill amendments)** — landed `fae42aa`. `run-retro` Step 1.5 / Step 3 removals / Tier 3 rotation / Step 4a / Step 4b Stage 2; `work-problems` Step 5 dispatch + Step 2.5 batch-as-default; `manage-problem` Step 9d evidence-grounded close; `transition-problem` Step 5 P063 silent-default. Released as `@windyroad/retrospective` minor + `@windyroad/itil` patch.
- **Phase 3 (AFK loop redesign)** — landed `328f92a`. `work-problems` ITERATION_SUMMARY gains deviation-candidate shape; `.afk-run-state/outstanding-questions.jsonl` queue; mid-loop UserPromptSubmit handler does NOT abort iter; `work-problems-mid-loop-userpromptsubmit-handler.bats` + `work-problems-deviation-candidate-shape.bats`. Released as `@windyroad/itil` patch via preview-tag rollout.
- **Phase 4 (Enforcement hook)** — **R6-GATED**. Auto-flag wired in `run-retro` Step 2d; fires when lazy count ≥2 across 3 consecutive retros. Not started; gating is intentional per the plan (ADR-040 declarative-first precedent).

**Confirmation criteria status** (per ADR-044): 6 named bats files in place (`run-retro-step-2d-r6-auto-flag`, `run-retro-step-4a-recovery-path`, `check-ask-hygiene`, `manage-problem-step-9d-recovery-path`, `work-problems-mid-loop-userpromptsubmit-handler`, `work-problems-deviation-candidate-shape`) + measurable lazy-AskUserQuestion-count metric being tracked per retro + explicit deviation-candidate behavioural assertion in place.

**Verification path to Closed**: observe lazy-AskUserQuestion-count metric across consecutive retros via Step 2d's trail file. If the metric trends to 0 across 3+ retros, P135 transitions Known Error → Verification Pending → Closed (declarative was sufficient — Phase 4 not required). If R6 fires (lazy count ≥2 across 3 consecutive retros), Phase 4 enforcement hook ships and P135 transitions through verification on that release.

**Workaround during verification window**: `run-retro` Step 2d already surfaces lazy calls per retro; user reads the table and corrects via authentic-correction (ADR-044 category 6) if a specific call is misclassified.
