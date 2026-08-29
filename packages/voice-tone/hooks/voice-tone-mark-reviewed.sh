#!/bin/bash
# Voice & Tone - PostToolUse hook for Agent tool
# Creates a session marker when voice-and-tone-lead has been consulted with PASS verdict.
# This marker unlocks the voice-tone-enforce-edit.sh PreToolUse block.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/review-gate.sh"

_parse_input

[ "$(_get_tool_name)" = "Agent" ] || exit 0
SUBAGENT=$(_get_subagent_type)
SESSION_ID=$(_get_session_id)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

case "$SUBAGENT" in
  *voice-and-tone-lead*|*wr-voice-tone*)
    HEADING=$(printf '%s\n' "$(_get_tool_output)" \
      | sed -nE 's/^[[:space:]]*>?[[:space:]]*\*\*(Voice \& Tone Review: (PASS|VIOLATIONS FOUND|GUIDE UPDATE NEEDED))\*\*.*/\1/p' \
      | head -n 1)

    case "$HEADING" in
      "Voice & Tone Review: PASS")
        touch "/tmp/voice-tone-reviewed-${SESSION_ID}"
        store_review_hash "$SESSION_ID" "voice-tone" "docs/VOICE-AND-TONE.md"
        touch "/tmp/voice-tone-plan-reviewed-${SESSION_ID}"
        ;;
      *)
        # Fail closed: issues and unparseable output do not unlock edits.
        ;;
    esac
    ;;
esac

exit 0
