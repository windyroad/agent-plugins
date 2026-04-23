#!/bin/bash
# Shared gate logic for architect enforcement hooks.
# Sourced by architect-enforce-edit.sh and architect-plan-enforce.sh.
# Provides: check_architect_gate

# Source shared portable helpers (_mtime, _hashcmd)
_ARCHITECT_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_ARCHITECT_GATE_DIR/gate-helpers.sh"

# Check architect gate marker. Returns 0 if marker is valid (allow), 1 if invalid (deny).
# Usage: check_architect_gate "$SESSION_ID"
check_architect_gate() {
  local SESSION_ID="$1"
  local MARKER="/tmp/architect-reviewed-${SESSION_ID}"
  local TTL_SECONDS="${ARCHITECT_TTL:-3600}"

  if [ -n "$SESSION_ID" ] && [ -f "$MARKER" ]; then
    local NOW=$(date +%s)
    local MARKER_TIME=$(_mtime "$MARKER")
    local AGE=$(( NOW - MARKER_TIME ))
    if [ "$AGE" -lt "$TTL_SECONDS" ]; then
      # TTL still valid -- check for decision drift
      local HASH_FILE="/tmp/architect-reviewed-${SESSION_ID}.hash"
      if [ -f "$HASH_FILE" ]; then
        local STORED=$(cat "$HASH_FILE")
        local CURRENT
        if [ -d "docs/decisions" ]; then
          CURRENT=$(find docs/decisions -name '*.md' -not -name 'README.md' -print0 | sort -z | xargs -0 cat 2>/dev/null | _hashcmd | cut -d' ' -f1)
        else
          CURRENT="none"
        fi
        if [ "$STORED" != "$CURRENT" ]; then
          rm -f "$MARKER" "$HASH_FILE"
          return 1  # Drift detected, deny
        else
          touch "$MARKER"  # Slide TTL window forward
          return 0  # Valid, allow
        fi
      else
        touch "$MARKER"  # Slide TTL window forward
        return 0  # No hash = old marker format, allow
      fi
    else
      rm -f "$MARKER"
      return 1  # TTL expired, deny
    fi
  fi

  return 1  # No marker, deny
}

# Emit fail-closed deny JSON for parse failures
architect_gate_parse_error() {
  cat <<'EOF'
{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Could not parse hook input. Gate is fail-closed." } }
EOF
}
