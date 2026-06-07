#!/bin/bash
# Shared gate logic for architect enforcement hooks.
# Sourced by architect-enforce-edit.sh and architect-plan-enforce.sh.
# Provides: check_architect_gate

# Source shared portable helpers (_mtime, _hashcmd)
_ARCHITECT_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_ARCHITECT_GATE_DIR/gate-helpers.sh"

# Check architect gate marker. Returns 0 if marker is valid (allow), 1 if invalid (deny).
# Sets ARCHITECT_GATE_REASON on failure with an explicit recovery directive
# naming the wr-architect:agent subagent_type (P215 / RFC-021 — mirrors the
# sibling REVIEW_GATE_REASON pattern in review-gate.sh). Downstream
# enforcement hooks (architect-enforce-edit.sh, architect-plan-enforce.sh)
# append this reason to their BLOCKED deny message so the agent sees a clear
# recovery affordance without having to read source.
# Usage: check_architect_gate "$SESSION_ID"
check_architect_gate() {
  local SESSION_ID="$1"
  local MARKER="/tmp/architect-reviewed-${SESSION_ID}"
  local TTL_SECONDS="${ARCHITECT_TTL:-3600}"
  # P191 Phase 2: anchor the docs/decisions drift-hash on the project root,
  # not the hook's runtime CWD (see architect-enforce-edit.sh for rationale).
  local PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

  if [ -n "$SESSION_ID" ] && [ -f "$MARKER" ]; then
    local NOW=$(date +%s)
    local MARKER_TIME=$(_mtime "$MARKER")
    local AGE=$(( NOW - MARKER_TIME ))
    if [ "$AGE" -lt "$TTL_SECONDS" ]; then
      # TTL still valid -- check for decision drift via substance-aware hash
      # (ADR-009 amendment 2026-06-06: trivial whitespace / line-ending /
      # trailing-newline edits do NOT trigger drift; substantive policy
      # changes DO. Conservative boundary — ambiguous edits stay
      # substantive. See gate-helpers.sh::_substance_hash_path).
      local HASH_FILE="/tmp/architect-reviewed-${SESSION_ID}.hash"
      if [ -f "$HASH_FILE" ]; then
        local STORED=$(cat "$HASH_FILE")
        local CURRENT
        if [ -d "$PROJECT_DIR/docs/decisions" ]; then
          CURRENT=$(_substance_hash_path "$PROJECT_DIR/docs/decisions")
        else
          CURRENT="none"
        fi
        if [ "$STORED" != "$CURRENT" ]; then
          rm -f "$MARKER" "$HASH_FILE"
          ARCHITECT_GATE_REASON="Decision drift detected — docs/decisions/ changed substantively since the last architect review. Re-delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') to refresh the marker."
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
      ARCHITECT_GATE_REASON="Architect review expired (${AGE}s old, TTL ${TTL_SECONDS}s). Re-delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') to refresh the marker."
      return 1  # TTL expired, deny
    fi
  fi

  ARCHITECT_GATE_REASON="No architect review marker found for this session. Delegate to wr-architect:agent via the Agent tool (subagent_type: 'wr-architect:agent') so the architect can review and create the marker."
  return 1  # No marker, deny
}

# Emit fail-closed deny JSON for parse failures
architect_gate_parse_error() {
  cat <<'EOF'
{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Could not parse hook input. Gate is fail-closed." } }
EOF
}
