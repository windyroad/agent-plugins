---
status: "proposed"
date: 2026-07-06
human-oversight: unconfirmed
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
- **Adopter-portable, standalone-installable** (ADR-002/003; ADR-017 canonical-source sync).

## Considered Options

1. **Between-iter check in `/wr-itil:work-problems` only** (the stale compendium shape) — rejected by Correction 2: loop-boundary-only pacing misses interactive work and everything inside a long iteration.
2. **Advisory nudge or blocking gate** — rejected by Correction 1 (no advise/nudge) and ADR-013 Rule 6 (a blocking gate breaks AFK).
3. **Frequently-firing PreToolUse hook with calculated sleep** — **chosen.**
4. **Single carrier plugin (itil only)** — rejected: an adopter installing any one `@windyroad/*` plugin should get the throttle (ADR-002 standalone installability); mitigate the N-copies cost with a shared recent-check marker instead.
5. **`ScheduleWakeup`-style orchestrator pacing** — rejected: covers only the loop surface (Correction 2), and P083 bars ScheduleWakeup in this flow.

## Decision Outcome

Chosen option 3, distributed per option 4's mitigation: canonical hook `packages/shared/hooks/quota-pace-throttle.sh`, synced to the seven published plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) by `scripts/sync-quota-pace-throttle.sh` with a CI `--check` drift gate (ADR-017), registered in each plugin's `hooks.json` as `PreToolUse` with **no matcher** (every tool call — Correction 2 verbatim) and `timeout: 90`.

### Mechanics (normative)

- **Cache contract**: the hook reads `~/.claude/quota-state.json` (override: `WR_QUOTA_CACHE_FILE`) — `{"written_at": <epoch>, "five_hour": {"used_percentage": <n>, "resets_at": <epoch>}, "seven_day": {...}}`. The statusline stdin payload is the only carrier of rate-limit state Claude Code exposes (verified empirically 2026-07-06: nothing else under `~/.claude` or `/tmp` persists it), so the cache is written by the user's statusline command via a documented ~6-line snippet (hook header + plugin READMEs). Atomic tmp+mv writes.
- **Pace rule**: per window (5h W=18000s, 7d W=604800s): `elapsed_pct = (W - (resets_at - now)) / W × 100`; `over_pp = usage_pct - (elapsed_pct - headroom_pp)`. Headroom defaults: 0pp (5h), 5pp (7d) — env-tunable `WR_QUOTA_HEADROOM_5H_PP` / `WR_QUOTA_HEADROOM_7D_PP`. `required_sleep = max over windows of over_pp × W / 100` seconds — the time for elapsed% to catch up to usage%; the tighter window governs by construction.
- **Per-firing cap**: sleep is capped at `WR_QUOTA_THROTTLE_MAX_SLEEP` (default 60s) per firing; because the hook fires on every tool call, repeated capped sleeps converge on the pace line without any single multi-hour hang.
- **Latency budget** (per ADR-023 performance-review scope): the no-op (behind-pace) branch must cost ≤50ms aggregate per tool call across all installed copies. Achieved by a shared recent-check marker (`/tmp/wr-quota-throttle-checked`): a copy that finds the marker fresher than 5s exits before parsing anything, so per-call work collapses to ~one copy regardless of how many plugins ship the hook; a lock file prevents stacked sleeps.
- **Fail-open envelope** (exit 0, empty stdout, on every path): kill-switch `WR_QUOTA_THROTTLE_DISABLE=1`; cache missing, older than 30 minutes, or malformed; `resets_at` in the past; `jq` absent. The hook NEVER emits `permissionDecision`, never blocks, never asks.
- **Adopter activation limitation (recorded)**: the hook is inert (silent fail-open) until the adopter wires the documented snippet into their own statusline command. Plugin READMEs carry the activation snippet, cache contract, sleep semantics, and kill-switch (JTBD-302). A SessionStart absent-cache nudge is a deferred slice — tracked as a task on RFC-046 (the self-firing carrier), not prose-only.

## Pros and Cons of the Options

- **Option 1 (between-iter only)**: good — one call site, no per-tool-call cost. bad — contradicts Correction 2; misses interactive burn and intra-iteration sprints.
- **Option 2 (advisory/gate)**: good — visible. bad — contradicts Correction 1; advisory depends on a human being present (fails AFK exactly when the loops burn hardest); a gate halts work, which is the harm itself.
- **Option 3 (PreToolUse calculated sleep, chosen)**: good — continuous even burn on all work; zero decisions; AFK-safe; fail-open. bad — deliberate latency when ahead of pace (accepted: small sleeps now beat a hard stop later); per-call hook spawn cost (mitigated by the recent-check marker + latency budget).
- **Option 4 (single carrier plugin)**: good — 1× spawn cost. bad — no throttle for adopters of the other six plugins.
- **Option 5 (orchestrator pacing)**: good — no hook surface. bad — loop-only; P083.

## Consequences

- Positive: overnight AFK loops self-throttle to land at window resets WITH headroom instead of hard-stopping mid-iteration; interactive work contributes to the same even burn; the weekly reserve protects chat/cowork.
- Negative: when ahead of pace, every tool call may sleep up to the cap — deliberate, user-ratified latency. Kill-switch documented.
- Negative: maintainer-only benefit until an adopter wires the statusline snippet (limitation recorded above).

## Confirmation

Behavioural bats (`packages/shared/test/quota-pace-throttle.bats`): behind-pace fast no-op; ahead-of-pace sleeps the calculated amount (dry-run calc assertions + one real capped-sleep wall-clock case); 7d headroom violation throttles even when raw usage < elapsed; recent-check marker short-circuit skips the parse; missing/stale cache, kill-switch, and past `resets_at` all fast no-op; exit code 0 and empty stdout on every path. Sync drift covered by `scripts/sync-quota-pace-throttle.sh --check` in CI (ADR-017).

## More Information

- P160 (`docs/problems/open/160-ship-quota-pacing-surface-to-prevent-weekly-quota-exhaustion.md`) — driver ticket; ratified direction + corrections verbatim.
- ADR-017 (canonical shared hooks + sync), ADR-013 Rule 6 (never block AFK), ADR-057 (declarative-first), ADR-045 (hook injection byte budget — this hook emits 0 bytes on every path), ADR-023 (performance review scope — latency budget above), ADR-002/003 (standalone installability), ADR-066 (born-proposed oversight semantics — ratification queued).
- Sibling axis: ADR-038 progressive disclosure (per-session context budget); this ADR is the per-week token-budget analogue.
