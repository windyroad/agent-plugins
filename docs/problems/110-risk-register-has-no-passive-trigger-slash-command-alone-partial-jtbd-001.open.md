# Problem 110: Risk register has no passive trigger — `/wr-risk-scorer:create-risk` alone partially satisfies JTBD-001

**Status**: Open
**Reported**: 2026-04-22
**Priority**: 8 (Medium) — Impact: Minor (2) x Likelihood: Likely (4)
**Effort**: M
**WSJF**: (8 × 1.0) / 2 = **4.0**

> Surfaced 2026-04-22 by the JTBD gate review during P102's fix implementation. P102 landed candidate (a) — slash command `/wr-risk-scorer:create-risk` — as a minimum-viable invocation surface, with an explicit scope note that passive triggers (candidates b/c/d from P102) are out of scope and tracked here. JTBD review confirmed the slash command alone is a floor for JTBD-005 (on-demand) and tech-lead auditability but does **not** fully satisfy JTBD-001 (solo-developer: Enforce Governance Without Slowing Down), because JTBD-001 explicitly rejects reliance on the assistant remembering to invoke — "no manual step is needed to trigger reviews — they happen on every edit".

## Description

P102's root-cause analysis (lines 42-44 of the verifying ticket) identified that `docs/risks/` sat empty for 5 days after P033 scaffolding because scaffolding + "populate incrementally" has no trigger. The fix shipped in P102 adds ONE trigger: the user (or assistant) invoking `/wr-risk-scorer:create-risk` by hand. This is the same failure mode as the pre-fix state, only one level up — the register now depends on the assistant *remembering to invoke the command* when a register-worthy risk appears, which the JTBD-001 pain point identifies as unreliable ("agents skip steps").

The missing piece is a **passive trigger** — something that fires without the assistant's explicit intent. P102 enumerated three candidates: (b) risk-scorer pipeline back-channel, (c) retro-step, (d) CLAUDE.md workflow rule. This ticket tracks selecting and implementing one (or more) of them.

## Symptoms

- Slash-command-only invocation requires the assistant to *remember* to invoke during a workflow that identified a register-worthy risk. JTBD-001's pain point is precisely that assistants skip steps.
- Pipeline risk reports (`wr-risk-scorer:pipeline` in `.risk-reports/`) identify standing-risk shapes (e.g. confidential-info leakage, context budget, hook-stack overhead) on every commit/push/release, but there is no back-channel to the register — those findings stay ephemeral.
- Retros (`/wr-retrospective:run-retro`) capture codification candidates but do not explicitly capture risks observed during the session.
- CLAUDE.md has no workflow rule directing the assistant to propose a register entry when pipeline scoring identifies an above-appetite residual.

## Workaround

Assistant and user should manually run `/wr-risk-scorer:create-risk` when a register-worthy risk is identified during a session. P102's MVP slash command is the current workaround for this ticket.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona (JTBD-001) — the "without slowing down" outcome is at risk because registration requires a manual step that may not fire.
  - Tech-lead persona (auditability) — a populated register that depends on manual invocation is a weaker audit signal than one backed by a passive process (the audit expects "risks are recorded as they surface", not "risks are recorded when the assistant remembers").
- **Frequency**: Every session that produces a register-worthy risk finding without an explicit invocation.
- **Severity**: Minor. The MVP slash command works when invoked; the harm is slow-leak (risks that are identified but not recorded). Not acutely breaking — closing this ticket improves the *reliability* of the register rather than restoring any lost functionality.
- **Analytics**: Baseline starts 2026-04-22 with R001 populated. If in 30 days the register has 1-2 entries despite session activity producing 5+ register-worthy findings, that confirms the gap.

## Root Cause Analysis

### Confirmed Root Cause

P102 deliberately scoped to CREATE-only slash command to ship a minimum-viable invocation surface within budget. That was the right call for P102's scope but left the passive-trigger work as follow-up. The root cause remains the same as P102: organic population assumes an invocation route, and a user-invoked slash command is not an organic route for risks that surface during autonomous AFK sessions, pipeline findings, or retro observations.

### Investigation Tasks

- [ ] Pick one trigger candidate to land first. Evaluate per JTBD fit + implementation cost:
  - **(b) Pipeline back-channel** — when `wr-risk-scorer:pipeline` identifies a standing-risk shape in `.risk-reports/`, write a "propose register entry?" hint into the pipeline output. The assistant reads the hint and invokes `/wr-risk-scorer:create-risk` with pre-filled context. Requires: modifying `packages/risk-scorer/agents/pipeline.md` to emit the hint + documenting the hand-off protocol in the create-risk SKILL.md. *Might amend ADR-026 (grounding flow).*
  - **(c) Retro step** — add a "risks-observed-this-session" step to `/wr-retrospective:run-retro`, analogous to Step 4b's codification-candidates table. Fires on every retro, so the trigger is guaranteed. Requires: modifying `packages/retrospective/skills/run-retro/SKILL.md`.
  - **(d) CLAUDE.md workflow rule** — mandate via a `UserPromptSubmit` hook injection that the assistant proposes a register entry whenever a pipeline scoring identifies an above-appetite residual. Hook-injected MANDATORY prose, per ADR-038 pattern. Requires: a new hook in risk-scorer + the CLAUDE.md rule.
- [ ] Architect review to decide whether (b) amends ADR-026, whether (c) is a local retro change or warrants amending retrospective's ADR, whether (d) warrants a new cross-cutting ADR.
- [ ] Observe whether the MVP slash command alone produces enough registry population in 30 days to close this ticket without the passive trigger. (Baseline starts 2026-04-22 with R001.)

### Fix Strategy

Pending investigation. Expected shape: pick one of (b)/(c)/(d) after 30 days of observation data. Favour (c) retro-step as a low-risk first pass — it is local to the retrospective plugin, fires on cadence, and does not require amending ADR-026. If pipeline hand-off becomes desirable later, (b) is additive on top of (c).

## Dependencies

- **Blocks**: Final closure of **P102** — P102 can move Verifying → Closed once this ticket lands a passive trigger *or* 30-day observation confirms the slash command alone is sufficient.
- **Blocked by**: (none — P102's scaffolding + create-risk skill is sufficient substrate)
- **Composes with**: P033 (parent scaffolding), P034 (centralising `.risk-reports/`), P099 (briefing unbounded append — related append-only concerns)

## Related

- **P102 (No invocation surface creates risk register entries)** — parent. This ticket is the explicitly-out-of-scope follow-up from P102's fix strategy.
- **P033 (No persistent risk register)** — grandparent. The scaffolding this chain populates.
- **JTBD-001 (Enforce Governance Without Slowing Down)** — the job this ticket's fix fully satisfies (P102's fix is a floor).
- **JTBD-005 (Invoke Governance Assessments On Demand)** — already served by P102's slash command.
- **ADR-026 (Risk-scorer grounding)** — may need amendment if Investigation Task (b) lands.
- **ADR-038 (Progressive disclosure via hook-injected prose)** — the pattern that candidate (d) would follow.
