#!/bin/bash
# PreToolUse hook: Denies Edit/Write to RISK-POLICY.md unless the
# /risk-policy skill has been engaged (marker file exists).
# Mirrors: architect-enforce-edit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
_enable_err_trap

_parse_input

FILE_PATH=$(_get_file_path)
SESSION_ID=$(_get_session_id)

if [ -z "$SESSION_ID" ] || [ -z "$FILE_PATH" ]; then
  exit 0
fi

# P004: Only gate files inside the project root.
case "$FILE_PATH" in
  /*)
    case "$FILE_PATH" in
      "$PWD"/*) ;;
      *) exit 0 ;;
    esac
    ;;
esac

# Only gate RISK-POLICY.md
BASENAME=$(basename "$FILE_PATH")
if [ "$BASENAME" != "RISK-POLICY.md" ]; then
  exit 0
fi

# Check for marker
MARKER="$(_risk_dir "$SESSION_ID")/policy-reviewed"
if [ -f "$MARKER" ]; then
  exit 0
fi

_governance_advisory "Review receipt unavailable; required substantive review remains the agent's responsibility."
exit 0
