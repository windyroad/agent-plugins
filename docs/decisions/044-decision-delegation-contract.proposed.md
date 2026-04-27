---
status: proposed
date: 2026-04-27
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent, wr-risk-scorer:plan]
amends: [013-structured-user-interaction-for-governance-decisions]
reassessment-date: 2026-10-27
---

# ADR-044 — Decision-Delegation Contract: when agents act on the framework vs ask the user

## Context and Problem Statement

The windyroad-claude-plugin project ships a substantial governance framework — 43 prior ADRs, JTBDs by persona, `RISK-POLICY.md`, `VOICE-AND-TONE.md`, `STYLE-GUIDE.md`, the WSJF prioritisation formula with documented tie-breaks, the `.open.md` → `.known-error.md` → `.verifying.md` → `.closed.md` lifecycle (ADR-022), and dozens of SKILL.md contracts that explicitly distinguish mechanical stages from user-interactive stages. This is a **substantial codification of decisions the user has already made**. Agents are meant to consume this codification and apply it; the per-action consent surface is meant to be reserved for cases where the framework has not already settled the answer.

Observed (2026-04-27 session): agents over-apply ADR-013 Rule 1's "interactive default = AskUserQuestion" to mechanical decisions where the framework has already decided. Per-session lazy-AskUserQuestion count was high enough that the user surfaced the friction directly: *"As part of the retro, there is friction with you asking me if you should update the briefing and/or create tickets. Why do you feel you need to ask me?"*. Five user corrections in one session (subprocess dispatch in iter 9; grep approach for P081 implementation; `.claude/` user-space writes; retro cascade scope; "removals shouldn't be an ask") each landed as problem tickets (P130, P131, P132, P133, P134). The tickets capture the surface symptoms; this ADR captures the underlying principle.

A long session-end conversation crystallised the underlying principle: **the framework IS a decision-delegation contract**. Per-action `AskUserQuestion` calls reverse the user's investment by re-asking decisions the user already made. When the framework's answer is clear, the agent's job is to **read it, apply it, act on it, and report**; not to sub-contract the work back to the user via redundant consent gates. P132 captured this as an inverse of P078 (capture-on-correction); ADR-044 generalises P132's "mechanical-zone" framing to the entire framework-resolution surface.

A second principle emerged from the same conversation: **anti-BUFD applies to framework evolution too**. The framework is **point-in-time** — its decisions were made under the context of work done so far. As reality changes, existing decisions may become wrong. The agent should not blindly follow an existing decision when current evidence contradicts it; nor should it auto-deviate without approval. The right response is to surface a **deviation candidate** with citations (the existing decision + the contradicting evidence + a proposed shape for the deviation) and queue it for user approval. The framework evolves incrementally based on actual need, not speculation; the agent is the empirical-discovery surface that produces the inputs the user needs to evolve the framework.

## Decision Drivers

- **JTBD-001 — Enforce Governance Without Slowing Down**: per-action `AskUserQuestion` consent gates that the framework has already settled directly slow the user down. Removing them while preserving the genuine human-value asks restores the velocity JTBD-001 promises.
- **JTBD-006 — Progress the Backlog While I'm Away**: the AFK orchestrator (`/wr-itil:work-problems`) cannot ask the user mid-loop — they're not present. Direction-class observations queue at iteration level for batched presentation on return. The deviation-candidate surface fits naturally here: the loop discovers misfits empirically; the user resolves them in one batch on return.
- **JTBD-101 — Extend the Suite with New Plugins**: downstream adopters of the windyroad SKILLs inherit the contract. ADR-044 + the Phase 2 SKILL.md edits (in P135's plan) propagate to adopters via published packages.
- **JTBD-201 — Restore Service Fast with an Audit Trail**: a measurable lazy-AskUserQuestion-count metric (Step 2d "Ask Hygiene Pass" — also part of P135's plan) gives the audit surface that proves the contract is being followed.
- **Anti-BUFD as a project value**: the framework's whole evolution discipline is incremental-discovery-from-real-friction, not big-design-up-front. The agent's role in that discipline is to act on the framework, surface misfits with evidence, and queue both new direction and deviation approvals for user batch resolution.

## Considered Options

### Option A — Status quo (ADR-013 Rule 1 unchanged)

Keep ADR-013 Rule 1 as the dominant rule: every branch point with two or more options uses `AskUserQuestion`. Rely on agent judgement to apply Rule 5 (policy-authorised silent proceed) when policy resolves the decision.

- **Pros**: no ADR churn; no SKILL amendments; preserves existing per-action consent surface.
- **Cons**: the observed pattern is exactly that agents do NOT apply Rule 5 when policy resolves the decision — the lazy-ask count is the metric that quantifies the failure. Status quo means the friction continues; user keeps getting asked about decisions they already made; framework's investment is silently undone every session.

### Option B — Supersede ADR-013 entirely with a new ADR

Mark ADR-013 superseded; draft a new ADR (e.g. ADR-044) covering both the original ADR-013 scope (structured user interaction) AND the new framework-resolution boundary.

- **Pros**: cleanest historical trail; no two ADRs both load-bearing on overlapping concerns; new ADR is the single citation source.
- **Cons**: ADR-013's Rules 2-6 (agent purity, owner of `AskUserQuestion`, plan mode for multi-step remediations, policy-authorised silent proceed, non-interactive fail-safe) are cited from many SKILL.md files and from other ADRs (ADR-032, ADR-040, ADR-042). Supersession requires rewriting every `ADR-013 Rule 5` reference across 12+ files. Cost-benefit unfavourable.

### Option C — Sibling ADR (NEW ADR-044) + amend ADR-013 Rule 1 in place — CHOSEN

Draft ADR-044 covering the framework-resolution boundary, the 6-class authority taxonomy, the deviation-approval surface, and the anti-BUFD-for-framework-evolution clause. Amend ADR-013 Rule 1 in place to add a forward pointer to ADR-044 (`...MUST use AskUserQuestion only when the framework has not already resolved the decision (see ADR-044)`). Rules 2-6 of ADR-013 untouched.

- **Pros**: ADR-013's Rules 2-6 stay load-bearing; downstream citations still work; the narrowing is local (single line edit on ADR-013) and the new content lives in its own ADR with its own Confirmation Criteria + Reassessment Triggers.
- **Cons**: readers must follow the cross-reference from ADR-013 to ADR-044 to get the full picture during the transition. Mitigated by ADR-013's amended Rule 1 explicitly naming ADR-044 as the framework-resolution authority.

## Decision Outcome

**Chosen option: C — sibling ADR-044 + amend ADR-013 Rule 1 in place.**

### The Six-Class Authority Taxonomy

Human input via `AskUserQuestion` is reserved for these categories. Everything else is framework-mediated and the agent acts and reports.

1. **Direction-setting for new work** — what to add to the suite (new tickets, new ADRs, new SKILLs, new gaps to close). Only the user knows the goals that haven't been written down yet.
2. **Deviation approvals from existing design decisions** — existing decisions are point-in-time, made under the context of work done so far. As reality changes, existing decisions may become wrong. The agent surfaces deviation candidates (citing the existing decision + the contradicting evidence per ADR-026 grounding + a proposed shape: amend / supersede / one-time-override) and the user approves the shape. **Never auto-deviate; never blindly follow against evidence.**
3. **Strategic one-time override** — the rule still stands; this specific case warrants an exception (not a rule-change). Distinct from deviation-approval (which requests rule-change).
4. **Genuinely-silent-framework cases** — no ADR / JTBD / policy / WSJF / risk-score / SKILL contract applies. By definition rare; the framework's coverage grows over time as deviation-approvals + new direction land.
5. **Taste on novel artefacts** — naming, voice, design aesthetics where no `VOICE-AND-TONE.md` / `STYLE-GUIDE.md` / `RISK-POLICY.md` settles the case.
6. **Authentic correction** — the P078 surface. Agent went wrong; user catches it. The framework can't pre-encode every wrongness shape; the user uniquely sees the gaps.

### Framework-Mediated Surface (NOT an `AskUserQuestion` zone)

The agent reads the framework and acts. Reporting is the oversight surface (user reads what the agent did and corrects via category 6 if wrong).

- **Releases** — `RISK-POLICY.md` appetite + ADR-042 auto-apply. Within appetite (≤4) drain. Above appetite converge or halt. Never per-release ask.
- **External comms** (upstream issues, comments, advisories) — P064 risk-scoring gate + P038 voice-tone gate (when both ship). Same risk-framework discipline. Never per-comment ask.
- **Prioritisation** — WSJF formula + documented tie-breaks (Known Error > Open; smaller effort first; older reported date). Pick + work.
- **Verification close** — close-on-evidence + report. Reversible if wrong. The framework's `## Fix Released` section + the agent's specific in-session citations are sufficient evidence; per-candidate ask is lazy deferral.
- **Codification shape** — `run-retro` Step 4b's catalog (skill / agent / hook / settings / script / CI / ADR / JTBD / guide / test fixture / memory). Pick the obvious-fit shape per observation; user edits the ticket if the shape was wrong.
- **Briefing add / remove / rotate** — Step 1.5's silent-classification model. Agent owns add/remove/rotate decisions on signal-vs-noise heuristics; user reads the Step 5 summary and corrects via category 6 if wrong.
- **Lifecycle transitions** — ADR-022 status flip mechanics: `git mv` rename + Status edit + P057 re-stage + P062 README refresh + ADR-014 commit. Mechanical.
- **Multi-concern split** — P016 concern-boundary analysis. N concerns → N tickets. No ask.
- **Continue / stop loops** — quota / policy decides. The natural stop is concrete (quota exhausted, ALL_DONE conditions met), not "you might want to review".

### Anti-BUFD-for-Framework-Evolution

Existing decisions are point-in-time. The framework is evolving, not fixed.

- **Don't predict the future** — write decisions for the current evidence + current scope. Don't speculate about cases that may never materialise.
- **Surface misfits when reality demonstrates them** — when the agent encounters an existing decision that current evidence contradicts, queue a deviation candidate (don't auto-deviate; don't blindly follow against evidence).
- **The deviation-candidate is the inputs the user needs to evolve the framework well** — citations + shape proposal + user batch-resolves on return.
- **The framework grows from the deviations** — every approved amend / supersede expands the framework's coverage, reducing the `genuinely-silent-framework` surface over time.

This is the same anti-BUFD discipline that drives WSJF-emergent ranking, the lifecycle's incremental discovery + verification, the codification candidates' ≥3-occurrence threshold, and the run-retro's reflection-and-capture flow. Framework evolution is no different.

## Consequences

### Good

- Restored governance velocity per JTBD-001 — the framework's investment in writing decisions down is honoured by the agent's "read + apply + act + report" default.
- Direction-class observations + deviation candidates accumulate from real friction (anti-BUFD), batched at AFK loop end + interactive retro end for user batch resolution.
- Lazy-AskUserQuestion count becomes a measurable per-session regression metric (Step 2d). Trend toward 0 = success.
- Framework evolves incrementally based on actual need not speculation. Deviations surface with evidence; user approves with full context.
- Inverse-P078 (excess-asks) and P078 (missing-asks) compose: ADR-044's 6-class taxonomy is the joint surface that makes both directions enforceable.

### Bad

- During the transition, downstream readers of ADR-013 must follow the cross-reference to ADR-044 for the full picture. Mitigated by ADR-013's amended Rule 1 explicitly naming ADR-044.
- The `genuinely-silent-framework` category is a moving target — as the framework grows, the silent surface shrinks. Sessions early in adoption will have more silent-framework asks than later sessions. Acceptable: this is the framework working as designed.
- Deviation-approval requires the agent to recognise misfits. False negatives (missed deviations the user would have approved) trail false positives (deviation candidates the user rejects). The plan's bats coverage for deviation-candidate emission asserts the positive (queueing-when-evidence-present is mandatory) but cannot guarantee no-false-negatives. The Step 2d lazy-count metric + per-session retro reflection are the long-tail catchers.

### Neutral

- ADR-013's Rules 2-6 stay load-bearing. No churn on the ~12+ downstream files citing them.

## Confirmation

The decision is satisfied when:

1. **Bats coverage** as named in P135's plan (`/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md`) lands and stays green:
   - `packages/retrospective/scripts/test/check-ask-hygiene.bats`
   - `packages/retrospective/skills/run-retro/test/run-retro-step-4a-cross-plugin-dispatch.bats`
   - `packages/retrospective/skills/run-retro/test/run-retro-step-4a-recovery-path.bats`
   - `packages/itil/skills/manage-problem/test/manage-problem-step-9d-recovery-path.bats`
   - `packages/itil/skills/work-problems/test/work-problems-mid-loop-userpromptsubmit-handler.bats`
   - `packages/itil/skills/work-problems/test/work-problems-deviation-candidate-shape.bats`
   - `packages/itil/hooks/test/itil-decision-delegation-detect.bats` (Phase 4, gated)

2. **Measurable lazy-AskUserQuestion-count metric** (Step 2d "Ask Hygiene Pass" in `run-retro`) trends toward 0 across consecutive retros. Today's baseline ~5-6 lazy calls per session. Target after Phase 2 lands: ≤2. Target after Phase 3 lands: ≤1 (mid-loop asks gone). Target steady-state: 0.

3. **Explicit deviation-candidate behavioural assertion** — the `work-problems-deviation-candidate-shape.bats` covers (a) iter emits deviation-candidate with required fields (existing-decision citation, contradicting-evidence citation per ADR-026, proposed shape ∈ {amend, supersede, one-time}); (b) iter does NOT auto-deviate when an existing decision appears no-longer-right; (c) loop-end emit presents the 5-option `AskUserQuestion`; (d) jsonl persistence preserves the shape across iter subprocess boundary; (e) positive regression: not-queueing-when-evidence-present is a regression. This makes the anti-BUFD-for-framework-evolution clause verifiable, not just doc-text.

## Reassessment

Re-evaluate this ADR if any of:

- Lazy-AskUserQuestion count fails to trend toward 0 across 5+ consecutive retros after Phase 2/3 land. Indicates the declarative path is insufficient; Phase 4 enforcement hook is the gated next step (per P135's plan R6 numeric gate).
- Deviation-candidate false-negative rate becomes load-bearing — when the user is approving deviation candidates the agent should have surfaced but didn't. May require adding explicit deviation-detection heuristics to Phase 4's enforcement hook.
- The 6-class authority taxonomy proves under-resolved — when classifying a session's `AskUserQuestion` calls during Step 2d produces ambiguous categorisations. May require sub-categories or framework refinement.
- A new SKILL or ADR pattern emerges that has its own ask-vs-act distinction not covered by this ADR. ADR-044 is the canonical reference; new patterns should cite it or propose an amendment.

## Related

- **ADR-013** (`013-structured-user-interaction-for-governance-decisions.proposed.md`) — amended in place. ADR-044 narrows Rule 1 with a forward pointer; Rules 2-6 untouched.
- **ADR-014** (`014-governance-skills-commit-their-own-work.proposed.md`) — commit-grain precedent. P135's per-phase work commits per ADR-014 (one ticket-unit-of-work per commit).
- **ADR-022** (`022-problem-verification-pending.proposed.md`) — lifecycle-mechanical example. Verification-close is framework-mediated per this ADR's framework-mediated list.
- **ADR-026** (`026-cost-source-grounding.proposed.md`) — grounding requirement. The deviation-candidate shape uses ADR-026's tool-invocation + observable-outcome citation discipline.
- **ADR-032** (`032-governance-skill-invocation-patterns.proposed.md`) — sub-pattern parent. AFK loop's deviation-candidate queue uses ADR-032's pending-questions artefact precedent (`.afk-run-state/outstanding-questions.jsonl`).
- **ADR-040** (`040-progressive-disclosure-tier-policy.proposed.md`) — declarative-first precedent. P135's Phase 4 enforcement hook is gated on Phase 1-3 declarative being insufficient (R6 numeric gate).
- **ADR-042** (`042-auto-apply-scorer-remediations-open-vocabulary.proposed.md`) — auto-apply precedent. ADR-044's framework-mediated release surface uses ADR-042's auto-apply-with-bounded-vocabulary.
- **ADR-043** (`043-progressive-context-usage-measurement.proposed.md`) — measurement precedent. P135's Phase 5 Step 2d "Ask Hygiene Pass" mirrors ADR-043's cheap-layer measurement shape.
- **P078** (`docs/problems/078-...verifying.md`) — capture-on-correction. ADR-044's category 6 (authentic correction) is the P078 surface.
- **P130** (`docs/problems/130-...open.md`) — orchestrator presence-aware dispatch. Subprocess-vs-main-turn shape is itself a deviation-approval candidate when the user is observably present mid-loop.
- **P131** (`docs/problems/131-...open.md`) — agents write to `.claude/` user space. Captures the inverse case where gate-exclusion-as-write-permission is a wrong inference; ADR-044's framework-mediated boundary clarifies the discipline.
- **P132** (`docs/problems/132-...open.md`) — inverse-P078 over-asks. P132 is the surface; ADR-044 is the underlying principle. P132's Phase 4 enforcement hook is the load-bearing implementation of ADR-044's framework-resolution boundary.
- **P133** (`docs/problems/133-...open.md`) — zsh-portability. Adjacent gap surfaced in the same correction-rich session.
- **P134** (`docs/problems/134-...open.md`) — README accumulator-bloat. Same family of session-discovered surfaces.
- **P135** (`docs/problems/135-decision-delegation-contract-master.open.md`) — master ticket for the implementation work. References this ADR + the 5-phase plan at `/Users/tomhoward/.claude/plans/noble-cuddling-sutton.md`.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance-without-slowing-down.proposed.md`) — primary persona served.
- **JTBD-006** (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — primary persona served.
- **JTBD-101** (`docs/jtbd/plugin-developer/JTBD-101-extend-the-suite-with-new-plugins.proposed.md`) — composes via Phase 2 SKILL.md edits that ship to adopters.
- **JTBD-201** (`docs/jtbd/tech-lead/JTBD-201-audit-trail.proposed.md`) — composes via the Step 2d lazy-count metric audit surface.
