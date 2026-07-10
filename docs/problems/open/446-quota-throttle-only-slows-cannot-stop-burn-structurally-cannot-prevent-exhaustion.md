# Problem 446: Quota-pace throttle's glide is too weak to hold the pace line — a real hard weekly-limit stop occurred with the throttle running; strengthen the glide (deficit response + much larger cap)

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

### Confirmed root cause (quantified by simulation, 2026-07-10)

Sleep-and-allow cannot stop burn (facts 1–3 above). Quantified: a per-call sleep caps *sustained* burn at `burn_per_call / (call_interval + cap)`. With the **real observed cadence — median 85s between tool calls (this session's transcript, n=295 gaps)** — and a heavy session, the Release-1 60s cap held sustained burn far ABOVE the weekly pace line (~0.57 %/hr = 95 %/168h), so usage drifted steadily to 100 %. The `cap·(1−budget/time_left)` response curve is also too gentle (≈19s sleep at 40 %-used/20 %-elapsed when it needed to be near the cap). The cap being a small constant (60s) is the primary defect; the gentle curve compounds it.

**Simulation (deficit-glide, weekly window, 85s cadence, 5pp headroom):** a fixed cap only DELAYS exhaustion, it does not prevent it —

| unthrottled exhausts in | fixed 60s | fixed 300s | fixed 600s | self-calibrating (ceil 600s) |
|---|---|---|---|---|
| 60h (1.7 %/hr) | 99h | 167h | glides (98 %) | **glides (95 %)** |
| 40h (2.5 %/hr) | 66h | 160h | glides | **glides (95 %)** |
| 30h (3.3 %/hr) | 50h | 127h | 165h | **glides (95 %)** |
| 20h (5 %/hr, extreme) | — | 86h | 148h | 154h (still exhausts) |

The decisive finding: **self-calibrating** (measure actual burn from the cache delta, sleep exactly enough to hit the *remaining sustainable rate* `(95−used)/hours_left`) holds usage flat on the line and glides to the weekly reset wherever the required per-call sleep fits under the ceiling. Holding the line needs 166s/call (light) → 667s/call (extreme); a hook cannot sleep past its timeout (default 600s) without failing open. So self-calibrating glide + a 600s ceiling covers realistic heavy burn; only sustained >5 %/hr for days still exhausts (the residual below — a sleep-based throttle cannot fix it; only a block could, and a block was declined 2026-07-10).

The simulation script + full output are preserved in the session transcript (2026-07-10) and are reproducible from the parameters above.

### Fix direction — STRENGTHEN THE GLIDE, no hard stop (user direction 2026-07-10: "I'm not asking for a complete stop. The glide didn't work.")

ADR-093's "never blocks / slow, don't jerk" tenet STANDS. The defect is that the glide was too WEAK to hold the line, not that slowing is wrong. The simulation above selected the mechanics:

1. **Self-calibrating sleep (supersedes the fixed-cap deficit curve).** Each firing measures the actual burn since the last firing (Δused / Δt from the cache), computes the remaining sustainable rate `safe = (100 − headroom − used) / hours_left`, and sleeps exactly enough to bring the current burn rate down to `safe`: `S = interval · (current_rate/safe − 1)`. This holds usage flat on the pace line for ANY burn intensity (proven in the sim: peak 95%, glides), instead of a fixed curve that only delays exhaustion.
2. **Ceiling = the hook timeout (~600s).** `S` is clamped to a ceiling below the hook's `timeout` (set `timeout: 600` in hooks.json) so the sleep always completes — never killed, never fails open. Configurable via `max_sleep_s` (ADR-098); the ceiling is a safety bound, not the primary lever (the self-calibration is).
3. **Continuous correction** — fires every call; fail-open on ERRORS (missing/malformed cache, no jq); kill-switch (`WR_QUOTA_THROTTLE_DISABLE=1`) unchanged.

**Known residual (flagged, not covered — user chose no hard stop):** holding the line needs up to ~667s/call under sustained >5 %/hr burn, which exceeds any sub-timeout sleep — so the extreme case (burning most of a week's budget in ~a day, for days) still exhausts. No sleep-based throttle can fix it; only a deny/block could, and a block was declined 2026-07-10. The self-calibrating glide covers all realistic heavy burn (the ≤3.3 %/hr band that caused the observed exhaustion).

This is a mechanics correction to ADR-093 (self-calibrating sleep + ceiling), NOT a philosophy change — still mechanical, slow-not-block, fail-open. It also needs the producer to write a monotonic `written_at`/usage so Δ can be measured (the flat cache already carries usage; add the read-delta in the hook).

## Dependencies

- **Composes with**: **P160** (ship quota-pacing surface — this is a defect in its Release-1 fix), **P443** (lineage). The distribution fix (P160/P443) and this correctness fix are independent.
- **Blocks**: the in-flight `@windyroad/cruise` extraction (STORY-042/043, RFC-046 Release 2) should ship the CORRECTED throttle, not the broken one — fix rides the same build.

## Related

- **STORY-039** — the shipped Release-1 throttle carrying the defect.
- **ADR-093** — the mechanics to amend (never-block → deny-at-the-line).
- **RFC-046** — the shipping RFC; the corrected hook lands in `@windyroad/cruise`.
- **JTBD-010** — the job this defeats (sustain quota; never hard-stop mid-flight).
- Verified platform facts: Claude Code hooks docs — PreToolUse fail-open-on-timeout + deny mechanism (2026-07-10).
