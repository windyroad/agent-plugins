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
# Cache (flat; written by the self-installed statusline producer — ADR-097 —
# and the shipped reality both Release-1 and this hook read):
#   {"five_used_pct":N,"five_resets_at":<epoch>,
#    "week_used_pct":N,"week_resets_at":<epoch>}
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
command -v jq >/dev/null 2>&1 || emit_ok

FIVE_W=18000; WEEK_W=604800
BASELINE_MIN=60      # need ≥60s between baseline samples to read a burn rate through integer usage%
BASELINE_SLIDE=300   # slide the baseline forward once it ages past 5min (keeps the rate current)

# Per-session state (concurrency, STORY-042): one file per session so N concurrent
# sessions each keep full throttle grip while the shared cache coordinates aggregate burn.
sid="${CLAUDE_SESSION_ID:-shared}"
STATE="${WR_QUOTA_MARKER:-${TMPDIR:-/tmp}/wr-quota-throttle-${sid}}"

now=$(date +%s 2>/dev/null) || emit_ok
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
CFG_P="${PWD}/.claude/cruise.config.json"; CFG_M="${HOME}/.claude/cruise.config.json"
cfg() { # key default env
  local k="$1" d="$2" e="$3" f v
  [ -n "$e" ] && { printf '%s' "$e"; return; }
  for f in "$CFG_P" "$CFG_M"; do
    [ -r "$f" ] || continue
    v=$(jq -r --arg k "$k" '.[$k] // empty' "$f" 2>/dev/null)
    case "$v" in ''|null) : ;; *) printf '%s' "$v"; return;; esac
  done
  printf '%s' "$d"
}
isint() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }
CACHE=$(cfg cache_path "${HOME}/.claude/quota-state.json" "${WR_QUOTA_CACHE_FILE:-}")
HD7=$(cfg headroom_7d_pp 5 "${WR_QUOTA_HEADROOM_7D_PP:-}");  isint "$HD7" || HD7=5
HD5=$(cfg headroom_5h_pp 0 "${WR_QUOTA_HEADROOM_5H_PP:-}");  isint "$HD5" || HD5=0
CEIL=$(cfg max_sleep_s 600 "${WR_QUOTA_THROTTLE_MAX_SLEEP:-}"); isint "$CEIL" || CEIL=600

[ -r "$CACHE" ] || emit_ok
read -r fu fr wu wr_ < <(
  jq -r '[.five_used_pct, .five_resets_at, .week_used_pct, .week_resets_at] | map(tostring) | join(" ")' \
     "$CACHE" 2>/dev/null
) || emit_ok
for v in "$fu" "$fr" "$wu" "$wr_"; do case "$v" in ''|null|*[!0-9.]*) emit_ok;; esac; done
wu=${wu%%.*}; fu=${fu%%.*}   # integer-truncate the used%

write_state() { printf '%s %s %s %s %s\n' "$now" "$base_ts" "$base_week" "$base_five" "$cur_s" > "$STATE" 2>/dev/null; }

# First sample (or reset baseline): record it, no rate yet → hold current sleep.
if [ "$base_week" -lt 0 ] || [ "$base_ts" -le 0 ]; then
  base_ts=$now; base_week=$wu; base_five=$fu; write_state
  [ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null   # keep any established pace while re-baselining
  emit_ok
fi

dt=$(( now - base_ts ))
if [ "$dt" -lt "$BASELINE_MIN" ]; then
  write_state                     # too soon to re-measure; keep sleeping the current amount
  [ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null
  emit_ok
fi

# Brake only when a window is BOTH over-rate AND at/over its linear pace line
# (P446 second dimension — deficit-aware, 2026-07-13). WITHOUT floats:
#   over-rate:    Δused/dt > (100−headroom−used)/(reset−now)
#               ⟺ Δused·(reset−now) > (100−headroom−used)·dt
#   at/over line: used ≥ (100−headroom)·elapsed/WL   [elapsed = WL − (reset−now)]
#               ⟺ used·WL ≥ (100−headroom)·elapsed
# While BEHIND the line you hold banked surplus (used less than the even-glide
# target) — spend it, bursts don't brake. Braking engages as you reach the line and
# holds you on it; the line ends at (100−headroom) < 100 at reset, so you still glide
# to reset without exhausting. Extreme sustained burn that empties the surplus AND
# exceeds what the ceiling can offset still exhausts (documented P446 residual).
# A window whose reset has passed (reset−now ≤ 0) is unconstrained (skip). Bad data
# (reset further than a window length → elapsed ≤ 0) fails safe: reads as over-line.
# ponytail: WL are the platform's rolling-window lengths; update if Anthropic changes them.
WL7=604800; WL5=18000          # 7-day / 5-hour window lengths (seconds)
over=0
w_left=$(( wr_ - now )); w_budget=$(( 100 - HD7 - wu )); w_dused=$(( wu - base_week )); w_elapsed=$(( WL7 - w_left ))
if [ "$w_left" -gt 0 ] && [ "$w_dused" -gt 0 ] \
   && [ $(( wu * WL7 )) -ge $(( (100 - HD7) * w_elapsed )) ] \
   && [ $(( w_dused * w_left )) -gt $(( (w_budget>0?w_budget:0) * dt )) ]; then over=1; fi
f_left=$(( fr - now )); f_budget=$(( 100 - HD5 - fu )); f_dused=$(( fu - base_five )); f_elapsed=$(( WL5 - f_left ))
if [ "$f_left" -gt 0 ] && [ "$f_dused" -gt 0 ] \
   && [ $(( fu * WL5 )) -ge $(( (100 - HD5) * f_elapsed )) ] \
   && [ $(( f_dused * f_left )) -gt $(( (f_budget>0?f_budget:0) * dt )) ]; then over=1; fi

# Feedback controller: ramp the per-call sleep toward holding burn = safe.
if [ "$over" -eq 1 ]; then
  cur_s=$(( cur_s * 3 / 2 + 10 ))          # over pace → slow more
  [ "$cur_s" -gt "$CEIL" ] && cur_s="$CEIL"
else
  cur_s=$(( cur_s * 2 / 3 - 10 ))          # on/under pace → ease off
  [ "$cur_s" -lt 0 ] && cur_s=0
fi

# Slide the baseline forward so the next rate reading stays current.
if [ "$dt" -ge "$BASELINE_SLIDE" ]; then base_ts=$now; base_week=$wu; base_five=$fu; fi

write_state
[ "$cur_s" -gt 0 ] && sleep "$cur_s" 2>/dev/null
emit_ok
