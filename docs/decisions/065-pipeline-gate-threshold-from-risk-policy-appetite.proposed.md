---
status: "proposed"
date: 2026-05-25
human-oversight: confirmed
oversight-date: 2026-05-25
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, downstream adopters]
reassessment-date: 2026-08-25
---

# Pipeline gate block threshold is derived from RISK-POLICY.md appetite, not hardcoded

## Context and Problem Statement

The pipeline risk gate (`packages/risk-scorer/hooks/lib/risk-gate.sh`, consumed by the commit / push / plan gates) decides whether to block an action by comparing the assessed risk score against a threshold. Before this decision the threshold was a code constant: `print('yes' if score >= 5 else 'no')`, with a deny message that read "Medium or above".

`RISK-POLICY.md` § Risk Appetite is the project's authoritative statement of how much pipeline risk it accepts. This repo's policy sets **"Threshold: 4 (Low)"** — "block when cumulative residual risk exceeds 4" — so the hardcoded `score >= 5` (i.e. `score > 4`) *coincidentally* matches this repo's appetite. But the constant is wrong for any adopter whose policy sets a different appetite. The `@windyroad/risk-scorer` package is installed into other projects; an adopter whose `RISK-POLICY.md` sets a higher appetite (for example "exceeds 9") has every within-appetite change in the 5-9 band gate-rejected, even though their own written policy says those changes are acceptable. The gate silently overrides the adopter's configured appetite with this repo's house number.

Upstream inbound report #149 (the P007 half) and local follow-up surfaced this. The threshold is policy, not code.

## Decision Drivers

- **JTBD-003 (Compose Only the Guardrails I Need)** — the gate must honour the adopter's configured `RISK-POLICY.md` appetite rather than impose the suite-author's number. A configurable policy file that the gate ignores is not composable.
- **JTBD-202 (Run Pre-Flight Governance Checks Before Release or Handover)** — the tech-lead persona "may install the full suite and configure policy files" and "needs consistent standards across multiple projects"; the gate must apply the standard the project actually documented.
- **JTBD-002 (Ship AI-Assisted Code with Confidence)** — the deny message must state the actual threshold applied so the audit trail is truthful.
- **No regression for existing installs** — projects without an appetite line (or without `RISK-POLICY.md`) must keep behaving exactly as before.
- **#149 / P007** — inbound report; the hardcoded threshold's cross-project blast radius.

## Considered Options

1. **Parse the appetite N from RISK-POLICY.md; block when `score > N`; default 4** (chosen) — the gate reads the project's own appetite. Default 4 when the policy is absent or unparseable preserves the prior `score >= 5` behaviour exactly for integer scores. Optional `RISK_APPETITE` env override mirrors the existing `RISK_TTL` / `BYPASS_RISK_GATE` env-knob convention.
2. **Keep the threshold hardcoded** — rejected: it ignores the adopter's `RISK-POLICY.md`, which is the defect.
3. **Env-injection only (no parse)** — require adopters to set `RISK_APPETITE` per session/CI. Rejected as the *primary* mechanism: it duplicates a value the project already states in `RISK-POLICY.md` and is easy to forget, re-introducing the silent-override failure for anyone who does not set it. Retained as an *override* layer (option 1's `RISK_APPETITE`) for incident/CI use, with the policy parse as the default source.

## Decision Outcome

**Chosen option: Option 1** — derive the threshold from `RISK-POLICY.md` § Risk Appetite.

`check_risk_gate` resolves the appetite integer N with this precedence:

1. `RISK_APPETITE` env override (when set to an integer) — mirrors `RISK_TTL`; for incident/CI use.
2. `RISK-POLICY.md` § Risk Appetite parse — tolerant of the phrasings `Threshold: N`, `exceeds N`, and `N/Low appetite`, scoped to the `## Risk Appetite` section so unrelated numbers elsewhere in the policy do not match.
3. Default **N = 4** when `RISK-POLICY.md` is absent or carries no appetite integer.

The gate blocks when **`score > N`** and renders the parsed threshold in the deny message: `… risk score S/25 exceeds the project appetite of N/25 (RISK-POLICY.md) …` (replacing the static "Medium or above"). The policy file is read from the gate's working directory (project root), consistent with how `external-comms-gate.sh` resolves `RISK-POLICY.md`.

`risk-gate.sh` is a single-copy library in `packages/risk-scorer/hooks/lib/` (not part of any ADR-017 sync set), so the change is confined to one file plus its behavioural test.

### Consequences

**Good**
- The gate honours each adopter's documented appetite; the 5-9 band is no longer wrongly blocked for higher-appetite projects.
- Default 4 + `score > N` reproduces the prior `score >= 5` behaviour exactly for integer scores (5 blocks, 4 passes), so existing installs (and this repo, whose policy is "Threshold: 4") see no behaviour change.
- The deny message now states the real threshold, keeping the JTBD-002 audit trail truthful.
- `RISK_APPETITE` reuses the existing env-knob convention; no new pattern.

**Neutral / accepted (per ADR-023 performance-review scope)**
- The gate now reads + regex-parses `RISK-POLICY.md` (~6 KB) on each gated `git commit` / `git push`. Cost: **~3-8 ms CPU/invocation**, ~6 KB transient memory, 0 network (worst-case estimate; no telemetry). Frequency anchor: **~75 gate cycles/day across 3 contributors** (the ADR-028 P166 projection). Aggregate: **~0.6 s/day worst-case**. No `performance-budget-*` ADR governs the pipeline gate; this aggregate is small and recorded here as accepted — no dedicated budget ADR is warranted at current scale. A future optimisation, if needed, is to memoize the parsed N per session (parse once, cache in the session risk dir), dropping the aggregate below ~0.1 s/day; not implemented now (the per-invocation read is within tolerance and keeps the gate stateless).

**Bad / watch**
- **Fractional-score behavioural delta**: the prior rule `score >= 5` and the new rule `score > N` are identical for integer scores at N=4, but diverge for non-integer scores in the open interval (4, 5): `4.5 > 4` now blocks, whereas `4.5 >= 5` previously passed. The risk matrix produces integer scores (1-25), so this delta does not arise in normal scoring; it is the more-correct behaviour (4.5 is above a 4 appetite). The "preserves prior behaviour exactly" claim is therefore scoped to **integer scores**, and a behavioural fixture (`score=4.5` → FAIL under default 4) pins the delta.
- **Sibling hardcoded `4` constants remain by hand**: ADR-042 (auto-apply scorer remediations) and the ADR-014 release-cadence appetite branch ("score ≤ 4") still encode the within-appetite constant `4` directly. These are NOT pipeline-gate *denials* (they are auto-apply / cadence decisions), so they are intentionally out of scope for this binding; a future reader who changes the gate appetite should know those two sites are not auto-derived and may need a matching manual update.

## Confirmation

Verified by behavioural bats in `packages/risk-scorer/hooks/test/risk-gate.bats` (per ADR-052 — gate PASS/FAIL fixtures against a parsed appetite, not structural greps):

- `RISK-POLICY.md` with "exceeds 9" → score 7 PASSES, score 10 FAILS.
- "Threshold: 9" phrasing → score 9 PASSES, score 10 FAILS.
- "exceeds 4" → score 4 PASSES, score 5 FAILS.
- Absent `RISK-POLICY.md` → default appetite 4 (4 PASSES, 5 FAILS).
- Unparseable `RISK-POLICY.md` (no appetite integer) → default appetite 4.
- Fractional `score=4.5` → FAILS under default 4 (the integer-only-equivalence delta).
- `RISK_APPETITE` env override takes precedence over the `RISK-POLICY.md` parse.
- The deny message renders the parsed appetite (`appetite of N/25`).
- The pre-existing `risk-gate.bats` suite (missing-score, expired, drift, three-band TTL, threshold category exports) remains green when run from the repo root (appetite parsed as 4 from this repo's policy).

## Pros and Cons of the Options

### Option 1: Parse appetite + default 4 + env override (chosen)
- Good: honours adopter policy; zero-config; backward-compatible; truthful deny message.
- Bad: per-invocation policy read (bounded, accepted above); fractional-score delta (documented + tested).

### Option 2: Keep hardcoded threshold (rejected)
- Bad: ignores `RISK-POLICY.md`; the defect itself.

### Option 3: Env-injection only (rejected as primary; retained as override)
- Good: explicit.
- Bad: duplicates the policy value; easy to forget → silent override returns for anyone who does not set it.

## Reassessment Criteria

Revisit if:
- The risk-scoring scale starts producing non-integer scores routinely (the fractional-score delta would then need a documented rounding rule).
- The per-invocation parse cost becomes material at higher contributor scale (implement the session-memoization noted above; possibly a `performance-budget-*` ADR).
- A second gate-mechanics constant needs the same policy binding (consider a shared appetite-resolver helper rather than duplicating the parse).

## Related

- **#149 / P007** — inbound report; hardcoded-threshold defect with cross-project blast radius.
- **ADR-009** (Gate marker lifecycle) — sibling gate-mechanics ADR; governs TTL/drift, says nothing about the threshold value — this ADR fills that gap.
- **ADR-014** (Governance skills commit their own work) — the release-cadence appetite branch encodes `4` by hand; noted as out of scope above.
- **ADR-023** (wr-architect performance review scope) — the per-invocation parse cost is recorded per its grounding discipline.
- **ADR-028** (External-comms gate) — precedent for resolving `RISK-POLICY.md` from the working directory.
- **ADR-042** (Auto-apply scorer remediations) — encodes the within-appetite `4` by hand; noted as out of scope above.
- **ADR-052** (Behavioural tests default) — the confirmation fixtures are behavioural.
- **RISK-POLICY.md** § Risk Appetite — the authoritative appetite source this gate now reads.
- **JTBD-002**, **JTBD-003**, **JTBD-202** — personas whose needs drive this decision.
