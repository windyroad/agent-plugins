#!/bin/bash
# Consume a checkout-bound Codex SubagentStop receipt in the parent session.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"
_parse_input

TOOL_NAME="$(_get_tool_name)"
EVENT_NAME="$(printf '%s' "$_HOOK_INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("hook_event_name", ""))' 2>/dev/null || true)"
[ "$TOOL_NAME" = "Bash" ] || [ "$EVENT_NAME" = "UserPromptSubmit" ] || exit 0
_enter_hook_cwd || exit 0
printf '%s' "$_HOOK_INPUT" | node "$SCRIPT_DIR/codex-agent-completion.mjs" --consume-pending
