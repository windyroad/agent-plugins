#!/usr/bin/env bash
# quota-pace-throttle.sh — PreToolUse hook (P160 / P443 / P446 / ADR-093 / RFC-046).
# @jtbd JTBD-010  (Sustain My Token Quota Across the Week and Across Surfaces)
# Ships in @windyroad/cruise — the single home (no longer synced across 7 plugins).
#
# Fires before every tool call across ALL work (interactive + AFK). Mechanically
# paces token burn so it converges onto the quota pace line instead of sprinting
# into a mid-flight hard-stop. It NEVER blocks, NEVER asks, fails OPEN on every
# abnormal path.
#
# SELF-CALIBRATING (P446, 2026-07-10). The Release-1 glide used a fixed 60s-capped
# sleep that only DELAYED exhaustion (a real hard weekly-limit stop occurred with
# it running). This holds the line instead: it measures the ACTUAL burn rate from
# the cache and, via a small feedback controller, ramps the per-call sleep UP while
# burn exceeds the remaining sustainable rate `safe = (100−headroom−used)/time_left`
# and DOWN while under — converging so burn ≈ safe (ADR-093 Mechanics). A one-shot
# `interval·(r/safe−1)` formula is fragile here (integer usage%, and the measured
# rate already reflects prior sleeps → oscillation); the controller is the stable
# realisation of the same target.
#
# Cache (flat; written by Claude's statusline or Codex app-server — ADR-097):
#   {"five_used_pct":N,"five_resets_at":<epoch>,
#    "week_used_pct":N,"week_resets_at":<epoch>,
#    "five_window_s":N,"week_window_s":N}
# Window durations are optional for legacy Claude caches (defaults: 5h/7d).
# The statusline's own stdin payload is nested (.rate_limits.five_hour.…); the
# producer flattens it into this cache. Missing/stale/malformed → no-op (fail-open).
#
# Config (ADR-098): env → project .claude/cruise.config.json → machine
# ~/.claude/cruise.config.json → default. jq-read, never sourced.
# Ceiling max_sleep_s default 600s, under the 660s hooks.json timeout so the sleep
# always completes (a timeout-killed hook fails OPEN and leaks the call). Setting
# max_sleep_s: 0 disables throttling (the ceiling clamps every sleep to 0) — there
# is no separate kill-switch: the glide only ever SLOWS, never blocks, so there is
# nothing to escape from, and uninstalling reverses it entirely.
#
# ponytail: integer arithmetic (cross-multiply to compare rates, no floats) + one
# sleep; ceiling + fail-open keep the blast radius to "a slower tool call".

set +e
emit_ok() { exit 0; }

IFS= read -r -d '' HOOK_INPUT || :
payload_sid=""
is_codex=0
if command -v jq >/dev/null 2>&1 && [ -n "$HOOK_INPUT" ]; then
  payload_sid=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
  # Codex transcript_path may be null or a path; turn_id is the stable discriminator.
  payload_runtime=$(printf '%s' "$HOOK_INPUT" | jq -r 'if (.session_id? and .turn_id?) then "codex" else "" end' 2>/dev/null)
  [ "$payload_runtime" = "codex" ] && is_codex=1
fi
[ -n "${CODEX_THREAD_ID:-}" ] && is_codex=1

BASELINE_MIN=60      # need ≥60s between baseline samples to read a burn rate through integer usage%
BASELINE_SLIDE=300   # slide the baseline forward once it ages past 5min (keeps the rate current)

# Per-session state (concurrency, STORY-042): one file per session so N concurrent
# sessions each keep full throttle grip while the shared cache coordinates aggregate burn.
sid="${CODEX_THREAD_ID:-${CLAUDE_SESSION_ID:-${payload_sid:-shared}}}"
STATE="${WR_QUOTA_MARKER:-${TMPDIR:-/tmp}/wr-quota-throttle-${sid}}"

now="${EPOCHSECONDS:-}"
[ -n "$now" ] || now=$(date +%s 2>/dev/null) || emit_ok
case "$now" in ''|*[!0-9]*) emit_ok;; esac

# State line: "check_ts base_ts base_week base_five cur_s". Recent-check FIRST
# (before any config/cache read) so the fast path stays cheap (ADR-023).
check_ts=0 base_ts=0 base_week=-1 base_five=-1 cur_s=0
if [ -f "$STATE" ]; then
  read -r check_ts base_ts base_week base_five cur_s < "$STATE" 2>/dev/null
  case "$check_ts" in ''|*[!0-9]*) check_ts=0;; esac
  case "$base_ts" in ''|*[!0-9]*) base_ts=0;; esac
  case "$base_week" in ''|*[!-0-9]*) base_week=-1;; esac
  case "$base_five" in ''|*[!-0-9]*) base_five=-1;; esac
  case "$cur_s" in ''|*[!0-9]*) cur_s=0;; esac
  [ $(( now - check_ts )) -lt 5 ] && emit_ok    # checked <5s ago → skip recompute
fi

# --- config resolution (ADR-098), only past the fast path ---
if [ "$is_codex" -eq 1 ]; then
  CODEX_ROOT="${CODEX_HOME:-${HOME}/.codex}"
  CFG_P="${PWD}/.codex/cruise.config.json"; CFG_M="${CODEX_ROOT}/cruise.config.json"
  CACHE_DEFAULT="${CODEX_ROOT}/quota-state.json"
else
  CFG_P="${PWD}/.claude/cruise.config.json"; CFG_M="${HOME}/.claude/cruise.config.json"
  CACHE_DEFAULT="${HOME}/.claude/quota-state.json"
fi
cfg() { # key default env
  local k="$1" d="$2" e="$3" f v
  [ -n "$e" ] && { printf '%s' "$e"; return; }
  for f in "$CFG_P" "$CFG_M"; do
    [ -r "$f" ] || continue
    command -v jq >/dev/null 2>&1 || { printf '%s' "$d"; return; }
    v=$(jq -r --arg k "$k" '.[$k] // empty' "$f" 2>/dev/null)
    case "$v" in ''|null) : ;; *) printf '%s' "$v"; return;; esac
  done
  printf '%s' "$d"
}
isint() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }
if [ ! -r "$CFG_P" ] && [ ! -r "$CFG_M" ]; then
  CACHE="${WR_QUOTA_CACHE_FILE:-$CACHE_DEFAULT}"
  HD7="${WR_QUOTA_HEADROOM_7D_PP:-5}"
  HD5="${WR_QUOTA_HEADROOM_5H_PP:-0}"
  CEIL="${WR_QUOTA_THROTTLE_MAX_SLEEP:-600}"
else
  CACHE=$(cfg cache_path "$CACHE_DEFAULT" "${WR_QUOTA_CACHE_FILE:-}")
  HD7=$(cfg headroom_7d_pp 5 "${WR_QUOTA_HEADROOM_7D_PP:-}")
  HD5=$(cfg headroom_5h_pp 0 "${WR_QUOTA_HEADROOM_5H_PP:-}")
  CEIL=$(cfg max_sleep_s 600 "${WR_QUOTA_THROTTLE_MAX_SLEEP:-}")
fi
isint "$HD7" || HD7=5
isint "$HD5" || HD5=0
isint "$CEIL" || CEIL=600

# Keep Node and app-server off the fresh-cache path. The producer's numeric
# sidecar also carries its write time, avoiding an external stat on every tool call.
pace_loaded=0; pace_written=0
if [ "$is_codex" -eq 1 ] && [ -r "${CACHE}.pace" ]; then
  read -r fu fr wu wr_ WL5 WL7 pace_written < "${CACHE}.pace" 2>/dev/null || emit_ok
  case "$pace_written" in ''|*[!0-9]*) pace_written=0;; *) pace_loaded=1;; esac
fi

# A stale cache starts one background refresh; this invocation continues against
# the last good snapshot. Legacy caches without a sidecar fall back to stat.
if [ "$is_codex" -eq 1 ]; then
  mtime="$pace_written"
  if [ "$mtime" -le 0 ]; then
    case "${OSTYPE:-}" in
      darwin*) mtime=$(/usr/bin/stat -f %m "$CACHE" 2>/dev/null);;
      *) mtime=$(/usr/bin/stat -c %Y "$CACHE" 2>/dev/null);;
    esac
  fi
  case "$mtime" in ''|*[!0-9]*) age=61;; *) age=$(( now - mtime ));; esac
  if [ "$age" -ge 60 ]; then
    lock="${CACHE}.refresh.lock"
    if mkdir "$lock" 2>/dev/null; then
      PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
      (node "$PLUGIN_ROOT/scripts/codex-quota-state.mjs" "$CACHE"; rmdir "$lock") >/dev/null 2>&1 &
    fi
  fi
fi

[ -r "$CACHE" ] || emit_ok
if [ "$pace_loaded" -ne 1 ]; then
  command -v jq >/dev/null 2>&1 || emit_ok
  read -r fu fr wu wr_ WL5 WL7 < <(
    jq -r '[.five_used_pct, .five_resets_at, .week_used_pct, .week_resets_at, (.five_window_s // 18000), (.week_window_s // 604800)] | map(tostring) | join(" ")' \
       "$CACHE" 2>/dev/null
  ) || emit_ok
fi
for v in "$fu" "$fr" "$wu" "$wr_" "$WL5" "$WL7"; do case "$v" in ''|null|*[!0-9.]*) emit_ok;; esac; done
wu=${wu%%.*}; fu=${fu%%.*}   # integer-truncate the used%

write_state() { printf '%s %s %s %s %s\n' "$now" "$base_ts" "$base_week" "$base_five" "$cur_s" > "$STATE" 2>/dev/null; }

# Position gate (needs NO rate): a window is at/over its linear pace line when
#   used·WL ≥ (100−headroom)·elapsed   [elapsed = WL − (reset−now)].
# Computed up-front so the re-baseline / too-soon paths below respect current
# position instead of blindly re-sleeping a stale cur_s (P446 sticky-recovery fix,
# 2026-07-13). reset passed (left ≤ 0) → not over-line; bad data (elapsed ≤ 0) → fails
# safe as over-line. A duration of 0 disables an absent platform window.
w_left=$(( wr_ - now )); f_left=$(( fr - now )); w_overline=0; f_overline=0
[ "$WL7" -gt 0 ] && [ "$w_left" -gt 0 ] && [ $(( wu * WL7 )) -ge $(( (100 - HD7) * (WL7 - w_left) )) ] && w_overline=1
[ "$WL5" -gt 0 ] && [ "$f_left" -gt 0 ] && [ $(( fu * WL5 )) -ge $(( (100 - HD5) * (WL5 - f_left) )) ] && f_overline=1
any_overline=0; { [ "$w_overline" -eq 1 ] || [ "$f_overline" -eq 1 ]; } && any_overline=1

# First sample (or reset baseline): record it. Position needs no burn-rate sample,
# so start minimum braking immediately when already over pace; subsequent samples
# self-calibrate it upward. Behind pace drops any stale grip at once.
if [ "$base_week" -lt 0 ] || [ "$base_ts" -le 0 ]; then
  base_ts=$now; base_week=$wu; base_five=$fu
  if [ "$any_overline" -eq 1 ]; then
    [ "$cur_s" -gt 0 ] || cur_s=10
    [ "$cur_s" -gt "$CEIL" ] && cur_s="$CEIL"
  else
    cur_s=0
  fi
  write_state
  [ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null
  emit_ok
fi

dt=$(( now - base_ts ))
if [ "$dt" -lt "$BASELINE_MIN" ]; then
  # Too soon to measure a rate → gate on position only. Behind the line → drop the
  # stale grip; still at/over it → keep the pace. (Position-only is slightly more
  # conservative than the full path: it may keep sleeping while on the line but
  # under-rate for this sub-BASELINE_MIN window — safe, only brief extra latency.)
  [ "$any_overline" -eq 1 ] || cur_s=0
  write_state
  [ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null
  emit_ok
fi

# Brake only when a window is BOTH at/over its pace line (w_overline/f_overline,
# computed up-front) AND over-rate (needs the measured Δused/dt). WITHOUT floats:
#   over-rate: Δused/dt > (100−headroom−used)/(reset−now)
#            ⟺ Δused·(reset−now) > (100−headroom−used)·dt
# While BEHIND the line you hold banked surplus — spend it, bursts don't brake.
# Braking engages as you reach the line and holds you on it; the line ends at
# (100−headroom) < 100 at reset, so you still glide to reset without exhausting.
# Extreme sustained burn that empties the surplus AND exceeds what the ceiling can
# offset still exhausts (documented P446 residual). Reset passed (left ≤ 0) → skip.
over=0
w_budget=$(( 100 - HD7 - wu )); w_dused=$(( wu - base_week ))
if [ "$w_overline" -eq 1 ] && [ "$w_dused" -gt 0 ] \
   && [ $(( w_dused * w_left )) -gt $(( (w_budget>0?w_budget:0) * dt )) ]; then over=1; fi
f_budget=$(( 100 - HD5 - fu )); f_dused=$(( fu - base_five ))
if [ "$f_overline" -eq 1 ] && [ "$f_dused" -gt 0 ] \
   && [ $(( f_dused * f_left )) -gt $(( (f_budget>0?f_budget:0) * dt )) ]; then over=1; fi

# Feedback controller. Over pace → ramp the per-call sleep up toward holding burn=safe.
# Behind pace → drop the grip to 0 AT ONCE (asymmetric recovery, P446 sticky-recovery
# fix): easing down one call at a time left a session that had banked surplus paying
# minutes of stale latency before it recovered. Dropping braking never risks
# exhaustion, and it re-engages the instant a window is over pace again.
if [ "$over" -eq 1 ]; then
  cur_s=$(( cur_s * 3 / 2 + 10 ))          # over pace → slow more
  [ "$cur_s" -gt "$CEIL" ] && cur_s="$CEIL"
else
  cur_s=0                                  # behind/under pace → full speed immediately
fi

# Slide the baseline forward so the next rate reading stays current.
if [ "$dt" -ge "$BASELINE_SLIDE" ]; then base_ts=$now; base_week=$wu; base_five=$fu; fi

write_state
[ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null
emit_ok
