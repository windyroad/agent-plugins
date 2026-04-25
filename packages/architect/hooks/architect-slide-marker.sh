#!/bin/bash
# Architecture - PostToolUse:Agent|Bash slide-marker hook (P111).
# Slides the parent session's existing architect-reviewed marker forward on
# subprocess return, treating subprocess wall-clock as continuous parent-
# session work for TTL purposes. Only TOUCHES an existing marker — never
# creates one (creation requires a real architect review parsed from the
# agent's verdict text in architect-mark-reviewed.sh).
#
# This addresses P111 / ADR-009 "Subprocess-boundary refresh": Agent and Bash
# tool calls that wrap long-running subprocesses (other subagents, `claude
# -p` iteration subprocesses, run_in_background completions) would otherwise
# let the parent's marker age past TTL even though the parent is still
# actively working through the subprocess.
#
# Failed subprocesses (tool_response.is_error=true) do NOT extend the trust
# window — see slide_marker_on_subprocess_return in lib/gate-helpers.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

_parse_input

SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

slide_marker_on_subprocess_return "/tmp/architect-reviewed-${SESSION_ID}"
slide_marker_on_subprocess_return "/tmp/architect-plan-reviewed-${SESSION_ID}"

exit 0
