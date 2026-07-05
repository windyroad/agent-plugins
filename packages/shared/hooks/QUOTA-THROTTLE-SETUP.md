# Quota-pace throttle — adopter setup (P160 / ADR-093 / RFC-046)

The `quota-pace-throttle.sh` PreToolUse hook (shipped in every `@windyroad/*`
plugin) paces token burn: before each tool call it compares cumulative 5h/7d
window usage against elapsed time and, when *ahead* of pace, sleeps a calculated
catch-up (capped 60s/firing). Behind pace it's a fast no-op. It never blocks,
never asks, and fails open. This keeps an AFK loop from sprinting into a
mid-flight quota hard-stop.

## One-time setup: feed it the data

The hook reads `~/.claude/quota-state.json`. Only the **statusline** receives
Claude Code's `.rate_limits` data, so the statusline must persist it. Add this
after your statusline extracts the rate-limit values (i.e. after it reads
`.rate_limits.seven_day.resets_at`), using whatever variable names your
statusline already assigns them to:

```bash
if [ -n "$five_used$week_used" ]; then
  printf '{"five_used_pct":%s,"five_resets_at":%s,"week_used_pct":%s,"week_resets_at":%s}\n' \
    "${five_used:-0}" "${five_resets:-0}" "${week_used:-0}" "${week_resets:-0}" \
    > "$HOME/.claude/quota-state.json" 2>/dev/null || true
fi
```

`*_resets` must be unix timestamps (as Claude Code supplies them). Until the
cache exists the hook fail-opens (no throttling) — so the plugin is safe to
install before wiring the statusline.

## Tuning

Environment overrides read by the hook: `WR_QUOTA_CACHE` (cache path),
`WR_QUOTA_MARKER` (recent-check marker path). The 5pp weekly headroom and the
60s/firing cap are constants in `quota-pace-throttle.sh`.
