#!/bin/bash
# JTBD - PostToolUse:Agent|Bash slide-marker hook (P111).
# Slides the parent session's existing jtbd-reviewed marker forward on
# subprocess return, treating subprocess wall-clock as continuous parent-
# session work for TTL purposes. Only TOUCHES an existing marker — never
# creates one (creation requires a real JTBD review parsed from the agent's
# verdict file in jtbd-mark-reviewed.sh).
#
# See ADR-009 "Subprocess-boundary refresh" and P111 for context. Failed
# subprocesses (tool_response.is_error=true) do NOT extend the trust window
# — see slide_marker_on_subprocess_return in lib/gate-helpers.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

slide_marker_on_subprocess_return "/tmp/jtbd-reviewed-${SESSION_ID}"
slide_marker_on_subprocess_return "/tmp/jtbd-plan-reviewed-${SESSION_ID}"

exit 0
