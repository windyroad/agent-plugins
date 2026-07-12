#!/usr/bin/env bash
# cruise-status.sh — on-demand telemetry for the quota-pace throttle (STORY-044).
# @jtbd JTBD-010
# Reads the same cache + per-session throttle state + config the throttle uses,
# and prints a legible report: per-window pace, the sleep it is injecting right
# now, a glide projection, and a cache-health check (a stale/absent cache means
# the throttle is silently fail-open — the P160 "installed but inert" failure).
#
# Fail-safe: never errors; prints a clear "no data" report when the cache/state
# is absent. ponytail: integer arithmetic + one report.

set +e
now=$(date +%s 2>/dev/null)

if ! command -v jq >/dev/null 2>&1; then
  echo "@windyroad/cruise — jq is not installed, so the throttle is a no-op and there is no telemetry to read."
  exit 0
fi

# --- config resolution (ADR-098): env → project → machine → default ---
CFG_P="${PWD}/.claude/cruise.config.json"; CFG_M="${HOME}/.claude/cruise.config.json"
cfg() { local k="$1" d="$2" e="$3" f v; [ -n "$e" ] && { printf '%s' "$e"; return; }
  for f in "$CFG_P" "$CFG_M"; do [ -r "$f" ] || continue
    v=$(jq -r --arg k "$k" '.[$k] // empty' "$f" 2>/dev/null)
    case "$v" in ''|null) : ;; *) printf '%s' "$v"; return;; esac; done; printf '%s' "$d"; }
isint() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }
CACHE=$(cfg cache_path "${HOME}/.claude/quota-state.json" "${WR_QUOTA_CACHE_FILE:-}")
HD7=$(cfg headroom_7d_pp 5 "${WR_QUOTA_HEADROOM_7D_PP:-}"); isint "$HD7" || HD7=5
HD5=$(cfg headroom_5h_pp 0 "${WR_QUOTA_HEADROOM_5H_PP:-}"); isint "$HD5" || HD5=0
CEIL=$(cfg max_sleep_s 600 "${WR_QUOTA_THROTTLE_MAX_SLEEP:-}"); isint "$CEIL" || CEIL=600

echo "@windyroad/cruise — quota pacing status"
echo ""

# --- cache health ---
if [ ! -r "$CACHE" ]; then
  echo "  ⚠ No quota cache at $CACHE."
  echo "    The throttle is FAIL-OPEN (not pacing). Install/repair the statusline producer,"
  echo "    or run a Pro/Max session so Claude Code exposes .rate_limits to the statusline."
  exit 0
fi
mtime=$(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE" 2>/dev/null)  # GNU form first, BSD fallback
age="?"; case "$mtime" in *[!0-9]*|'') : ;; *) age=$(( now - mtime ));; esac
read -r fu fr wu wr_ < <(jq -r '[.five_used_pct,.five_resets_at,.week_used_pct,.week_resets_at]|map(tostring)|join(" ")' "$CACHE" 2>/dev/null)
for v in "$fu" "$fr" "$wu" "$wr_"; do case "$v" in ''|null|*[!0-9.]*) echo "  ⚠ Cache is malformed — throttle fail-open."; exit 0;; esac; done
fu=${fu%%.*}; wu=${wu%%.*}

# --- per-session throttle state (the sleep it's injecting now) ---
sid="${CLAUDE_SESSION_ID:-shared}"
STATE="${WR_QUOTA_MARKER:-${TMPDIR:-/tmp}/wr-quota-throttle-${sid}}"
cur_s=0 base_ts=0 base_week=-1
if [ -f "$STATE" ]; then read -r _c base_ts base_week _bf cur_s < "$STATE" 2>/dev/null
  isint "$cur_s" || cur_s=0; isint "$base_ts" || base_ts=0; fi

# --- per-window report ---
bar() { # used_pct pace_pct  → 20-cell ASCII bar (# used, - remaining, | pace line)
  local u=$(( $1*20/100 )) p=$(( $2*20/100 )) i=0 o=""
  [ "$u" -gt 20 ] && u=20; [ "$p" -gt 19 ] && p=19; [ "$p" -lt 0 ] && p=0
  while [ "$i" -lt 20 ]; do
    if [ "$i" -eq "$p" ]; then o="${o}|"; elif [ "$i" -lt "$u" ]; then o="${o}#"; else o="${o}-"; fi
    i=$(( i+1 ))
  done; printf '%s' "$o"; }

window() { # label used reset W headroom
  local label="$1" used="$2" reset="$3" W="$4" hd="$5"
  local left=$(( reset - now )); [ "$left" -lt 0 ] && left=0
  local elapsed=$(( (W-left)*100/W )); [ "$elapsed" -gt 100 ] && elapsed=100
  local pace=$(( (100-hd)*elapsed/100 )); local ahead=$(( used - pace ))
  local hrs_left=$(( left/3600 )); local hrs_x10=$(( left*10/3600 ))
  local budget=$(( 100-hd-used )); [ "$budget" -lt 0 ] && budget=0
  local sust_x10="n/a"; [ "$left" -gt 0 ] && sust_x10=$(( budget*10*3600/left ))
  local tag=""; [ "$ahead" -gt 0 ] && tag="+${ahead}pp ahead" || tag="$(( -ahead ))pp behind"
  printf "  %-14s [%s]  used %s%%  ·  pace %s%%  ·  %s\n" "$label" "$(bar "$used" "$pace")" "$used" "$pace" "$tag"
  printf "  %-14s sustainable %s.%s%%/hr  ·  resets in %s.%sh\n" "" "$((sust_x10/10))" "$((sust_x10%10))" "$((hrs_x10/10))" "$((hrs_x10%10))"
}

# governing window = the one you're more ahead on
window "5-hour window" "$fu" "$fr" 18000 "$HD5"
window "7-day window" "$wu" "$wr_" 604800 "$HD7"
echo ""

# position (used − linear pace) per window; the most-ahead window governs the label.
# The throttle is deficit-aware: it only brakes at/over the line, so the label must
# derive from real position, not from sleep>0 (P446 second dimension).
pos() { local used="$1" reset="$2" W="$3" hd="$4"; local left=$(( reset-now )); [ "$left" -lt 0 ] && left=0
  local el=$(( (W-left)*100/W )); [ "$el" -gt 100 ] && el=100; echo $(( used - (100-hd)*el/100 )); }
gov=$(pos "$fu" "$fr" 18000 "$HD5"); wpos=$(pos "$wu" "$wr_" 604800 "$HD7"); [ "$wpos" -gt "$gov" ] && gov=$wpos

# --- throttle now ---
if [ "$cur_s" -gt 0 ]; then
  if [ "$gov" -ge 0 ]; then
    echo "  Throttle now:   sleeping ${cur_s}s per tool call — holding you on the pace line (+${gov}pp) to glide to reset"
  else
    echo "  Throttle now:   sleeping ${cur_s}s per tool call — easing off ($(( -gov ))pp behind pace, sleep winding down)"
  fi
elif [ "$gov" -ge 0 ]; then
  echo "  Throttle now:   idle (0s) — on the pace line, full speed"
else
  echo "  Throttle now:   idle (0s) — $(( -gov ))pp behind pace, full speed"
fi

# --- projection (measured burn vs sustainable, 7d — the scarce window) ---
if [ "$base_week" -ge 0 ] && [ "$base_ts" -gt 0 ] && [ $(( now-base_ts )) -ge 60 ] && [ "$wu" -gt "$base_week" ]; then
  dt=$(( now-base_ts )); r_x1000=$(( (wu-base_week)*1000*3600/dt ))     # measured %/hr ×1000
  wleft=$(( wr_-now )); [ "$wleft" -lt 1 ] && wleft=1
  safe_x1000=$(( (100-HD7-wu>0?100-HD7-wu:0)*1000*3600/wleft ))
  if [ "$r_x1000" -le "$safe_x1000" ]; then
    echo "  Projection:     at your measured burn (~$((r_x1000/1000)).$(( (r_x1000/100)%10 ))%/hr) you glide to the 7d reset with headroom ✓"
  else
    echo "  Projection:     measured burn (~$((r_x1000/1000)).$(( (r_x1000/100)%10 ))%/hr) exceeds the sustainable rate — the throttle is slowing you toward it"
  fi
else
  echo "  Projection:     not enough burn samples yet this session to project."
fi

# --- config + health ---
fresh="fresh"; case "$age" in *[!0-9]*) fresh="age unknown";; *) [ "$age" -gt 1800 ] && fresh="⚠ STALE (${age}s — throttle fail-open)" || fresh="fresh (${age}s ago)";; esac
echo "  Config:         headroom 5h=${HD5}pp 7d=${HD7}pp  ·  ceiling ${CEIL}s  ·  cache ${fresh}"
