# Problem 446: Quota-pace throttle only SLOWS burn (sleep-and-allow), cannot STOP it — structurally incapable of preventing the exhaustion it exists to prevent; must DENY at the budget line

**Status**: Open
**Reported**: 2026-07-10
**Priority**: 20 (Critical) — Impact: 5 (Catastrophic — the feature's entire purpose is defeated; a real hard weekly-limit stop occurred mid-work WITH the throttle installed and running) × Likelihood: 5 (Certain — observed 2026-07-09) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — the hook change is small (flip one branch from sleep-and-allow to deny) + amend ADR-093 + tests; folds into the in-flight cruise build.
**JTBD**: JTBD-010
**Persona**: developer

## Description

The mechanical quota-pace throttle (STORY-039 / ADR-093, shipped Release 1) is a PreToolUse hook that, when ahead of pace, **sleeps up to a 60s-per-firing cap and then ALLOWS the tool call**. This only *slows* burn — it never *stops* it. So a heavy session whose burn rate stays above the safe rate even at one call per 60s keeps consuming and sails straight through to 100% → a hard rate-limit stop. On 2026-07-09 the maintainer hit a hard **weekly** rate-limit stop mid-work with the throttle installed and running — the exact catastrophic outcome the throttle exists to prevent.

**Why sleep-and-allow is structurally incapable of the guarantee (verified against Claude Code docs, 2026-07-10):**

1. **PreToolUse hooks fail OPEN on timeout.** If the hook runs past its timeout it is killed and *the tool call proceeds anyway*. So "sleep long enough" past the timeout does NOT stop the call — it lets it through.
2. **Sleep only delays; it never blocks.** The only way a hook actually stops a call is `permissionDecision: "deny"` (or exit 2).
3. **A finite per-call sleep cannot floor burn at zero.** The hook's only lever is latency per call, which caps throughput at ~1 call / sleep. Burn floors at (burn-per-call / sleep); driving that to zero — which is what "never exhaust" requires at the budget line with window-time still remaining — needs sleep → ∞, i.e. a block. "Slow enough" at the boundary IS "stop."

So the "NEVER blocks" tenet in ADR-093 — intended as politeness / fail-open safety — is the bug: a throttle that never blocks cannot guarantee non-exhaustion.

## Symptoms

- A hard 5h or weekly rate-limit stop occurring while the throttle is installed and active.
- Burn crossing the reserved-headroom line (e.g. past 95% weekly with the 5pp headroom) instead of being held at it.

## Impact Assessment

- **Who**: developer (every user of the throttle, incl. the maintainer). Adopters (once distribution is fixed per P160/P443) would inherit a throttle that does not deliver its core promise.
- **Frequency**: whenever burn rate exceeds what a 60s-capped sleep can offset — routine in heavy AFK sessions.
- **Severity**: Catastrophic — the entire value proposition (never hard-stop mid-flight) fails.

## Root Cause Analysis

### Confirmed root cause

Sleep-and-allow cannot stop burn (facts 1–3 above). The `budget ≤ 0 → safe_rate 0 → sleep CAP → ALLOW` branch of the glide math is the specific defect: at the reserved line it naps 60s and then lets the burn through.

### Fix direction (to be ratified via ADR-093 amendment)

- **Soft zone (ahead of pace, budget remains):** keep slowing — sleep the corrected glide amount. This is the dominant behaviour and preserves the "slow, don't jerk" philosophy.
- **Hard zone (used ≥ 100 − headroom for a window, window not yet reset):** **DENY** (`permissionDecision: deny`, informative reason) instead of sleep-and-allow — hold tool calls until the window eases back / resets. Guarantees burn cannot cross the reserved line → the account never reaches the 100% hard limit; the weekly headroom (5pp) is preserved for non-Code surfaces.
- **Override:** the existing kill-switch (`WR_QUOTA_THROTTLE_DISABLE=1`) lets the user push through deliberately.
- **Fail-open preserved on ERRORS** (missing/malformed cache, no jq) — deny only when correctly, confidently over the reserved line.

This amends ADR-093's "NEVER blocks / NEVER a hard stop from the throttle" tenet: the throttle now imposes a *self-controlled, headroom-preserving, overridable* stop precisely to prevent the *uncontrolled, total, account-wide* hard stop.

## Dependencies

- **Composes with**: **P160** (ship quota-pacing surface — this is a defect in its Release-1 fix), **P443** (lineage). The distribution fix (P160/P443) and this correctness fix are independent.
- **Blocks**: the in-flight `@windyroad/cruise` extraction (STORY-042/043, RFC-046 Release 2) should ship the CORRECTED throttle, not the broken one — fix rides the same build.

## Related

- **STORY-039** — the shipped Release-1 throttle carrying the defect.
- **ADR-093** — the mechanics to amend (never-block → deny-at-the-line).
- **RFC-046** — the shipping RFC; the corrected hook lands in `@windyroad/cruise`.
- **JTBD-010** — the job this defeats (sustain quota; never hard-stop mid-flight).
- Verified platform facts: Claude Code hooks docs — PreToolUse fail-open-on-timeout + deny mechanism (2026-07-10).
