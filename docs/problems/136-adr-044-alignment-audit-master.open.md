# Problem 136: ADR-044 alignment audit — sweep all unaudited skills/hooks/agents/ADRs/JTBDs/READMEs against the framework-resolution boundary (master ticket)

**Status**: Open
**Reported**: 2026-04-27
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Possible (3) — friction is suite-wide but per-surface bounded
**Effort**: L — ~5+ sessions across 26 edit-bearing surfaces (3 high-ask SKILLs + 4-6 medium/low-ask SKILLs + 4 critical hooks + ~2 ADR amendments). Per-surface release cadence drains projected risk to one surface at a time per P135 R1.
**WSJF**: (9 × 1.0) / 4 = **2.25**

> Master ticket for the **ADR-044 alignment audit** — the user-directed follow-up to P135's completion. P135 amended 4 SKILLs in Phase 2; the remaining suite (31 SKILLs + 65 hooks + 10 agents + 37 unaudited ADRs + 16 JTBDs + 12 READMEs) needs systematic review against the framework-resolution boundary so CLAUDE.md and other files don't contradict ADR-044. Surfaced 2026-04-27 by user direction at P135 implementation completion: *"we should also do an audit of all the files (hooks, skills, agents, etc) to make sure they align with the clarified direction and make sure CLAUDE.md and other files don't contradict"*.

## Description

ADR-044 (Decision-Delegation Contract) codifies the framework-resolution boundary: framework-resolved decisions are mechanical (no `AskUserQuestion`); the user owns 6 categories (direction-setting / deviation-approval / one-time-override / silent-framework / taste / authentic-correction). Per-action `AskUserQuestion` calls in framework-resolved zones are "lazy deferral" per Step 2d Ask Hygiene Pass classification.

P135 Phase 2 amended 4 SKILLs (run-retro Step 3/4a/4b, work-problems Step 5/2.5, manage-problem Step 9d, transition-problem Step 5 P063). The plan deferred the rest of the suite to a follow-up audit (this ticket). The remaining suite scope (verified Phase 1 inventory):

- **35 SKILL.md total**; 4 audited; **31 remaining**:
  - High-ask candidates (5+ AskUserQuestion calls): `work-problem` singular (11), `mitigate-incident` (8), `manage-incident` (7).
  - Moderate-ask (3 calls): `review-jobs`, `analyze-context`.
  - Zero-ask (likely no work needed): c4/check, c4/generate, itil/list-incidents, itil/list-problems, itil/reconcile-readme.
  - Per-package: architect 2, c4 2, connect 2, itil 16 (14 unaudited), jtbd 2, retrospective 2 (1 audited), risk-scorer 5, style-guide 1, tdd 1, voice-tone 1, wardley 1.
- **69 hooks total**; critical ask-emitters (4): `itil-assistant-output-gate.sh`, `itil-assistant-output-review.sh`, `manage-problem-enforce-create.sh`, `voice-tone-eval.sh`. Other 65: PreToolUse gates (risk-scorer 18, architect 9, others 23), UserPromptSubmit (4), PostToolUse/Stop (scattered). Most are no-ask.
- **10 agents total**; only `risk-scorer/agents/pipeline.md` references ask-behaviour (1 mention); other 9 have no explicit ask-vs-act guidance.
- **43 ADRs total** (41 proposed, 2 superseded); ADR-013 amended in P135 Phase 1; likely composes-with: ADR-022, ADR-032, ADR-040, ADR-042; remaining ~37 to audit for contradictions.
- **16 JTBDs**; no explicit ask-mandate detected in spot checks.
- **12 READMEs** (project root + per-package); no contradictory directives in spot checks.
- **141 bats files, ~253 structural-grep test assertions**; P081 territory. P136 uses `tdd-review: structural-permitted` marker as bridge; P081 Phase 2 owns canonical retrofit.

## Symptoms

- Per-session lazy-AskUserQuestion-count (Step 2d metric) dominated by unaudited SKILLs (work-problem singular at 11 ask-calls is the prime candidate; mitigate-incident at 8; manage-incident at 7).
- Without audit, future P135-class corrections cycle: each user-corrected SKILL re-derives the framework-resolution boundary instead of applying ADR-044 once.
- CLAUDE.md / READMEs / JTBDs may carry direction that contradicts ADR-044 silently — no detection mechanism today.
- ADR-044 is project-wide but only 4 of 35 SKILLs codify it; the remaining 31 SKILLs are out-of-step.

## Workaround

Per-session Step 2d Ask Hygiene Pass surfaces the lazy count; user notices high lazy count tied to a specific SKILL; user invokes `/wr-itil:work-problem <NNN>` against P136 to chip away. Without the master ticket + per-surface findings, the audit is ad-hoc and forgets surfaces.

## Impact Assessment

- **Who is affected**: every user of every windyroad SKILL with un-aligned ADR-044 prose. Solo-developer (JTBD-001) primarily; AFK-orchestration (JTBD-006) compounds because per-iter-redundant-asks multiply across iters; plugin-developer (JTBD-101) inherits via published packages.
- **Frequency**: every interactive session. Once the agent's lazy-ask habit kicks in on an un-aligned SKILL, it persists unbroken until that SKILL is amended.
- **Severity**: Moderate — degrades user experience suite-wide; per-surface bounded.
- **Likelihood**: Possible — depends on which SKILLs the user invokes; `/wr-itil:work-problem` (singular, 11 asks) is high-volume.
- **Analytics**: 2026-04-27 baseline ~5-6 lazy calls per session post-P135-Phase-2; expected to drop measurably as Phase 2/3/4 of P136 land.

## Root Cause Analysis

### Confirmed root cause

P135 Phase 2 amended only the 4 SKILLs the implementer touched. ADR-044 is project-wide; alignment requires systematic per-surface audit. The remaining suite carries pre-ADR-044 prose that wasn't reconciled.

### Investigation Tasks

- [x] Phase 1 inventory completed: 35 SKILLs / 69 hooks / 10 agents / 43 ADRs / 16 JTBDs / 12 READMEs / 141 bats.
- [x] Verified counts via Explore agent (2026-04-27).
- [x] Confirmed P135 Phase 2 already audited 4 SKILLs (run-retro / work-problems / manage-problem / transition-problem).
- [x] Identified high-ask candidates: work-problem (11), mitigate-incident (8), manage-incident (7).
- [ ] Phase 2: audit work-problem singular SKILL.md.
- [ ] Phase 2: audit mitigate-incident SKILL.md.
- [ ] Phase 2: audit manage-incident SKILL.md.
- [ ] Phase 3: audit medium-ask SKILLs (review-jobs, analyze-context).
- [ ] Phase 3: audit low-ask SKILLs (~24 surfaces).
- [ ] Phase 4: audit 4 critical hooks (itil-assistant-output-gate, itil-assistant-output-review, manage-problem-enforce-create, voice-tone-eval).
- [ ] Phase 4: sweep remaining 65 hooks (single audit-log entry on this ticket).
- [ ] Phase 5: sweep 10 agents + 37 unaudited ADRs + 16 JTBDs + 12 READMEs.

## Fix Strategy

**Implementation plan**: see `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md` (drafted 2026-04-27 by Plan agent; risk-scored PASS at 3/3/4 by `wr-risk-scorer:plan`; user-approved 2026-04-27 via `/plan` workflow).

**6 phases** (sequenced for declarative-first + per-surface release cadence):

- **Phase 1 (Anchor, S ~1 hr)**: NEW P136 master ticket + README WSJF row. Doc-only, no changeset.
- **Phase 2 (High-ask SKILL audit, M ~3 hrs across 3 sessions)**: 3 separate per-skill audits + per-skill commits + per-skill `@windyroad/itil` patches drained between each. work-problem (11 calls) → mitigate-incident (8) → manage-incident (7).
- **Phase 3 (Medium + low-ask SKILL audit, M ~3 hrs across 4-6 sessions)**: 26 remaining SKILLs. Group truly zero-ask SKILLs (c4/check, c4/generate, list-incidents, list-problems, reconcile-readme) into single audit-log entry; 4-6 actual edit-bearing commits.
- **Phase 4 (Hook audit, S-M ~2 hrs)**: 4 critical hooks per-hook commits + changesets. Remaining 65 hooks bundled into single audit-log entry.
- **Phase 5 (Sweep, S ~1 hr)**: Agent + ADR + JTBD + README sweep. Bundle no-change-needed entries into single doc-only audit-log commit closing P136.
- **Phase 6 (Bats retrofit)**: NOT in P136 scope — P081 Phase 2 territory. P136 uses `tdd-review: structural-permitted` marker as bridge.

**Per-surface release cadence (R1 from P135 plan, validated)** drains projected release risk to one surface at a time. Each surface change ships its own release; drain before next surface starts.

**Deviation-candidate-only flow** (NOT auto-edit) per ADR-044 spirit. Each per-surface finding rides through ADR-044's 5-option deviation-approval `AskUserQuestion` (Approve+amend / Approve+supersede / Approve+one-time / Reject / Defer) at retro end. User can reject; SKILL reverted via `git revert`.

**No CLAUDE.md changes** — settled at P135 plan-approval. Don't re-litigate.

## Dependencies

- **Blocks**: per-session lazy-AskUserQuestion friction continues on un-audited SKILLs until P136 Phases 2-4 land.
- **Blocked by**: (none — Phase 1 can proceed standalone; subsequent phases sequenced per plan).
- **Composes with**: P135 (predecessor — established ADR-044 + amended 4 SKILLs), P132 (inverse-P078 enforcement), P081 (canonical bats retrofit; P136 bridge via `tdd-review: structural-permitted` marker), P130 (orchestrator presence-aware dispatch — same family of agent-discipline gaps), P131 (user-space writes — same family).

## Related

- **ADR-044** (`docs/decisions/044-decision-delegation-contract.proposed.md`) — the architectural anchor. Captures the 6-class authority taxonomy + framework-mediated surface enumeration + anti-BUFD-for-framework-evolution clause + R6 numeric gate Reassessment Trigger.
- **ADR-013** (`docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md`) — Rule 1 amended in P135 Phase 1.
- **ADR-014** (`docs/decisions/014-governance-skills-commit-their-own-work.proposed.md`) — commit-grain precedent. Per-surface commits per ADR-014.
- **ADR-022** (`docs/decisions/022-problem-verification-pending.proposed.md`) — lifecycle precedent.
- **ADR-040** (`docs/decisions/040-progressive-disclosure-tier-policy.proposed.md`) — declarative-first precedent (R1 cadence + advisory enforcement matches).
- **ADR-042** (`docs/decisions/042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — auto-apply with bounded vocabulary precedent (deviation-approval surface inherits the spirit).
- **P135** (`docs/problems/135-decision-delegation-contract-master.open.md`) — predecessor master ticket.
- **P132** (`docs/problems/132-...open.md`) — inverse-P078 over-asks; P132's Phase 4 enforcement hook is gated on R6 (post-P136 measurement).
- **P081** (`docs/problems/081-...open.md`) — canonical bats retrofit. P136 cross-references P081 in Phase 6.
- **P130** (`docs/problems/130-...open.md`) — orchestrator presence-aware dispatch.
- **P131** (`docs/problems/131-...open.md`) — agents write to `.claude/` user space.
- `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md` — the approved 6-phase implementation plan.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — primary persona served. Suite-wide alignment IS the without-slowing-down outcome.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — primary persona served. AFK iters compound friction across un-aligned SKILLs.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-the-suite-with-new-plugins.proposed.md`) — composes via per-surface SKILL.md edits that ship to adopters.
- **JTBD-201** (audit trail) — composes via Step 2d "Ask Hygiene Pass" lazy-count metric trend across consecutive retros as Phases land.
- 2026-04-27 session evidence: P135 implementation completed; user surfaced the audit gap directly: *"we should also do an audit of all the files (hooks, skills, agents, etc) to make sure they align with the clarified direction and make sure CLAUDE.md and other files don't contradict"*. /plan workflow opened; Plan agent designed 6-phase plan; risk-scorer:plan PASS at 3/3/4; user approved.
