# Ask Hygiene — 2026-05-04 (P167 / Phase 0 RISK-POLICY.md session)

Per Step 2d / ADR-044. 4 AskUserQuestion calls. Lazy count = 0.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Scope | deviation-approval | Gap: architect raised 3 blocking preconditions (composition-rule documentation, RC3 framing, methodology ADR) that meaningfully expanded the user's pre-pinned "A" answer beyond what they signed up for; ADR-044 category 2 — existing-direction deviation. |
| 2 | Approve draft | silent-framework | Framework: `packages/risk-scorer/skills/update-policy/SKILL.md` Step 6 mandates AskUserQuestion confirmation before write — "You MUST use the AskUserQuestion tool (not plain text output) to collect user confirmation. Do not proceed to step 7 until you have received answers via AskUserQuestion." |
| 3 | Proceed | correction-followup | Framework: ADR-044 category 6 / P078 capture-on-correction surface — clarifying the operational implication of the user's "I don't agree with this" correction (revert + redraft, partial revert, or halt). |
| 4 | Approve redraft | silent-framework | Framework: `packages/risk-scorer/skills/update-policy/SKILL.md` Step 6 — same skill-mandated confirmation re-entered after the redraft per Step 7 validate + Step 8 write contract. |

**Lazy count: 0**
**Direction count: 0**
**Deviation-approval count: 1**
**Override count: 0**
**Silent-framework count: 2**
**Taste count: 0**
**Correction-followup count: 1**

R6 numeric gate (lazy ≥ 2 across 3 consecutive retros): not fired.
