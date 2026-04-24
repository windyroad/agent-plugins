---
"@windyroad/risk-scorer": minor
---

feat(risk-scorer): pipeline agent emits `RISK_REGISTER_HINT:` passive trigger for the risk register (P110)

The `wr-risk-scorer:pipeline` agent now emits a structured `RISK_REGISTER_HINT:` block alongside its existing `RISK_SCORES:` / `RISK_REMEDIATIONS:` / `RISK_BYPASS:` outputs when it identifies a register-worthy risk shape. The calling orchestrator consumes the hint post-remediation-loop and hands off to `/wr-risk-scorer:create-risk` with pre-filled context.

This closes the passive-trigger gap P102's MVP slash command left open. JTBD-001 (Enforce Governance Without Slowing Down) requires passive triggers that fire "without a manual step" — the pipeline agent is hook-fired on every commit/push/release gate, so a hint emitted from it inherits that passivity.

**Shape** (bulleted-list, multi-hint capable):

```
RISK_REGISTER_HINT:
- above-appetite-residual | <one-line prefill>
- confidentiality-disclosure | <one-line prefill>
- user-stated-precondition | <one-line prefill>
```

**Reason-tag vocabulary** (closed — extending requires a new ticket):

- `above-appetite-residual` — any cumulative residual score > appetite
- `confidentiality-disclosure` — business metric or client detail flagged in diff
- `user-stated-precondition` — paired capability unmet; standalone Risk item

**Consumption semantics**: the hint is consumed by the orchestrator **after** the ADR-042 auto-apply remediation loop converges or halts — not interleaved. A remediation that reduces residual back within appetite does not retract the hint; the risk is standing even if this change is no longer in breach.

**Silence guarantee**: no hint is emitted when all cumulative scores are within appetite AND no confidentiality-disclosure or user-stated-precondition item fires — preserves the ADR-013 Rule 5 silent-pass contract.

Additive change — existing `RISK_SCORES:` / `RISK_REMEDIATIONS:` / `RISK_BYPASS:` outputs and the ADR-042 auto-apply loop are unchanged.

Refs P110, P102 (parent), JTBD-001, JTBD-005, ADR-015 (Scorer Output Contract addendum).
