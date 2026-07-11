# @windyroad/cruise

## 0.2.0

### Minor Changes

- 7c87fe5: Add `@windyroad/cruise` — token-quota pacing — and retire the seven-way throttle sync.

  `@windyroad/cruise` is a self-calibrating token-quota throttle for Claude Code. It reads your rate-limit usage, measures your actual burn, and paces your tool calls so you glide onto each window's pace line and converge on the reset — instead of sprinting into a hard rate-limit stop mid-session. It reserves a weekly headroom for your other Claude surfaces, never blocks, and fails open. Knobs live in a config file (`.claude/cruise.config.json` per project or `~/.claude/cruise.config.json` per machine); `WR_QUOTA_THROTTLE_DISABLE=1` pauses it.

  The seven governance plugins (architect, itil, jtbd, tdd, risk-scorer, style-guide, voice-tone) no longer ship the throttle — it now has a single home in `@windyroad/cruise`, installed as part of the default `npx @windyroad/agent-plugins` set.
