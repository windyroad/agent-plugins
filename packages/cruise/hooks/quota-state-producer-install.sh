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
# abnormal path is a non-breaking no-op after emitting pacing guidance. Cases:
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
PACING_CONTEXT='Cruise can start, stop, or change intentional tool-call delays at any time in this task. A pending call within the configured pacing ceiling is expected, not evidence that a service is unavailable or hung. Wait silently: cancelling or retrying restarts the pacing delay. Do not diagnose or send progress updates solely because of Cruise pacing. Use the Cruise status skill only when the user asks for pacing details.'
emit_context() {
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$PACING_CONTEXT"
  exit 0
}

# Codex exposes quota through app-server, not a statusline. Never mutate Claude
# config from a Codex session; initialize the Codex cache and fail open.
if [ -n "${CODEX_THREAD_ID:-}" ]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
  command -v node >/dev/null 2>&1 && node "$PLUGIN_ROOT/scripts/codex-quota-state.mjs" >/dev/null 2>&1
  emit_context
fi

command -v jq >/dev/null 2>&1 || emit_context

CLAUDE_DIR="${HOME}/.claude"
SL="${CLAUDE_DIR}/statusline-command.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"
CACHE_NAME="quota-state.json"
SENTINEL="@windyroad/cruise (quota pacing)"
NUDGE_MARKER="${CLAUDE_DIR}/.cruise-producer-merge-nudged"
[ -d "$CLAUDE_DIR" ] || emit_context

log() { printf 'cruise: %s\n' "$1" >&2; }   # SessionStart stderr is a visible, non-breaking log

# The ACTIVE statusline is whatever settings.json points at (may be a non-default
# path); fall back to the default path when nothing is configured.
CONFIGURED=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
ACTIVE="$CONFIGURED"; [ -z "$ACTIVE" ] && ACTIVE="$SL"
case "$ACTIVE" in "~/"*) ACTIVE="${HOME}/${ACTIVE#\~/}";; esac   # expand a leading ~

# --- case 1: the ACTIVE statusline already writes the cache → no-op (any path)
if [ -f "$ACTIVE" ] && grep -q "$CACHE_NAME" "$ACTIVE" 2>/dev/null; then
  emit_context
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

# --- case 2: NO statusline anywhere (none configured + default file absent) → create + wire.
# If a statusline is configured elsewhere, we must NOT create an orphan — fall to agent-merge.
if [ -z "$CONFIGURED" ] && [ ! -f "$SL" ]; then
  {
    printf '#!/usr/bin/env bash\n'
    producer_block
    printf 'printf "cruise ✓"\n'   # minimal display; the user can replace it (the block above is what matters)
  } > "$SL" 2>/dev/null && chmod +x "$SL" 2>/dev/null || emit_context

  # wire settings.json statusLine.command (only if not already set), atomically
  if [ -f "$SETTINGS" ]; then
    _stmp="${SETTINGS}.$$.tmp"
    jq --arg c "$SL" '.statusLine //= {"type":"command","command":$c}' "$SETTINGS" > "$_stmp" 2>/dev/null \
      && mv -f "$_stmp" "$SETTINGS" 2>/dev/null || rm -f "$_stmp" 2>/dev/null
  else
    printf '{"statusLine":{"type":"command","command":"%s"}}\n' "$SL" > "$SETTINGS" 2>/dev/null
  fi
  log "created $SL + wired statusLine (quota producer installed)"
  emit_context
fi

# --- case 3: statusline present but not a producer → agent-merge nudge (once, non-breaking)
if [ ! -f "$NUDGE_MARKER" ]; then
  : > "$NUDGE_MARKER" 2>/dev/null
  _ctx="$PACING_CONTEXT

@windyroad/cruise needs a quota-state producer, but your active statusline ($ACTIVE) does not write ~/.claude/quota-state.json. Do NOT blind-append it (the statusline reads stdin once). Carefully integrate this block into that statusline — reuse its already-captured stdin variable instead of the block's \$(cat) — then confirm with the user:

$(producer_block)"
  jq -n --arg ctx "$_ctx" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' 2>/dev/null \
    || emit_context
  exit 0
fi
emit_context
