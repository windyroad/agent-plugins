# @windyroad/cruise

## 0.3.1

### Patch Changes

- 36d13be: Rewrite the README to lead with the value — the pain of a mid-run rate-limit stop and the glide-to-reset outcome — and add the install commands and the `/wr-cruise:status` usage.

## 0.3.0

### Minor Changes

- 60b252a: Add `/wr-cruise:status` — see what the throttle is doing.

  An on-demand telemetry report for quota pacing: per rolling window (5-hour and 7-day) it shows your usage against the pace line, how far ahead or behind you are, the remaining sustainable burn rate, and time to reset; the exact sleep the throttle is injecting per tool call right now; a glide projection; and a cache-health check that flags a stale or absent quota cache — which means the throttle is silently doing nothing.

## 0.2.0

### Minor Changes

- 7c87fe5: Add `@windyroad/cruise` — token-quota pacing — and retire the seven-way throttle sync.

  `@windyroad/cruise` is a self-calibrating token-quota throttle for Claude Code. It reads your rate-limit usage, measures your actual burn, and paces your tool calls so you glide onto each window's pace line and converge on the reset — instead of sprinting into a hard rate-limit stop mid-session. It reserves a weekly headroom for your other Claude surfaces, never blocks, and fails open. Knobs live in a config file (`.claude/cruise.config.json` per project or `~/.claude/cruise.config.json` per machine); `WR_QUOTA_THROTTLE_DISABLE=1` pauses it.

  The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship the throttle — it now has a single home in `@windyroad/cruise`, installed as part of the default `npx @windyroad/agent-plugins` set.
