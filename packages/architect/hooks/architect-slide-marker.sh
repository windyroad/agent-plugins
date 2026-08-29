#!/bin/bash
# Architecture - PostToolUse:Agent|Bash|Skill slide-marker hook (P111 + P213).
# Slides the parent session's existing architect-reviewed marker forward on
# subprocess return, treating subprocess wall-clock as continuous parent-
# session work for TTL purposes. It only TOUCHES existing architecture-review
# markers. P368 also lets an exact successful oversight-helper event create
# its separate document-and-session evidence marker.
#
# This addresses P111 / ADR-009 "Subprocess-boundary refresh": Agent, Bash,
# and Skill tool calls that wrap long-running subprocesses (other subagents,
# `claude -p` iteration subprocesses, run_in_background completions, or
# /wr-*:assess-* sibling-assessor SKILLs run by the AFK orchestrator) would
# otherwise let the parent's marker age past TTL even though the parent is
# still actively working through the subprocess. The Skill matcher coverage
# is the 2026-06-08 P213 amendment (Option D).
#
# Failed subprocesses (tool_response.is_error=true) do NOT extend the trust
# window — see slide_marker_on_subprocess_return in lib/gate-helpers.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

SESSION_ID=$(_get_session_id)

# P368: the successful standalone helper invocation and its PostToolUse event
# are the only place where the confirming session id and artefact path coexist.
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
            and argv[0] == "wr-architect-mark-oversight-confirmed"):
        print(argv[1])
except Exception:
    pass
' 2>/dev/null)

if [ -n "$OVERSIGHT_PATH" ]; then
  if [ -z "$SESSION_ID" ]; then
    echo "wr-architect-mark-oversight-confirmed: missing session id; no oversight marker written" >&2
  else
    ABS_DIR="$(cd "$(dirname "$OVERSIGHT_PATH")" 2>/dev/null && pwd)" || ABS_DIR=""
    ABS_PATH="${ABS_DIR:+$ABS_DIR/}$(basename "$OVERSIGHT_PATH")"
    case "$ABS_PATH" in
      */docs/decisions/*.md)
        if command -v sha256sum >/dev/null 2>&1; then
          PATH_HASH=$(printf '%s' "$ABS_PATH" | sha256sum | cut -d' ' -f1 | cut -c1-16)
        elif command -v shasum >/dev/null 2>&1; then
          PATH_HASH=$(printf '%s' "$ABS_PATH" | shasum -a 256 | cut -d' ' -f1 | cut -c1-16)
        else
          echo "wr-architect-mark-oversight-confirmed: no SHA-256 utility; no oversight marker written" >&2
          PATH_HASH=""
        fi
        if [ -n "$PATH_HASH" ] && ! : > "${SESSION_MARKER_DIR:-/tmp}/oversight-confirmed-${PATH_HASH}-${SESSION_ID}"; then
          echo "wr-architect-mark-oversight-confirmed: marker write failed" >&2
        fi
        ;;
      *) echo "wr-architect-mark-oversight-confirmed: invalid ADR path; no oversight marker written" >&2 ;;
    esac
  fi
fi

[ -n "$SESSION_ID" ] || exit 0

slide_marker_on_subprocess_return "/tmp/architect-reviewed-${SESSION_ID}"
slide_marker_on_subprocess_return "/tmp/architect-plan-reviewed-${SESSION_ID}"

exit 0
