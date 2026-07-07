---
status: "proposed"
date: 2026-07-06
human-oversight: confirmed
oversight-date: 2026-07-08
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-10-06
---

# Mechanical quota-pace throttle — frequently-firing PreToolUse hook, calculated sleep, never blocks

## Context and Problem Statement

Claude's weekly token quota is shared across every surface on the account (Claude Code, chat, cowork). Hitting a rate-limit window does not merely delay work — it HALTS it mid-flight: AFK `/wr-itil:work-problems` loops break partway through an iteration, in-flight subprocess work strands, and the user must either babysit the reset or waste the hours until it (P160 live evidence 2026-07-05: `You've hit your session limit · resets 11pm`; the user had to choose between staying up and losing the overnight window). The statusline already *measures* burn pace against the 5-hour and 7-day windows; nothing *regulates* it.

The user ratified the solution direction on 2026-07-05 (P160 ticket body, corrections 1 + 2, verbatim quotes there):

1. **Automatic proportional-window throttle** — at any point, cumulative usage must not exceed the elapsed fraction of the window; pace against whichever of the 5h / 7d windows is tighter; leave weekly headroom for non-Claude-Code surfaces.
2. **Correction 1** — *"it shouldn't advise or nudge, it should use hooks to calculate if a delay is needed and if so, sleep for that amount of time."* Mechanical, zero human decision.
3. **Correction 2** — *"it shouldn't be just between work-problems iters. Other work too. It should fire on hooks quite frequently."* The carrier is a high-frequency hook across ALL work, interactive and AFK.

**Slot note**: a compendium-only ADR-093 entry (no body file ever existed on disk — a P365-class partial write) recorded a pre-Correction-2 shape (itil-sibling scripts, between-iter Step 6.6 first slice, per-tool-use pacing deferred). This body is the authoritative record (ADR-077) and supersedes that stale shape in place; the between-iter checkpoint remains a complementary future slice, not the load-bearing surface.

## Decision Drivers

- **The stop is the harm** — pacing must prevent the mid-flight hard stop, not report it afterwards.
- **Mechanical** (Correction 1) — no advisory, no nudge, no `AskUserQuestion`, no user-in-the-loop.
- **Fires frequently on ALL work** (Correction 2) — interactive foreground and AFK loops alike.
- **Cheap when behind pace** — a PreToolUse hook on every tool call must add negligible latency on the no-op branch.
- **Fail-open, never blocks** (ADR-013 Rule 6; ADR-057 declarative-first) — any abnormal state proceeds silently; the throttle must never become a new way to halt work.
- **Cross-surface weekly headroom** — the 7d axis reserves quota for chat/cowork.
- **Adopter-portable, standalone-installable** (ADR-002/003; ADR-017 canonical-source sync — *the sync mechanism is retired by the 2026-07-08 amendment; standalone-installability is now served by the dedicated `@windyroad/quota-pacing` plugin*).

## Considered Options

1. **Between-iter check in `/wr-itil:work-problems` only** (the stale compendium shape) — rejected by Correction 2: loop-boundary-only pacing misses interactive work and everything inside a long iteration.
2. **Advisory nudge or blocking gate** — rejected by Correction 1 (no advise/nudge) and ADR-013 Rule 6 (a blocking gate breaks AFK).
3. **Frequently-firing PreToolUse hook with calculated sleep** — **chosen.**
4. **Single carrier plugin** — Release 1 rejected this (mitigate the N-copies cost with a shared recent-check marker instead) on the ground that "an adopter installing any one `@windyroad/*` plugin should get the throttle". **This rejection is RETRACTED by the 2026-07-08 amendment**: a dedicated single-home plugin `@windyroad/quota-pacing` is adopted for JTBD-010/USM cohesion (not spawn cost), consciously accepting opt-in reach. See Amendment.
5. **`ScheduleWakeup`-style orchestrator pacing** — rejected: covers only the loop surface (Correction 2), and P083 bars ScheduleWakeup in this flow.

## Decision Outcome

Chosen option 3 (mechanical PreToolUse calculated sleep), registered in `hooks.json` as `PreToolUse` with **no matcher** (every tool call — Correction 2 verbatim) and `timeout: 90`. **Plugin home — REVISED 2026-07-08 (see Amendment):** Release 1 shipped the canonical hook `quota-pace-throttle.sh` synced across the seven published plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) via `scripts/sync-quota-pace-throttle.sh` (ADR-017 drift gate). That seven-plugin sync is **retired** in favour of a dedicated, standalone, opt-in plugin `@windyroad/quota-pacing`; the shared-canonical + sync surface (and its multi-copy latency mitigation) is removed as the extraction lands.

### Mechanics (normative)

- **Cache contract**: the hook reads `~/.claude/quota-state.json` (override: `WR_QUOTA_CACHE_FILE`) — `{"written_at": <epoch>, "five_hour": {"used_percentage": <n>, "resets_at": <epoch>}, "seven_day": {...}}`. The statusline stdin payload is the only carrier of rate-limit state Claude Code exposes (verified empirically 2026-07-06, re-confirmed authoritatively 2026-07-08: no hook event receives `.rate_limits`, there is no `claude usage` CLI / native quota file, and a plugin cannot contribute the `statusLine` settings key). Release 1 required the user to hand-wire a ~6-line snippet; the 2026-07-08 amendment makes the producer self-installing (see below). Atomic tmp+mv writes.
- **Pace rule**: per window (5h W=18000s, 7d W=604800s): `elapsed_pct = (W - (resets_at - now)) / W × 100`; `over_pp = usage_pct - (elapsed_pct - headroom_pp)`. Headroom defaults: 0pp (5h), 5pp (7d) — env-tunable `WR_QUOTA_HEADROOM_5H_PP` / `WR_QUOTA_HEADROOM_7D_PP`. `required_sleep = max over windows of over_pp × W / 100` seconds — the time for elapsed% to catch up to usage%; the tighter window governs by construction.
- **Per-firing cap**: sleep is capped at `WR_QUOTA_THROTTLE_MAX_SLEEP` (default 60s) per firing; because the hook fires on every tool call, repeated capped sleeps converge on the pace line without any single multi-hour hang.
- **Latency budget** (per ADR-023 performance-review scope): the no-op (behind-pace) branch must cost ≤50ms per tool call. Achieved by a recent-check marker (`/tmp/wr-quota-throttle-checked`): a firing that finds the marker fresher than 5s exits before parsing anything; a lock file prevents stacked sleeps. *(Release 1 framed this as a cross-copy mitigation "regardless of how many plugins ship the hook" — that multi-copy rationale is retired by the 2026-07-08 amendment: a single-home plugin means one copy per tool call, a strict performance improvement; the marker remains only as an intra-plugin fast-path.)*
- **Fail-open envelope** (exit 0, empty stdout, on every path): kill-switch `WR_QUOTA_THROTTLE_DISABLE=1`; cache missing, older than 30 minutes, or malformed; `resets_at` in the past; `jq` absent. The hook NEVER emits `permissionDecision`, never blocks, never asks.
- **Adopter activation — REVISED 2026-07-08 (see Amendment):** Release 1 left the hook inert (silent fail-open) until the adopter hand-wired the statusline snippet — the P160/P443 adopter-inert gap. The revised decision makes the producer **self-installing**: a SessionStart hook materialises the `~/.claude/quota-state.json` writer (indicative activation shape — create the statusline cache-writer + wire `settings.json` when absent, idempotently guarded-append when present, agent-merge fallback for complex existing statuslines; the **mechanism is deferred to a dedicated build-time ADR** per ADR-074). Consent is **implied at install** with an **opt-out** kill path. Closes the adopter-inert gap → satisfies JTBD-010 outcome #7.

## Pros and Cons of the Options

- **Option 1 (between-iter only)**: good — one call site, no per-tool-call cost. bad — contradicts Correction 2; misses interactive burn and intra-iteration sprints.
- **Option 2 (advisory/gate)**: good — visible. bad — contradicts Correction 1; advisory depends on a human being present (fails AFK exactly when the loops burn hardest); a gate halts work, which is the harm itself.
- **Option 3 (PreToolUse calculated sleep, chosen)**: good — continuous even burn on all work; zero decisions; AFK-safe; fail-open. bad — deliberate latency when ahead of pace (accepted: small sleeps now beat a hard stop later); per-call hook spawn cost (mitigated by the recent-check marker + latency budget).
- **Option 4 (single carrier plugin)**: good — 1× spawn cost. bad — no throttle for adopters of the other six plugins. **[Retracted 2026-07-08 — see Amendment: the extraction adopts a single-home shape for JTBD-010/USM cohesion, not spawn cost, and consciously accepts opt-in reach; the "no throttle for adopters of other plugins" con is now the intended opt-in behaviour.]**
- **Option 5 (orchestrator pacing)**: good — no hook surface. bad — loop-only; P083.

## Consequences

- Positive: overnight AFK loops self-throttle to land at window resets WITH headroom instead of hard-stopping mid-iteration; interactive work contributes to the same even burn; the weekly reserve protects chat/cowork.
- Negative: when ahead of pace, every tool call may sleep up to the cap — deliberate, user-ratified latency. Kill-switch documented.
- Negative (Release 1 only): maintainer-only benefit until an adopter wired the statusline snippet. **RESOLVED by the 2026-07-08 amendment** — the self-installing producer closes this for all adopters (implied-at-install consent + opt-out).

## Confirmation

Behavioural bats (`packages/shared/test/quota-pace-throttle.bats`): behind-pace fast no-op; ahead-of-pace sleeps the calculated amount (dry-run calc assertions + one real capped-sleep wall-clock case); 7d headroom violation throttles even when raw usage < elapsed; recent-check marker short-circuit skips the parse; missing/stale cache, kill-switch, and past `resets_at` all fast no-op; exit code 0 and empty stdout on every path. ~~Sync drift covered by `scripts/sync-quota-pace-throttle.sh --check` in CI (ADR-017).~~ — **RETIRED 2026-07-08**: the extraction to a single `@windyroad/quota-pacing` plugin removes the seven-way sync surface entirely (see Amendment). The extraction + self-installer bats land with STORY-042 / STORY-043.

## More Information

- P160 (`docs/problems/known-error/160-ship-quota-pacing-surface-to-prevent-weekly-quota-exhaustion.md`) — driver ticket (reopened Known Error, Sev 20, Tier 0); ratified direction + corrections verbatim.
- ADR-017 (canonical shared hooks + sync — *the sync surface is retired by the 2026-07-08 amendment*), ADR-013 Rule 6 (never block AFK), ADR-057 (declarative-first), ADR-045 (hook injection byte budget — this hook emits 0 bytes on every path), ADR-023 (performance review scope — latency budget above), ADR-002/003 (standalone installability — now served by the dedicated plugin), ADR-066 (born-proposed oversight semantics — ratification queued).
- Sibling axis: ADR-038 progressive disclosure (per-session context budget); this ADR is the per-week token-budget analogue.

## Amendment 2026-07-08 — own-plugin home (opt-in) + self-installing producer (P443 / JTBD-010 / STORY-MAP-003)

P443 surfaced that quota-pacing was shipped without a grounded problem → JTBD → USM → RFC → story lineage: it was mis-anchored to JTBD-006 (Progress the Backlog While I'm Away, AFK-only) when the throttle in fact fires on ALL work. The correct grounding is **JTBD-010 (Sustain My Token Quota Across the Week and Across Surfaces)**, ratified 2026-07-07. Two Release-1 decisions are revised in place (ADR-093 was never ratified, so this is pre-acceptance evolution, not a file-status supersession):

**1. Plugin home — own-plugin, opt-in (retracts Option 4's rejection rationale).** A user-story-map analysis for JTBD-010 (formalised as STORY-MAP-003, born-unconfirmed) shows quota-pacing shares **no backbone activity** with the two existing story maps (both JTBD-008 "decompose-a-fix"): it is independent. It is therefore extracted into a dedicated, standalone plugin **`@windyroad/quota-pacing`** (user-ratified 2026-07-08). This **retracts** Considered-Options Option 4's rejection ground ("an adopter installing any one `@windyroad/*` plugin should get the throttle"): reach is now **opt-in** — throttling is a capability installed on purpose, not bundled into every governance plugin. (Grounding note per ADR-074: the extraction rests on the USM *analysis* + the user's 2026-07-08 ratification, NOT on STORY-MAP-003's oversight marker, which is born-unconfirmed and drains separately.) The Release-1 sync/multi-copy mechanics (Decision Driver "ADR-017 canonical-source sync"; Considered-Options Option 4's shared-marker mitigation; the Latency-budget "regardless of how many plugins ship the hook" rationale; the More-Information ADR-017 reference) describe Release 1 as-shipped and are **retired by this amendment** — under a single-home plugin there is no seven-way sync surface and no multi-copy-per-tool-call cost (a strict performance improvement, 7 → 1).

**2. Adopter activation — self-installing producer (resolves the adopter-inert limitation).** Release 1's "inert until the adopter wires the statusline snippet" limitation is **resolved**. Platform constraint (authoritative, Claude Code v2.1.x): the statusline is the ONLY surface exposed to `.rate_limits`, and a plugin **cannot** contribute the `statusLine` settings key — so self-installing the user's statusline config is the only mechanism. A SessionStart hook self-installs the producer (indicative shape: create-if-absent + wire `settings.json`; idempotent guarded-append when present; agent-merge fallback). **Consent model — decided:** implied-at-install (the plugin's stated purpose requires the producer; installing it is the authorisation) + opt-out. ADR-034's rejection of silent auto-install does not bind here: it is superseded (by ADR-030, on a mechanism mismatch — per-project vs global-cache install model — not a consent principle) and never ratified, and it addressed silently installing plugin *code onto another repo* — a materially different case from a chosen plugin writing its own required config on the user's own machine. **Mechanism deferred:** the self-installer's implementation (exact write shape, idempotency sentinel, opt-out surface) gets its own build-time ADR per ADR-074 before STORY-043 is built.

**Traceability:** problems P160 (reopened Known Error, Sev 20) + P443 (lineage repair); JTBD-010; STORY-MAP-003 (USM); stories STORY-039 (shipped throttle, backfill), STORY-042 (extraction), STORY-043 (self-installing producer); RFC-046 (lineage repair pending). ADR-002 obligations for the new plugin (inventory, `marketplace.json`, `install.mjs` PLUGINS array + dependency graph) land with the STORY-042 extraction build.
