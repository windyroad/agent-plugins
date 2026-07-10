#!/usr/bin/env bash
# quota-state-producer-install.sh — SessionStart hook (P160/P443/ADR-097/STORY-043).
# @jtbd JTBD-010
#
# Self-installs the quota-state PRODUCER: the throttle (quota-pace-throttle.sh)
# reads ~/.claude/quota-state.json, but only a statusline receives Claude Code's
# `.rate_limits`, and a plugin cannot ship the statusLine settings key — so cruise
# writes the user's statusline for them (ADR-097: implied-at-install consent; the
# reversal is uninstall — NO separate opt-out; pacing is disabled via config
# max_sleep_s: 0, and the glide never blocks so there is nothing to escape).
#
# Idempotent + fail-SAFE: a SessionStart hook must never break the session. Every
# abnormal path is a silent no-op. Cases:
#   - statusline already writes the cache (grep quota-state.json)  → no-op
#   - statusline ABSENT                                            → create it + wire settings.json
#   - statusline PRESENT but not a producer                        → agent-merge nudge (once)
#
# Build note (STORY-043): ADR-097's indicative shape said "guarded-append" for the
# present case, but a present statusline has already consumed stdin, so an appended
# stdin-reading block would run with no payload (broken). Agent-merge (human-watched
# integration into the existing stdin handling) is the safe realisation; blind-append
# is deliberately NOT done.
#
# ponytail: pure detection + at most one atomic file create + one jq settings-merge;
# never edits an existing statusline in place.

set +e
emit_plain() { exit 0; }
command -v jq >/dev/null 2>&1 || emit_plain

CLAUDE_DIR="${HOME}/.claude"
SL="${CLAUDE_DIR}/statusline-command.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"
CACHE_NAME="quota-state.json"
SENTINEL="@windyroad/cruise (quota pacing)"
NUDGE_MARKER="${CLAUDE_DIR}/.cruise-producer-merge-nudged"
[ -d "$CLAUDE_DIR" ] || emit_plain

log() { printf 'cruise: %s\n' "$1" >&2; }   # SessionStart stderr is a visible, non-breaking log

# --- case 1: already a producer (our block, or any statusline that writes the cache) → no-op
if [ -f "$SL" ] && grep -q "$CACHE_NAME" "$SL" 2>/dev/null; then
  emit_plain
fi

# The managed producer block (flat schema, matching the throttle + shipped cache).
producer_block() {
  cat <<'BLOCK'
# >>> @windyroad/cruise (quota pacing) — managed, do not edit >>>
# Flattens Claude Code's .rate_limits stdin into ~/.claude/quota-state.json for the
# cruise throttle. Reads stdin once into $CRUISE_IN; if your statusline also reads
# stdin, integrate this using your existing captured input instead of re-reading.
CRUISE_IN="${CRUISE_IN:-$(cat)}"
if command -v jq >/dev/null 2>&1; then
  _cf=$(printf '%s' "$CRUISE_IN" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
  _cfr=$(printf '%s' "$CRUISE_IN" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
  _cw=$(printf '%s' "$CRUISE_IN" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
  _cwr=$(printf '%s' "$CRUISE_IN" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)
  if [ -n "$_cf" ] && [ -n "$_cw" ]; then
    _ctmp="$HOME/.claude/quota-state.json.$$.tmp"
    printf '{"five_used_pct":%s,"five_resets_at":%s,"week_used_pct":%s,"week_resets_at":%s}\n' \
      "$_cf" "${_cfr:-0}" "$_cw" "${_cwr:-0}" > "$_ctmp" 2>/dev/null && mv -f "$_ctmp" "$HOME/.claude/quota-state.json" 2>/dev/null
  fi
fi
# <<< @windyroad/cruise <<<
BLOCK
}

# --- case 2: no statusline → create one (producer + minimal display) + wire settings.json
if [ ! -f "$SL" ]; then
  {
    printf '#!/usr/bin/env bash\n'
    producer_block
    printf 'printf "cruise ✓"\n'   # minimal display; the user can replace it (the block above is what matters)
  } > "$SL" 2>/dev/null && chmod +x "$SL" 2>/dev/null || emit_plain

  # wire settings.json statusLine.command (only if not already set), atomically
  if [ -f "$SETTINGS" ]; then
    _stmp="${SETTINGS}.$$.tmp"
    jq --arg c "$SL" '.statusLine //= {"type":"command","command":$c}' "$SETTINGS" > "$_stmp" 2>/dev/null \
      && mv -f "$_stmp" "$SETTINGS" 2>/dev/null || rm -f "$_stmp" 2>/dev/null
  else
    printf '{"statusLine":{"type":"command","command":"%s"}}\n' "$SL" > "$SETTINGS" 2>/dev/null
  fi
  log "created $SL + wired statusLine (quota producer installed)"
  emit_plain
fi

# --- case 3: statusline present but not a producer → agent-merge nudge (once, non-breaking)
if [ ! -f "$NUDGE_MARKER" ]; then
  : > "$NUDGE_MARKER" 2>/dev/null
  _ctx="@windyroad/cruise needs a quota-state producer, but ~/.claude/statusline-command.sh already exists and does not write ~/.claude/quota-state.json. Do NOT blind-append it (the statusline reads stdin once). Carefully integrate this block into the existing statusline — reuse its already-captured stdin variable instead of the block's \$(cat) — then confirm with the user:

$(producer_block)"
  jq -n --arg ctx "$_ctx" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' 2>/dev/null \
    || emit_plain
  exit 0
fi
emit_plain
