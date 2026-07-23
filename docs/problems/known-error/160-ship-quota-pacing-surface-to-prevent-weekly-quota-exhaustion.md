# Problem 160: Ship quota-pacing surface to prevent weekly-quota exhaustion — advisory or blocking nudge when burn rate exceeds sustainable pace, so users retain Claude tokens for non-Claude-Code surfaces (chat, cowork) for the full week

**Status**: Known Error (reopened 2026-07-07 — verification FAILED per user audit; see § Verification inadequate). Keeps **Severity 20** (NOT re-rated down) because the pain is felt in full by **everyone who is not the one hand-wired machine** — the shipped throttle protects a single maintainer setup; every adopter (and any other maintainer machine) is still fully exposed to mid-window quota hard-stops. The adopter-inert gap is the *reason* the original severity still holds, not a reason to lower it (user direction 2026-07-07).
**Reported**: 2026-05-03
**Priority**: 20 (Critical) — Impact: Significant (4) x Likelihood: Almost certain (5) — RE-RATED UP 2026-07-05 (was Minor 2): hitting the quota does NOT just "wait for reset" — it HALTS work mid-loop, breaks the running `/wr-itil:work-problems` loops, and forces an effortful manual resume. User-pinned TOP PRIORITY 2026-07-05.
**Origin**: internal
**Effort**: XL — new plugin or sibling surface; ADR required for policy semantics (advisory vs blocking, scope boundary against existing statusline read-surface, AFK-orchestrator interaction); cross-cutting with hooks (PreToolUse cadence gate?), statusline (already reads quota state — see `~/.claude/statusline-command.sh`), and a quota-policy schema analogous to `RISK-POLICY.md`. Multi-day, cross-package work.

**WSJF**: (20 × 2.0) / 8 = **5.0** (Known Error multiplier 2.0; Severity 20 ≥ 17 = **Tier 0 Critical-bypass** — sorts above all tiers regardless of WSJF per ADR-076)

> Surfaced 2026-05-03 by user direction citing live status-line evidence: `5h: 23% ahead (resets 45m)` and `7d: 36% behind (resets 5d 17h)` — burning weekly quota at ~1.5x sustainable pace. Confirmed by James Nowland (cross-user) reporting same pain class: "blown through my AI with code" leaving no tokens for important text-based emails. Quota exhaustion is a cross-surface failure (Claude Code consumes; chat + cowork starve) that the existing statusline diagnostic surface measures but does not regulate.

## Description

Claude's weekly token quota is shared across **all** Claude surfaces the user has authenticated to from a single account — Claude Code, claude.ai chat, Anthropic Cowork, and any custom API-backed tools. The Windy Road plugin suite includes governance surfaces that intentionally drive up agent verbosity (architect review, JTBD review, risk-scorer pipeline, retrospective passes, hook injection on every prompt — see ADR-038 progressive-disclosure context budget) which is correct for **per-session** quality but accumulates **per-week** quota burn that the user cannot see ahead-of-time.

The status-line surface (already wired via `statusLine.command` in `~/.claude/settings.json` → `~/.claude/statusline-command.sh`) **measures** the burn rate against the 5-hour window and the 7-day window — the screenshot evidence shows the format `5h: <bar> <pct> ahead/behind (resets <N>) | 7d: <bar> <pct> ahead/behind (resets <N>)`. This is a **diagnostic** surface — it tells the user what already happened. It does **not** regulate, advise, or constrain future tool-call cadence to keep the weekly burn within the sustainable pace.

The gap: a **prescriptive** layer that converts the existing diagnostic data into governance — analogous to how `RISK-POLICY.md` converts pipeline impact/likelihood into commit gates, this surface would convert quota burn rate into operational guidance ("you're burning at 1.5x sustainable; defer the AFK loop / switch to a smaller model / batch the work tomorrow"). Critically, the surface must be **cross-tool aware** — the regulation must reflect that the user wants to preserve quota for chat + cowork, not just for the next Claude Code session.

This is a **product capability gap**, not a bug. There is no existing plugin in the `@windyroad/*` suite addressing it, and no upstream Claude Code feature (per current release notes) provides it. It is captured here as a problem ticket per the project's pattern (problems = capability gaps + bugs together; see siblings P155 / P156 / P157 for the "ship X" backlog framing).

**Why this matters now** (load-bearing on existing JTBDs):

- **JTBD-001 (enforce governance without slowing down)** — running out of tokens mid-week is the maximum form of "slowed down": the agent stops working at all. Governance gates that drive quota burn (architect, JTBD, risk-scorer running on every edit + every commit) MUST be tunable against weekly cadence, otherwise the governance itself starves the user out of the workflow it is supposed to protect.
- **JTBD-006 (progress the backlog while AFK)** — AFK orchestrators (`/wr-itil:work-problems`, `/loop`) are the heaviest single class of quota consumer. An overnight AFK loop can consume the user's weekly quota in one run if uncapped. Without a pacing surface, the user can't safely set an AFK loop and walk away — the loop might land them at zero tokens for the rest of the week.
- **Cross-user evidence** — James Nowland (different solo-developer persona instance) reports the same pain class independently. This is not a single-user idiosyncrasy.

## Symptoms

- Status-line shows `7d: <pct>% behind` reaching double-digits early in the week with no surfacing of the implication (will run out before reset).
- Mid-week token exhaustion forcing the user to abandon non-Claude-Code surfaces (chat, cowork) for which they had not budgeted the burn.
- AFK orchestrator runs (e.g. `/wr-itil:work-problems` 16-hour overnight loops) silently consume large fractions of weekly quota with no in-loop pacing check.
- User cannot ask "if I run this loop overnight, will I have tokens left for chat tomorrow?" — no policy surface answers this question.
- Cross-user pain (James Nowland's report) shows this is a class-of-user problem, not a one-off.

## Workaround

Current state — manual self-pacing:

1. User glances at the status-line periodically and self-throttles by stopping high-cost work (AFK loops, expensive reviews) when the 7-day bar shows behind.
2. User chooses model manually (Opus → Sonnet → Haiku) to trade quality for tokens when burn rate is high.
3. User defers non-essential governance work (retrospectives, audits) to early in the week when quota headroom is high.
4. User accepts running out of tokens as a recoverable failure mode (wait until reset).

All four sub-workarounds depend on the user remembering to check and being present to act. They fail completely during AFK loops (no human in the loop to see the status-line; no `/loop` mechanism to halt-on-budget). They also fail on shared accounts where multiple humans + multiple agents draw from the same quota pool.

## Impact Assessment

- **Who is affected**: Solo-developer (primary — manages own quota across CC + chat + cowork); AFK orchestrator class (primary failure mode — long-running unattended loops); plugin-user (indirect — adopters of `@windyroad/*` plugins inherit governance surfaces that drive quota burn without a counter-balancing pacing surface, so adopters experience the same exhaustion class without being able to tune it independently).
- **Frequency**: Continuous — present every week; failure mode (mid-week exhaustion) appears multiple weeks per month based on observed status-line data.
- **Severity**: Minor (per RISK-POLICY.md impact 2 — "dev tooling affected; published packages and installed plugins unaffected") — this is a missing-feature framing; nothing in the shipped plugin suite is broken. Re-rate to Significant (4) if the gap blocks an adopter from using `@windyroad/*` plugins because their governance surfaces consume too much quota.
- **Likelihood**: Almost certain (per RISK-POLICY.md likelihood 5 — "Known gap, no controls in place") — explicitly observed, no plugin or upstream feature regulates this today.
- **Analytics**: Live status-line snapshot 2026-05-03 — `5h: 23% ahead (resets 45m)`, `7d: 36% behind (resets 5d 17h)`. Cross-user corroboration: James Nowland message attached to ticket creation — independently observed, same pain class.

## Root Cause Analysis

### Preliminary Hypothesis (fix-shape sketch — design questions deferred to architect review)

The fix is a new pacing surface, not a tweak to an existing one. Open design questions the architect review must resolve:

**Q1 — Plugin home**: new dedicated plugin (`@windyroad/cruise`?) vs sibling skill / hook in an existing plugin (`@windyroad/itil` since it owns the policy-pattern; `@windyroad/risk-scorer` since it owns the gate-pattern; or nowhere — surface as a global hook bundled with `accessibility-agents`-style global config). New plugin is the cleanest separation but adds release surface; sibling skill is cheaper but couples concerns.

**Q2 — Read surface**: what does the pacing layer read for burn-rate state? The existing statusline reads quota state (it must — it renders the bars). Either:
- (a) The pacing surface re-implements the read (duplicates the statusline's source-of-truth lookup).
- (b) The pacing surface reads a shared cache that the statusline writes (introduces a coupling).
- (c) The statusline becomes the single source of truth and the pacing surface reads its rendered output (parses the bar text — brittle).

**Q3 — Enforcement mode**: advisory (warn + continue) vs blocking (gate + require ack) vs adaptive (auto-throttle: switch model, defer expensive ops). Likely tiered like RISK-POLICY.md appetite bands:
- Within sustainable pace (≤ 100% of weekly): silent.
- Approaching limit (100–115%): advisory message in agent output.
- Above limit (115–130%): blocking gate analogous to risk-scorer commit-gate; requires explicit user ack to proceed with high-cost ops (AFK loops, expensive reviews).
- Critical (> 130% with > 2 days until reset): hard halt — refuse to start new AFK loops; advise switch to smaller model.

**Q4 — Policy schema**: a `QUOTA-POLICY.md` analogous to `RISK-POLICY.md`? Per-user customisable thresholds (some users only ever use Claude Code; others split across 3 surfaces and need stricter pacing)? Per-org / per-account schema for shared accounts?

**Q5 — AFK-orchestrator integration**: how does `/wr-itil:work-problems` Step 6.5 (release cadence) interact with quota pacing? Likely a sibling Step 6.6 (or a fold into 6.5) that checks the pacing surface before starting another iteration. If pacing says "above appetite", halt the loop and emit a halt-with-report per ADR-013 Rule 6.

**Q6 — Cross-tool awareness**: does the pacing surface read state for chat + cowork burn, or only Claude Code? If only CC, the user must self-budget the chat+cowork share. If cross-tool, the surface needs an account-wide quota reader (likely an Anthropic API call against the user's account — non-trivial auth surface).

**Q7 — Upstream coordination**: should this be reported upstream to Claude Code as a feature request (per `/wr-itil:report-upstream`) before building? The existing statusline is already an upstream-supplied surface; quota pacing might be on the Anthropic roadmap. External-root-cause detection in Step 7 of this skill should fire the upstream-report prompt when this ticket transitions to Known Error.

### Investigation Tasks

- [x] Architect review — Q1–Q4 resolved by ADR-093 (born `human-oversight: unconfirmed`, ratification pending): Q1 plugin-home = shared hook synced across all 7 plugins (`packages/shared/hooks/`); Q2 read-surface = the statusline-written cache `~/.claude/quota-state.json` (option b — the ONLY surface Claude Code passes `.rate_limits.{five_hour,seven_day}` to; PreToolUse hooks don't receive it directly); Q3 enforcement = mechanical calculated-sleep (NOT advisory — per the 2026-07-05 correction); Q4 schema = inline headroom constants (5pp weekly, 60s/firing cap), no separate QUOTA-POLICY.md needed for the first slice.
- [x] JTBD review — serves JTBD-001 (governance must not starve the user of tokens) + JTBD-006 (AFK loops self-throttle to land at reset with headroom, so "set a loop and walk away" holds) + JTBD-302 (adopters get the same pacing via the synced hook + `QUOTA-THROTTLE-SETUP.md`).
- [x] Investigate `~/.claude/statusline-command.sh` — done: it is the only surface Claude Code passes rate-limit percentages + `resets_at` to. Wired it to write `~/.claude/quota-state.json` as the throttle's read source (Q2 option b).
- [x] Investigate Anthropic upstream surface — done: no `Anthropic-Account-Quota` header / `claude usage` CLI / account endpoint is available to a PreToolUse hook; the statusline is the only rate-limit-bearing surface, hence the statusline-cache design.
- [ ] `/wr-itil:report-upstream` to Claude Code with a native-quota-pacing feature request (follow-on; does NOT block verification — the downstream throttle already ships).
- [x] Implement the agreed design — SHIPPED as `packages/shared/hooks/quota-pace-throttle.sh`, synced to all 7 plugins, released (itil 0.57.1 + siblings). Reframed from the superseded XL "new plugin + advisory" scope to the shipped M "calculated-sleep PreToolUse hook" per the 2026-07-05 corrections.
- [x] ~~Wire AFK orchestrator between-iter integration (Q5)~~ — SUPERSEDED by Correction 2: the throttle is a **frequently-firing PreToolUse hook across ALL work** (interactive + AFK), which subsumes the narrower between-iter checkpoint.
- [x] Behavioural bats — SHIPPED: `packages/shared/test/quota-pace-throttle.bats`, 8/8 green (ahead-of-pace sleeps capped; behind-pace fast no-op; tighter-window-wins; weekly-headroom; fail-open on missing/malformed cache; recent-check no-op; never emits deny).
- [ ] Document in BRIEFING.md as the token-budget analogue of ADR-038's context budget (follow-on; does NOT block verification).
- [ ] **Adopter-inert producer gap (folded from user audit 2026-07-07).** The throttle ships the CONSUMER (`quota-pace-throttle.sh` hook, synced ×7) but NOT the PRODUCER of its data source. `~/.claude/quota-state.json` is written ONLY by the user's statusline (`~/.claude/statusline-command.sh`, lines 223-226) — Claude Code passes `.rate_limits` to no other surface. The producer exists only as a copy-paste snippet in `QUOTA-THROTTLE-SETUP.md`; there is no first-run nudge, no plugin-contributed statusline, and no staleness guard. **Out of the box an adopter's hook fail-opens forever → zero throttling.** It works for the maintainer solely because the statusline was hand-wired. Fix options: ship a plugin-contributed statusLine, OR a SessionStart absent-cache nudge (already a deferred RFC-046 slice), OR both. This is the "solved only for me" gap.
- [ ] **Own-plugin extraction (folded from user audit 2026-07-07).** Quota-pacing is a cross-cutting, general-purpose capability with nothing to do with governance, yet it ships as a hook synced verbatim across 7 governance plugins whose canonical home (`packages/shared/`) is not itself installable. A proper JTBD/USM (see P443) shows it is independent of the other user-story-maps → it belongs in its **own** plugin. **RATIFIED 2026-07-07: extract to `@windyroad/cruise`** (user confirmed — the USM shares no backbone with the two existing JTBD-008 decompose-a-fix maps). An adopter who wants only quota-pacing should not have to install a governance plugin, and the capability should not be maintained as 7 synced copies.

## Dependencies

- **Blocks**: (none directly — but every governance surface that drives token burn (architect, JTBD, risk-scorer, retrospective) is **regulated by** this surface once shipped, so all of those would have a cross-reference once the policy schema lands)
- **Blocked by**: (none — the gap is independently buildable; statusline surface already exists as a read source)
- **Composes with**: P027 (closed — manage-problem work-flow expensive; that solution reduced per-invocation cost but didn't introduce weekly-cadence regulation); P091 (open — session-wide context budget from plugin hook stack; sibling concern at the per-session axis vs P160's per-week axis); P099 (verifying — BRIEFING.md unbounded-grow; sibling progressive-disclosure pattern); ADR-038 (progressive-disclosure context budget — P160 is the token-budget analogue).

## Related

- `~/.claude/settings.json` → `statusLine.command` → `~/.claude/statusline-command.sh` — existing diagnostic read surface.
- Status-line evidence (2026-05-03): `5h: 23% ahead (resets 45m) | 7d: 36% behind (resets 5d 17h)`.
- Cross-user corroboration: James Nowland message attached to ticket creation (independently observed pain class).
- `RISK-POLICY.md` — pattern template for the proposed `QUOTA-POLICY.md` schema (Q4).
- ADR-038 (progressive-disclosure context budget) — the per-session analogue of the per-week regulation P160 proposes.
- ADR-013 (six-rule AskUserQuestion + AFK-fail-safe contract) — Rule 6 (AFK fail-safe) is the canonical halt-with-report pattern the AFK-orchestrator integration (Q5) would reuse.
- ADR-042 (auto-apply scorer remediations) — pattern template for the adaptive-enforcement mode in Q3 (auto-throttle = scorer-style auto-apply).
- P155 / P156 / P157 — sibling "ship X" backlog framing for new plugin capability gaps.
- JTBD-001 (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — load-bearing dependency.
- JTBD-006 (`docs/jtbd/solo-developer/JTBD-006-work-backlog-afk.proposed.md`) — load-bearing dependency.
- JTBD-302 (`docs/jtbd/plugin-user/JTBD-302-trust-readme-describes-installed-behaviour.proposed.md`) — adopter-side concern (installed governance surfaces must not silently exhaust user quota).

## New evidence + ratified solution direction (2026-07-05)

**User-pinned TOP PRIORITY.** Verbatim: *"hitting the quota limit has negative issues beyond having to wait for the tokens to reset. It also stops work midway, which needs effort to resume later, especially the work-problems loop. For instance, I'm going to have to restart all the various work-problems loops after 11pm, but I would like to go to bed, but that would mean wasting time between now and the morning. So I have to stay up, which sucks."*

Live evidence (screenshot 2026-07-05): `You've hit your session limit · resets 11pm (Australia/Sydney)`; status-line `5h: 100% behind (resets 29m)`, `7d: 31% behind (resets 5d 16h)`. The session limit stopped work mid-flight.

**The stop is the harm, not the wait.** Three compounding costs beyond "wait for reset":
1. **Mid-loop halt** — the AFK `/wr-itil:work-problems` loops break partway through an iter; in-flight subprocess work strands (ADR-019 Step 0 dirty-state recovery cost on resume).
2. **Effortful resume** — restarting all the loops after reset is manual work; state has to be re-established.
3. **Forced-waking / wasted-window** — the user can't safely set an overnight loop and go to bed: either stay up to babysit the reset (bad) or waste the hours between now and morning (bad). This is the JTBD-006 "set an AFK loop and walk away" promise breaking.

### Ratified solution direction (user, 2026-07-05) — AUTOMATIC PROPORTIONAL-WINDOW THROTTLE

An automatic throttle that **paces** the work so we never exceed the proportional share of quota for the current window. It is a **balancing act**: use as many tokens as possible WITHOUT hitting the quota (hitting it breaks the loops).

- **Rule**: at any point, cumulative usage must not exceed the fraction of the window elapsed. E.g. **1hr into a 5hr window → ≤20% of the 5h quota used**; **75% through the week → ≤70% of the weekly quota used** (leave headroom). Applies to BOTH windows simultaneously (the 5h window AND the 7d window) — pace against whichever is tighter.
- **Behaviour when ahead of pace** (burning too fast): the AFK loop (and any heavy work) should slow/pause/defer the next expensive unit until elapsed-time catches up to usage — rather than sprinting into the wall and hard-stopping mid-iter. A brief scheduled sleep-until-back-on-pace between iters is preferable to a hard quota-stop.
- **Behaviour when behind pace** (headroom available): run at full speed / spawn expensive iters freely.
- **Cross-window + cross-surface**: the weekly axis must leave headroom for non-Claude-Code surfaces (chat, cowork) — don't spend the whole week's quota in Claude Code.
- **Data source**: the status-line already reads the 5h/7d quota state (`~/.claude/statusline-command.sh`); the throttle converts that diagnostic into a pacing gate (a PreToolUse/between-iter cadence check + a `ScheduleWakeup`-style pace-sleep in the work-problems loop). Analogous to how `RISK-POLICY.md` converts impact/likelihood into commit gates — a `QUOTA-POLICY`-style pacing surface.

**Fix strategy**: this reframes P160's XL "new plugin" scope toward a concrete, prioritisable first slice — a between-iter pacing check in `/wr-itil:work-problems` (and `/loop`) that reads the window state and inserts a pace-sleep when usage% > elapsed%, so an overnight loop self-throttles to land the user at reset WITH headroom instead of hard-stopped mid-iter. Re-estimate Effort at build (the first-slice pacing gate is likely M/L, not the full XL cross-plugin surface).

### CORRECTION (user, 2026-07-05) — mechanical hook-calculated sleep, NOT advise/nudge

The ticket's original "advisory or blocking nudge" framing (title + Description) is **SUPERSEDED**. Verbatim user direction: *"it shouldn't advise or nudge, it should use hooks to calculate if a delay is needed and if so, sleep for that amount of time."*

The mechanism is **automatic and mechanical** — zero human decision, zero nudge:
1. A **hook** (between-iter in the AFK loop, and/or PreToolUse on expensive units) reads the current window state (5h + 7d usage% and elapsed%).
2. It **calculates** whether we are ahead of the proportional pace, and if so, **by how much** — i.e. the delay needed for elapsed-time to catch up to usage (`required_sleep = time until on-pace = f(usage%, elapsed%, window_reset)`), taking the tighter of the 5h / 7d windows.
3. If a delay is needed, it **sleeps for exactly that amount** (blocking the next expensive unit), then proceeds. If no delay is needed (behind pace, headroom available), it proceeds immediately at full speed.

So the loop self-throttles into an even burn that lands at each window's reset WITH headroom, instead of sprinting into a mid-iter hard-stop. No status-line glance, no "you're burning fast" message, no user-in-the-loop — the hook computes the sleep and takes it. This is the load-bearing design change: enforcement by calculated sleep, not surfacing by advisory.

### CORRECTION 2 (user, 2026-07-05) — a FREQUENTLY-FIRING HOOK across ALL work, not just work-problems iters

Verbatim: *"it shouldn't be just between work-problems iters. Other work too. It should fire on hooks quite frequently."*

Scope broadened: the throttle is NOT limited to the AFK `/wr-itil:work-problems` between-iter boundary. It is a **hook that fires frequently on ALL work** — interactive foreground sessions AND AFK loops alike. The natural carrier is a high-frequency hook event (e.g. **PreToolUse**, which fires before every tool call), so pace is checked continuously across every kind of work, not just at loop boundaries.

Mechanism per firing (unchanged calc, broader trigger): read the live 5h/7d window state → compute `required_sleep` (usage% vs elapsed% over the tighter window; 0 when behind pace/headroom) → if >0, **sleep that amount** before the tool call proceeds. When behind pace, it's a fast no-op check (no sleep) so it adds negligible latency; only when ahead-of-pace does it insert the calculated sleep. This paces the ENTIRE token burn evenly — every tool call self-throttles — so no work (loop or interactive) sprints into a mid-flight quota hard-stop.

Design note: PreToolUse-on-every-call means the check must be CHEAP (a fast read of the cached window state + arithmetic), with the sleep only on the ahead-of-pace branch. The between-iter work-problems call from Correction 1 remains as a coarser complementary checkpoint, but the load-bearing surface is the frequent hook.

### REFINEMENT 3 (user, 2026-07-06) — SMART GLIDE-PATH, not "sleep until back on the line"

Verbatim: *"with the pacing, we need to be smart. … we are currently well over the pace for our weekly quota. Instead of just stopping all usage for a few days, it should use some sort of smart algo, so it still lets us progress a bit, while getting back to the pace. It's like if you were doing a race and had to hit a pace, if you found out you were 20min ahead, you wouldn't just stop for 20min, you would instead slow down so that eventually you are back on pace. In our case that eventually has to be before the quota is consumed."* (Live evidence: `7d: 62% behind (resets 4d 23h)` — well over the weekly pace.)

**The defect in the first-slice algorithm**: the shipped v1 computed `sleep = (used% − elapsed%) × window / 100` capped at 60s. Because that raw catch-up is enormous (a 20pp weekly lead ≈ 1.4 days), the cap dominated → effectively **bang-bang**: a flat 60s sleep on every call while over pace, then zero once back on the ideal line. It slowed rather than fully stopped, but it (a) was not proportional (no smooth ease-off as it converged) and (b) aimed to snap back to the ideal `used% == elapsed%` line rather than glide to the reset.

**The fix — proportional glide-path controller** (shipped 2026-07-06):
- Per window, compute a `safe_rate = budget_left / time_left` (fixed-point ×1000; `1000` = on pace, `0` = budget blown with time still on the clock). Weekly budget subtracts the 5pp headroom. The tighter (smaller `safe_rate`) window governs.
- `sleep = CAP × (1 − safe_rate)`. Far over pace (safe_rate → 0) → sleep approaches the CAP (slow hard, but still one call per CAP — never a hard stop); mildly over → a short sleep; on/under pace (safe_rate ≥ 1) → zero (fast no-op).
- **Self-converging**: as the throttle slows the burn, wall-clock advances, `time_left` shrinks, `safe_rate` climbs back toward 1, and the sleep eases to zero exactly as the burn rejoins the sustainable pace — the runner drifting back, not stopping dead. Because `safe_rate` is derived from `budget_left / time_left`, the target is to land at the reset **with headroom intact**, i.e. convergence happens BEFORE the quota is consumed, by construction.
- The one inherent tension (guaranteed non-exhaustion vs "still make progress"): the CAP bounds per-call latency, so if the user keeps working right at the wire the slowdown is strong (near-CAP per call) but not infinite — progress continues, exhaustion is heavily delayed rather than hard-prevented. This matches the user's explicit "still lets us progress a bit." CAP is tunable (`CAP_SECONDS`, default 60).

Shipped: `packages/shared/hooks/quota-pace-throttle.sh` glide-path rewrite + `packages/shared/test/quota-pace-throttle.bats` 9/9 (added a proportional-ease-back test asserting far-over sleeps strictly longer than mildly-over — the property bang-bang lacked). Synced to all 7 plugins. ADR-093 / RFC-046 (born unconfirmed) to be updated with the glide-path law at their ratification drain.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-046 | proposed | Quota-pace throttle hook — frequently-firing PreToolUse calculated-sleep pacing across all work |
## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-039 | STORY-039: Throttle token burn against the quota windows | archived |
| STORY-044 | STORY-044: See what cruise is doing — a status/telemetry skill | accepted |
| STORY-042 | STORY-042: Extract quota-pacing into its own plugin | in-progress |
| STORY-043 | STORY-043: Self-install the quota-state producer | in-progress |

## Fix Released — code slice (2026-07-06)

The throttle CODE is built, tested (8/8 behavioural bats), and RELEASED across all
7 plugins (itil 0.57.1, architect 0.19.0, jtbd, tdd, risk-scorer 0.16.5, style-guide,
voice-tone 0.6.6): `packages/shared/hooks/quota-pace-throttle.sh` — a PreToolUse hook
that reads the statusline-written `~/.claude/quota-state.json`, compares 5h/7d
usage% vs elapsed%, and sleeps a calculated catch-up (cap 60s/firing, 5pp weekly
headroom) when ahead of pace; fast no-op behind pace; never blocks/prompts; fail-open.
Statusline cache-writer added to `~/.claude/statusline-command.sh` (maintainer) +
`QUOTA-THROTTLE-SETUP.md` for adopters.

**Ratification-block (per the goal):** the governance artefacts authored for this fix
are born `human-oversight: unconfirmed` (AFK fallback, ADR-066/P348) and need the
maintainer's ratification at `/wr-architect:review-decisions` + `/wr-itil:manage-rfc`:
- **ADR-093** — mechanical quota-pace throttle (decision).
- **RFC-046** — quota-pace throttle hook, frequently-firing PreToolUse across all work.
- **STORY-* / RFC-045** — capture-adr-derives-full-substance (shipped architect 0.19.0, the drifted-but-real skeleton-rot fix; P375-adjacent).

Awaiting: (1) user verification that pacing behaves as intended over a real window;
(2) governance ratification of ADR-093/RFC-046. The code path is live meanwhile.

## Verification inadequate — reopen pending (user audit 2026-07-07)

The maintainer verified the throttle live and found it **works — but only for the maintainer**, and the delivery is inadequate on three axes. Verbatim substance: *"Yes, the problem got solved, but only for me. … the problem doesn't specify the persona it impacts. How can you solve it for the user if you don't know who the user is? … if you had done a proper JTBD and USM, you would have seen it was independent of the other USMs and belonged in its own plugin."*

Confirmed 2026-07-07 (see verification session):

1. **Working for the maintainer.** The hook is installed in the active cache, firing every tool call, and on live numbers (weekly 74% used at 43% elapsed) actively glide-path throttling ~37s/call. The mechanism is sound.
2. **Inert for adopters.** The data producer is not shipped (folded gap above) — an adopter gets the hook but no throttling.
3. **Mis-placed.** Synced across 7 governance plugins instead of its own (folded gap above).
4. **Broken governance lineage.** Wrong/absent grounding JTBD + persona; orphaned STORY-039 / STORY-MAP-003; RFC-046 `proposed` while this ticket is `verifying`. Captured as **P443** (blocks honest verification of this ticket) + folded into **P404** (systemic gate-gaps).

**This ticket must NOT close** until (a) P443's lineage repair lands (correct JTBD/persona/USM), (b) the adopter-inert producer gap is closed, and (c) the own-plugin extraction (`@windyroad/cruise`) is done. Per the P404/P390 verification-failure precedent, **REOPENED `verifying → known-error` 2026-07-07 (user-ratified), Severity kept at 20**. Rationale (user, verbatim substance): *"the reason we don't re-rate it is because the pain is felt by all the people not using it at the moment."* The shipped throttle mitigates the acute pain for exactly one hand-wired machine; for everyone else — every adopter, every un-wired maintainer machine — the full mid-window-hard-stop pain is undiminished. Severity 20 (Tier 0 Critical-bypass) reflects the population still exposed, not the one setup that is protected.

### Cross-profile producer failure (2026-07-23)

After installing Cruise and restarting Codex, an affected Codex profile still had no `~/.codex/quota-state.json`; the status skill correctly reported fail-open pacing but could only suggest another restart or an unspecified producer repair. The same published producer succeeds in another profile on the same machine. Investigation found that the installer knows a working Codex binary only for its own process, while later producer runs rediscover it from a narrow fixed candidate list and silently discard every app-server error. Proposed ADR-097/098 amendments persist the install-time binary and surface a private, bounded failure classification through the status command.

### Producer constraint (research 2026-07-07 — reshapes the adopter fix)

Authoritative Claude Code v2.1.x finding: **the statusLine is the ONLY surface exposed to `.rate_limits`.** No hook event receives it; there is no `claude usage` CLI / native quota file / env var / API a hook can reach; and **a plugin CANNOT contribute the main `statusLine`** (only the `agent` + `subagentStatusLine` settings keys exist). `.rate_limits` also only appears for Pro/Max subscribers after the first API response. Consequence: the producer (`~/.claude/quota-state.json` writer) is unavoidably **user-owned config the plugin cannot ship**. The "works fully out-of-the-box" goal is therefore **not achievable**; the honest ceiling is *"the one-time statusline setup is surfaced/nudged, never silently inert"* — closed by (a) a **SessionStart absent-cache nudge** + (b) a **ready-made statusline snippet / opt-in installer**. The earlier "plugin-contributed statusLine" option is struck (impossible).
