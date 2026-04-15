#!/bin/bash
# PostToolUse hook: Manages the WIP-reviewed marker.
# - After Edit/Write on non-doc files: clears the marker (blocks next edit)
# - After Agent (risk-scorer) completion: creates the marker (unblocks next edit)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
_enable_err_trap

_parse_input

TOOL_NAME=$(_get_tool_name)
SESSION_ID=$(_get_session_id)
[ -n "$SESSION_ID" ] || exit 0

MARKER="$(_risk_dir "$SESSION_ID")/wip-reviewed"

# WIP marker persists after assessment — allows multiple edits.
# Marker lifecycle: TTL + drift detection (ADR-009).
# Agent case (marker creation) handled by risk-score-mark.sh.

exit 0
