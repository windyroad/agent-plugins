#!/bin/bash
# JTBD - PostToolUse:Agent|Bash|Skill slide-marker hook (P111 + P213).
# Slides the parent session's existing jtbd-reviewed marker forward on
# subprocess return, treating subprocess wall-clock as continuous parent-
# session work for TTL purposes. It only TOUCHES existing JTBD-review markers.
# P368 also lets an exact successful oversight-helper event create its separate
# document-and-session evidence marker.
#
# See ADR-009 "Subprocess-boundary refresh" and P111 for context. Failed
# subprocesses (tool_response.is_error=true) do NOT extend the trust window
# — see slide_marker_on_subprocess_return in lib/gate-helpers.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

SESSION_ID=$(_get_session_id)

# P368: bind oversight evidence to the exact successful Bash event rather
# than guessing from the set of recently announced sessions.
OVERSIGHT_PATH=$(printf '%s' "$_HOOK_INPUT" | python3 -c '
import json, shlex, sys
try:
    data = json.load(sys.stdin)
    response = data.get("tool_response", {})
    argv = shlex.split(data.get("tool_input", {}).get("command", ""))
    if (data.get("tool_name") == "Bash"
            and isinstance(response, dict)
            and response.get("is_error") is not True
            and len(argv) == 2
            and argv[0] == "wr-jtbd-mark-oversight-confirmed"):
        print(argv[1])
except Exception:
    pass
' 2>/dev/null)

if [ -n "$OVERSIGHT_PATH" ]; then
  if [ -z "$SESSION_ID" ]; then
    echo "wr-jtbd-mark-oversight-confirmed: missing session id; no oversight marker written" >&2
  else
    ABS_DIR="$(cd "$(dirname "$OVERSIGHT_PATH")" 2>/dev/null && pwd)" || ABS_DIR=""
    ABS_PATH="${ABS_DIR:+$ABS_DIR/}$(basename "$OVERSIGHT_PATH")"
    case "$ABS_PATH" in
      */docs/jtbd/*.md|*/docs/jtbd/*/*.md)
        if command -v sha256sum >/dev/null 2>&1; then
          PATH_HASH=$(printf '%s' "$ABS_PATH" | sha256sum | cut -d' ' -f1 | cut -c1-16)
        elif command -v shasum >/dev/null 2>&1; then
          PATH_HASH=$(printf '%s' "$ABS_PATH" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
        else
          echo "wr-jtbd-mark-oversight-confirmed: no SHA-256 utility; no oversight marker written" >&2
          PATH_HASH=""
        fi
        if [ -n "$PATH_HASH" ] && ! : > "${SESSION_MARKER_DIR:-/tmp}/oversight-confirmed-${PATH_HASH}-${SESSION_ID}"; then
          echo "wr-jtbd-mark-oversight-confirmed: marker write failed" >&2
        fi
        ;;
      *) echo "wr-jtbd-mark-oversight-confirmed: invalid JTBD path; no oversight marker written" >&2 ;;
    esac
  fi
fi

[ -n "$SESSION_ID" ] || exit 0

slide_marker_on_subprocess_return "/tmp/jtbd-reviewed-${SESSION_ID}"
slide_marker_on_subprocess_return "/tmp/jtbd-plan-reviewed-${SESSION_ID}"

exit 0
