# Problem 377: Skills, agents, and hooks override RISK-POLICY appetite instead of applying it

**Status**: Verification Pending
**Reported**: 2026-06-24

## Fix Released

Fix shipped via RFC-029 (6 slices, all committed 2026-06-24; Wave 1 "P377 gate cohort" released to npm — `apply-risk-policy-appetite` changeset). The appetite-faithful behaviour is live: the risk-gate now reads the RISK-POLICY appetite (default 5 per ADR-086) rather than a hardcoded threshold, and the unauthorised `BYPASS_RISK_GATE` + ci-bypass paths were removed (verified this session — risk-gate.bats test "score 5 allows at threshold" green; the gate applies appetite 5, not an override). Transitioned Open→Verifying 2026-06-27 by the work-problems orchestrator (stranded-shipped; the only remaining task was the RFC-029 lifecycle transition + oversight ratification, which is interactive governance — queued for /wr-itil:manage-rfc accepted).

**Awaiting user verification** — confirm no skill/agent/hook surface overrides the RISK-POLICY appetite (all apply it), and ratify the RFC-029 human-oversight marker at the `manage-rfc accepted` transition.
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
- [x] **FIXED via RFC-029 (2026-06-24)** — 6 slices, all committed; architect + risk-scorer plan review PASS; user decisions locked + ADR substance P357-confirmed:
  - **Slice 1** `f91aad4d` — ADR-042 Rule 1 extended to commit + Rule 1b (incident-as-risk-reducing, no carve-out); ADR-044 cat-3 excludes above-appetite commit; ADR-013 Rule 5 extended.
  - **Slice 2** `1268747c` — above-appetite-commit AskUserQuestion removed from manage-problem, transition-problem(s), 3 incident skills, assess-release.
  - **Slice 3** `6cd909b2` — pipeline.md + wip.md read appetite from RISK-POLICY.md (Class B); incident framing propagated; plan-risk-guidance.sh default 5→4 (ADR-065 fix).
  - **Slice 4** `70862540` — BYPASS_RISK_GATE (Class D) + ci-bypass removed; reducing-*/incident-release kept; gate bats flipped (48/48 green).
  - **Slice 5** `7f10bd17` — update-policy writes an `## Authorized Bypass Scenarios` clause (Class C policy-anchoring; default-permitted-when-silent).
  - **Slice 6** — behavioural-enforcement floor verified: 166 risk-scorer hook bats + 315 changed-itil-skill contract bats green. The guarantee (never above appetite, no ask, appetite-from-policy, no bypasses) is enforced by the gate HOOKS (risk-gate.bats cases 23-28 + the Slice-4 flips), so it holds even if advisory prose drifts. SKILL-prose promptfoo not added: risk-scorer has no prose-eval harness and manage-problem's is Tier-A-only (no Tier-B grader for the negative no-ask clause) — a prose-eval-harness extension is a separate consideration (revisit only if prose drift is observed), NOT a silent deferral.
- [ ] Lifecycle: transition RFC-029 proposed → accepted/closed once released; ratify the RFC's human-oversight marker at /wr-itil:manage-rfc accepted.

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
