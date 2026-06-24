# Problem 377: Skills, agents, and hooks override RISK-POLICY appetite instead of applying it

**Status**: Open
**Reported**: 2026-06-24
**Priority**: 16 (High) — Impact: 4 (High) × Likelihood: 4 (Likely). Rated at capture from observed evidence. Impact 4: RISK-POLICY is the safety bound; surfaces that override it let above-appetite work ship and defeat the policy's purpose, and it ships to adopters. Likelihood 4: fires on every above-appetite commit; structural across 8+ surfaces.
**Origin**: internal
**Effort**: L — multi-ADR (013/042/044) + ~8 skills + 2 scoring agents + hooks + RISK-POLICY.md. WSJF = (16 × 1.0) / 4 = 4.0. Likely warrants an RFC.

## Description

Multiple surfaces **override** RISK-POLICY.md's appetite rather than faithfully applying it. RISK-POLICY § Risk Appetite (lines 85-86) says: above appetite → "applies additional controls, or **blocks/halts** the action per the gate-specific rules." It sanctions NO "ask the user to commit anyway" path and defines NO `RISK_BYPASS` exceptions. Yet:

Surfaced 2026-06-24 by user: *"I am NEVER going to give above-appetite permission. Don't ask again. EVER"* → *"the Skill incorrectly tells you to [ask]"* → *"ADR-013 might be the culprit too"* → *"the pipeline agent should be using the risk policy, not overriding it"* → *"are there any other skills, agents or hooks that try to override the risk policy?"*

## Audit (2026-06-24) — override taxonomy

**A. Above-appetite COMMIT ask (override — policy says block/halt, not ask).** Codified as ADR-044 **category-3 (one-time-override)** AskUserQuestion surface, anchored in **ADR-013**:
- `packages/risk-scorer/skills/assess-release/SKILL.md:85` — "If any score is above appetite, use AskUserQuestion to ask..."
- `packages/itil/skills/manage-problem/SKILL.md:1083`, `transition-problem/SKILL.md:310`, `transition-problems/SKILL.md:215` — non-incident; **clear bugs**.
- `packages/itil/skills/manage-incident/SKILL.md:308`, `mitigate-incident/SKILL.md:171`, `restore-incident/SKILL.md:140` — incident-context category-3, justified by JTBD-201 restore-service-fast. **Decision needed**: does "never above appetite" carve out incidents?
- Note: the same skills' PUSH/RELEASE branch already says the CORRECT thing (manage-problem:1109, manage-incident:332, work-problems Step 6.5): "per ADR-042 MUST auto-apply remediations... MUST NOT release above appetite... MUST NOT call AskUserQuestion as a shortcut." The commit branch contradicts the release branch.

**B. Scoring agents hardcode appetite instead of reading it from RISK-POLICY.md.**
- `packages/risk-scorer/agents/pipeline.md` (lines 171/180/217) hardcodes `≤ 4` / `> 4`; line 422 says "Follow RISK-POLICY.md for appetite" but the threshold is baked in. An adopter who sets a different appetite is ignored.
- `packages/risk-scorer/agents/wip.md` — same hardcoded-threshold pattern.

**C. Agent-invented bypasses not anchored in RISK-POLICY.md.**
- `pipeline.md` defines `RISK_BYPASS: reducing` (risk-reducing commits) + `RISK_BYPASS: incident` (live incidents); the commit-gate hook honours `reducing-commit` / `incident-release` / `ci-bypass` / `adr-031-migration` markers. None is defined in RISK-POLICY.md. **Decision needed**: policy-anchor them (add a RISK-POLICY § Exceptions) or remove.

**D. `BYPASS_RISK_GATE=1` env escape hatch** (`gate-helpers.sh`) — the nuclear override. Disposition decision needed.

## Root Cause Analysis

### Investigation Tasks

- [x] Rated at capture (Impact 4 × Likelihood 4, Effort L)
- [x] Audit complete (2026-06-24 — taxonomy A-D above)
- [ ] **Governance fix (ADR-level)**: remove/narrow the ADR-013/ADR-044 category-3 "above-appetite commit" surface; extend ADR-042 (auto-remediate, never above appetite, never ask) to cover COMMIT not just push/release. Architect + user substance-confirm.
- [ ] Fix the clear bugs (Class A non-incident + assess-release): replace the above-appetite-commit AskUserQuestion with ADR-042 auto-remediate language (mirror the release branch already in the same files).
- [ ] Fix Class B: pipeline.md + wip.md read the appetite from RISK-POLICY.md, not a hardcoded `4`.
- [ ] Resolve Class A incident carve-out + Class C/D bypass disposition (user decisions) and apply.
- [ ] Behavioural tests / promptfoo coverage for the corrected above-appetite behaviour.

## Related

- Memory `feedback_never_offer_above_appetite` — the behavioural rule (never offer above-appetite, auto-remediate). This ticket is the structural root-cause fix behind it.
- **ADR-042** — auto-apply remediations to reach within appetite; never release above. The fix extends this to commit.
- **ADR-013 / ADR-044** — codify the category-3 one-time-override above-appetite surface that is the governance root of Class A.
- **P375** — sibling immune-system ticket (uncadenced deferrals); same "framework already resolved it, surface re-asks anyway" inverse-P078 / P132 class.
- **RISK-POLICY.md** § Risk Appetite — the authority being overridden.

(captured via direct write — rated at capture per the P375 rate-at-capture rule)

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-029 | proposed | Apply RISK-POLICY appetite faithfully across all surfaces |
