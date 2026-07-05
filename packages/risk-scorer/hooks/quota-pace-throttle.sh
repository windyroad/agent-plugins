#!/usr/bin/env bash
# quota-pace-throttle.sh — PreToolUse hook (P160 / ADR-093 / RFC-046).
#
# Fires before every tool call across ALL work (interactive + AFK). Mechanically
# paces token burn so it never sprints into a mid-flight quota hard-stop: it
# compares cumulative window usage% against elapsed% and, when AHEAD of pace,
# sleeps the calculated catch-up time (capped per firing). When behind/on pace
# it is a fast no-op. It NEVER blocks, NEVER asks, and fails OPEN on every
# abnormal path — a broken throttle must not break the session.
#
# Data source: ~/.claude/quota-state.json, written by the statusline (the only
# surface Claude Code passes `.rate_limits` to). Fields:
#   { "five_used_pct": N, "five_resets_at": <unix>,
#     "week_used_pct": N, "week_resets_at": <unix> }
# If the cache is missing/stale/malformed, the hook no-ops (fail-open) — the
# statusline-writer install is a separate, user-consented step.
#
# ponytail: pure arithmetic + one sleep; the 60s/firing cap + fail-open keep the
# blast radius to "at worst a slightly-slower tool call", never a stall or block.

set +e
CACHE="${WR_QUOTA_CACHE:-${HOME}/.claude/quota-state.json}"
MARKER="${WR_QUOTA_MARKER:-${TMPDIR:-/tmp}/wr-quota-throttle-last}"
FIVE_WINDOW=18000      # 5h in seconds
WEEK_WINDOW=604800     # 7d in seconds
WEEK_HEADROOM_PP=5     # leave 5pp weekly headroom for non-Claude-Code surfaces
CAP_SECONDS=60         # max sleep per firing

emit_ok() { exit 0; }  # PreToolUse: silent allow, never a permissionDecision deny

# Fail-open preconditions.
command -v jq >/dev/null 2>&1 || emit_ok
[ -r "$CACHE" ] || emit_ok

now=$(date +%s 2>/dev/null) || emit_ok
case "$now" in ''|*[!0-9]*) emit_ok;; esac

# Recent-check no-op: if we checked <5s ago, skip recompute (keeps per-call
# latency negligible when we're firing on every tool call).
if [ -f "$MARKER" ]; then
  last=$(cat "$MARKER" 2>/dev/null)
  case "$last" in
    ''|*[!0-9]*) : ;;
    *) [ $(( now - last )) -lt 5 ] && emit_ok ;;
  esac
fi
printf '%s' "$now" > "$MARKER" 2>/dev/null

# Read the cache; fail-open on any parse miss.
read -r five_used five_reset week_used week_reset < <(
  jq -r '[.five_used_pct, .five_resets_at, .week_used_pct, .week_resets_at]
         | map(tostring) | join(" ")' "$CACHE" 2>/dev/null
) || emit_ok
for v in "$five_used" "$five_reset" "$week_used" "$week_reset"; do
  case "$v" in ''|null|*[!0-9.]*) emit_ok;; esac
done

# elapsed% of a window = (window - remaining) / window * 100, clamped [0,100].
elapsed_pct() { # resets_at window_secs
  local remaining=$(( $1 - now )) win="$2" e
  [ "$remaining" -lt 0 ] && remaining=0
  [ "$remaining" -gt "$win" ] && remaining="$win"
  e=$(( (win - remaining) * 100 / win ))
  printf '%s' "$e"
}

# integer-truncate the used% (cache may carry a decimal)
five_used_i=${five_used%%.*}; week_used_i=${week_used%%.*}
five_elapsed=$(elapsed_pct "$five_reset" "$FIVE_WINDOW")
week_elapsed=$(elapsed_pct "$week_reset" "$WEEK_WINDOW")

# pace gap per window (positive = ahead of pace = burning too fast).
# weekly target leaves headroom, so effective gap = used - (elapsed - headroom).
gap5=$(( five_used_i - five_elapsed ))
gap7=$(( week_used_i - (week_elapsed - WEEK_HEADROOM_PP) ))

# Take the tighter (larger-gap) window and its window length.
if [ "$gap5" -ge "$gap7" ]; then gap="$gap5"; win="$FIVE_WINDOW"; else gap="$gap7"; win="$WEEK_WINDOW"; fi
[ "$gap" -le 0 ] && emit_ok   # behind/on pace → fast no-op

# Catch-up sleep: elapsed% rises at 100/win per second, so closing `gap` pp of
# lead needs gap/100 * win seconds. Cap per firing so no single call stalls long.
sleep_secs=$(( gap * win / 100 ))
[ "$sleep_secs" -gt "$CAP_SECONDS" ] && sleep_secs="$CAP_SECONDS"
[ "$sleep_secs" -le 0 ] && emit_ok

sleep "$sleep_secs" 2>/dev/null
emit_ok
