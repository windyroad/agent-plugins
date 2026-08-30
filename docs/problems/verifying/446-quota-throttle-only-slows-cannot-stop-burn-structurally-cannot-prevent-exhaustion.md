# Problem 446: Quota-pace throttle's glide is too weak to hold the pace line — a real hard weekly-limit stop occurred with the throttle running; strengthen the glide (deficit response + much larger cap)

**Status**: Verification Pending (transitioned 2026-07-15 — fix verified released: cruise 0.3.5 on npm + installed cache, all three controller dimensions present in the shipped hook, ADR-093 amendment landed; awaiting live verification of the deficit-aware controller)
**Reported**: 2026-07-10
**Priority**: 20 (Critical) — Impact: 5 (Catastrophic — the feature's entire purpose is defeated; a real hard weekly-limit stop occurred mid-work WITH the throttle installed and running) × Likelihood: 5 (Certain — observed 2026-07-09) — derived at capture per Step 4a
**Origin**: internal
**Effort**: M — the hook change is small (flip one branch from sleep-and-allow to deny) + amend ADR-093 + tests; folds into the in-flight cruise build.
**WSJF**: 20.0 — (20 × 2.0) / 2 (Known Error ×2.0; Severity 20 ≥ 17 = Tier 0 Critical-bypass per ADR-076)
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

## Second dimension — the glide OVER-brakes when behind the pace line (position-unaware controller), observed 2026-07-13

The RCA above fixes "glide too WEAK to hold the line." Live `/wr-cruise:status` telemetry on 2026-07-13 surfaced the complementary failure: the self-calibrating controller (the P446 mechanism, shipped in `@windyroad/cruise`) **over-brakes when you are well behind the pace line**. Observed: 5h window 8% used vs 17% pace (9pp behind), 7d window 11% used vs 22% pace (11pp behind) — clear surplus, days of runway — yet the throttle was sleeping 25s/call.

**Mechanism**: the over-rate test (`quota-pace-throttle.sh` lines 110–121) is purely a RATE comparison: it brakes whenever measured burn `Δused/dt` exceeds `safe = (100−headroom−used)/(reset−now)` — the remaining budget spread evenly over ALL remaining window time. It gives **no credit for accumulated position** (the surplus banked by being under the linear pace line). On a 7-day window `safe` is ~0.6%/hr, so ANY genuine working burst (~13%/hr) trips it, even with 84% budget and 5.3 days left. Being behind pace bumps `safe` only marginally (larger remaining budget), nowhere near enough to stop the over-brake.

**Fix direction (a control-law change, not a re-tune)**: make the controller **deficit/surplus-aware**, not pure instantaneous-rate. While usage is under the linear pace line, the banked slack should be spendable — let bursts draw it down freely (little/no brake); engage braking only as usage approaches the line, hard at/over it. This still guarantees non-exhaustion (at the line the sustainable rate holds the glide to reset) but stops the pointless braking when there is a large surplus and a long horizon. Candidate shapes (a genuine ≥2-option design decision — confirm before building per ADR-074): (a) token-bucket / surplus-drawdown allowance above `safe`; (b) PI controller adding an integral (position) term to the current proportional (rate) term; (c) brake magnitude scaled by `(used − linear_pace)` deficit. One deficit-aware law fixes BOTH dimensions of this ticket (too-weak-at-the-line AND too-aggressive-when-behind).

**Sibling reporter bug (cheap, separable)**: `cruise-status.sh` prints `Throttle now: … braking (you're ahead of pace)` whenever the injected sleep is >0 — it infers "ahead" from sleep>0, not from actual position, so it flatly contradicts the "Npp behind" line it prints above. The label must derive from real position (behind/at/ahead), not from whether a sleep is active.

### Third dimension — sticky recovery (the injected sleep unwinds too slowly), fixed 2026-07-13

Surfaced live 2026-07-13: `/wr-cruise:status` sat "Waiting…" for 2m+ because the throttle was sleeping on the status command's own tool call, using a stale per-call sleep (`cur_s=88`) ramped during the over-brake window. Root cause of the *stickiness*: (a) the ease-down was gradual (`cur_s*2/3−10`, one firing at a time) AND each firing sits behind its own sleep, so a high `cur_s` unwinds over minutes; (b) the re-baseline / too-soon early-return paths re-slept the stored `cur_s` unconditionally, without re-checking position. A session that had banked surplus (fell behind pace) stayed slow long after conditions said "don't brake."

**Fix (shipped 0.3.5, user-pinned Option A via AskUserQuestion):** asymmetric recovery — when a window is behind pace the controller drops `cur_s` to 0 **at once** (not eased); the position gate is hoisted so the early-return paths respect it and never re-sleep a stale value while behind pace. Dropping braking cannot cause exhaustion, and it re-engages the instant a window is over pace again (ramp-up unchanged). Immediate manual reset for a running session: clear `$TMPDIR/wr-quota-throttle-*`.

**ADR-093 amendment — LANDED 2026-07-13 (commit 4ca91d5e).** ADR-093's normative Mechanics now records all three shipped realities — (1) the deficit-aware position gate, (2) the feedback controller that replaced the one-shot `S=interval·(r/safe−1)` formula, (3) the asymmetric immediate-recovery law — with the numeric constants surfaced per P444, the old formula retired-in-place with forward pointers, and non-exhaustion / ceiling / fail-open unchanged. Architect + JTBD PASS; oversight re-ratified 2026-07-13 via AskUserQuestion Confirm (P357). No amendment work remains.

## Fix Strategy

The fix shipped through RFC-046's `@windyroad/cruise` vehicle across two patch releases: 0.3.4 (deficit-aware position gate — brake only when over-rate AND at/over the linear pace line; plus the `/wr-cruise:status` position-label fix) and 0.3.5 (asymmetric instant recovery — `cur_s` drops to 0 the moment a window is behind pace; re-baseline/too-soon paths respect the position gate). The feedback controller replacing the fixed-cap one-shot formula landed in the same series. ADR-093 amendment recording all three mechanics: commit 4ca91d5e (2026-07-13).

**Release vehicle**: .changeset/cruise-instant-recovery.md (drained at the 0.3.5 publish; sibling .changeset/cruise-deficit-aware-throttle.md drained at 0.3.4)

## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-044 | STORY-044: See what cruise is doing — a status/telemetry skill | in-progress |

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-046 | verifying | Quota-pace throttle — mechanical PreToolUse pacing, extracted into `@windyroad/cruise` |

## Fix Released

Released in `@windyroad/cruise` 0.3.4 + 0.3.5 (npm-published; installed plugin cache at 0.3.5 as of 2026-07-15). The strengthened glide is deficit-aware, feedback-driven, and recovers instantly when behind pace. Awaiting user verification — the observable acceptance signal is a heavy session gliding to the window reset at the headroom line (≤95% weekly) with no hard rate-limit stop, and no over-braking while behind pace.

Exercise evidence from the releasing/verifying sessions (2026-07-15 in-session checks):

- `npm view @windyroad/cruise versions` lists 0.3.5; installed cache `~/.claude/plugins/cache/windyroad/wr-cruise/0.3.5/` present.
- Shipped `hooks/quota-pace-throttle.sh` (0.3.5 cache) verifiably carries all three fix dimensions: deficit-aware position gate (brake only at/over the linear pace line; banked surplus spendable), feedback controller ramping per-call sleep toward burn=safe, and asymmetric instant recovery (`cur_s=0` at once when behind pace, incl. re-baseline/too-soon paths).
- ADR-093 amendment recording the three mechanics: commit 4ca91d5e, oversight re-ratified 2026-07-13.
- Known residual stands as documented: sustained >5 %/hr burn for days still exhausts (no sleep-based throttle can cover it; a block was declined 2026-07-10).

## Dependencies

- **Composes with**: **P160** (ship quota-pacing surface — this is a defect in its Release-1 fix), **P443** (lineage). The distribution fix (P160/P443) and this correctness fix are independent.
- **Blocks**: the in-flight `@windyroad/cruise` extraction (STORY-042/043, RFC-046 Release 2) should ship the CORRECTED throttle, not the broken one — fix rides the same build.

## Related

- **STORY-039** — the shipped Release-1 throttle carrying the defect.
- **ADR-093** — the mechanics to amend (never-block → deny-at-the-line).
- **RFC-046** — the shipping RFC; the corrected hook lands in `@windyroad/cruise`.
- **JTBD-010** — the job this defeats (sustain quota; never hard-stop mid-flight).
- Verified platform facts: Claude Code hooks docs — PreToolUse fail-open-on-timeout + deny mechanism (2026-07-10).
## Verification-period evidence — 2026-07-15 evening (5h-window session-limit hit with throttle active)

Observed during the 2026-07-15 work-problems loop: a **5-hour-window session limit** was hit at ~20:08 (reset 20:30) WITH the 0.3.5 throttle installed, cache fresh, and braking confirmed active afterwards (25s/call per /wr-cruise:status; 7-day window held exactly on the pace line at 56% vs 57% — the primary job working). Contributing mechanics, in order:

1. **Concurrency gap (NEW — not in the three shipped dimensions or the recorded residual)**: 3-4 concurrent sessions (this orchestrator + its iter subprocess + two other projects' AFK loops) each computed per-call braking from the shared cache as if alone; collective burn was N× a single throttled session while braking stayed per-session. The control law has no concurrency term.
2. **Position gate spending banked surplus (by design)**: the evening started behind pace; the asymmetric-recovery gate (third dimension, user-pinned Option A) correctly let the burst draw the surplus down at zero brake until usage crossed the line — close to the window edge, where per-call sleeps cannot stop a short-horizon overshoot.
3. **Documented residual**: sustained multi-session burn is the "no sleep-based throttle can fix it" case recorded at fix time (deny/block declined 2026-07-10).

Impact was the benign case: 22 minutes of stall (one iter died pre-work, $2.44, retried clean), not the lost-week weekly-window case. Disposition: this is verification-period evidence, NOT a regression of the three shipped dimensions (each behaved as designed). The concurrency gap is uncovered scope — route at the next interactive review: absorb into this ticket as a fourth dimension pre-close, or capture as a sibling (the P448/P389/P361-style cluster call).
