# @windyroad/cruise

Cruise control for your Claude Code token burn. A mechanical, self-calibrating throttle that paces your tool-call burn so you **glide onto each rate-limit window's pace line and converge on the reset** — instead of sprinting into a hard rate-limit stop mid-flight. *Maturity: Experimental.*

Grounded in JTBD-010 (Sustain My Token Quota Across the Week and Across Surfaces); mechanics in ADR-093; config in ADR-098; producer self-install in ADR-097.

## What it does

A matcher-less `PreToolUse` hook fires before every tool call. It reads your current rate-limit usage from a cache, measures your actual burn rate, and — when you're burning faster than the *remaining sustainable rate* `(100 − headroom − used) / time_left` — sleeps a small, growing amount per call (a feedback controller) to bring your burn back onto pace. When you're on or under pace it's a fast no-op. It **never blocks, never asks, and fails open** on every abnormal path (a broken throttle must not break your session).

Two rate-limit windows are paced simultaneously (rolling 5-hour and 7-day); the tighter one governs. A weekly **headroom** (default 5pp) is reserved so Claude Code doesn't consume the last of your budget that chat / Cowork also draw on.

**Honest limit:** because it slows rather than blocks (by design — see JTBD-010), it cannot prevent exhaustion under *sustained* very-heavy burn (>~5%/hr for days); that would need a hard stop, which is deliberately not done. It covers all realistic heavy burn.

## Controls

- **Disable without uninstalling:** set `max_sleep_s: 0` in the config file — a zero ceiling clamps every sleep to nothing. There's no separate kill-switch: the glide only ever *slows*, never blocks, so there's nothing to escape from.
- **Config file** (`.claude/cruise.config.json` in a project, or `~/.claude/cruise.config.json` per-machine; project wins, then machine, then built-in defaults; env vars override all):

  ```json
  {
    "headroom_7d_pp": 5,
    "headroom_5h_pp": 0,
    "max_sleep_s": 600,
    "cache_path": "~/.claude/quota-state.json"
  }
  ```

  `max_sleep_s` is the per-call sleep ceiling (default 600s, under the hook's 660s timeout so the sleep always completes). Raising it toward the timeout throttles harder (a near-hold at the line) while always remaining a sleep, never a block.

## The quota cache

The throttle reads `~/.claude/quota-state.json` (nested schema: `.five_hour.used_percentage` / `.resets_at`, `.seven_day.{…}`). Only a **statusline** receives Claude Code's `.rate_limits`, so the cache is written by a small statusline snippet. `@windyroad/cruise` self-installs that producer (ADR-097) — you don't wire it by hand. If the cache is absent/stale/malformed the throttle is a silent no-op (fail-open).

## Uninstall / opt-out

There's no "install but don't self-install the producer" knob — that would be an inert plugin. To remove the producer, **uninstall the plugin**; uninstall removes the self-installed statusline block (leaving your statusline as it was). To pause the *pacing* while keeping everything installed, set `max_sleep_s: 0` (above).

## Tests

`test/quota-pace-throttle.bats` (throttle) + `test/quota-state-producer-install.bats` (self-installer) — behavioural: fail-open paths, baseline capture, over-pace ramp-up, under-pace ease-off, ceiling clamp + `max_sleep_s: 0` disable, recent-check short-circuit, never-denies, 5h-window-governs; and for the installer: create-and-wire when absent, no-op when already producing, agent-merge (never blind-append) otherwise.
