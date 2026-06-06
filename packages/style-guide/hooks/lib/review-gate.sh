#!/bin/bash
# Shared gate logic for review enforcement hooks (a11y, voice-tone, style-guide).
# Sourced by *-enforce-edit.sh hooks and review-plan-enforce.sh.
# Provides: check_review_gate, review_gate_deny, review_gate_parse_error

# Source shared portable helpers (_mtime, _hashcmd)
_REVIEW_GATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_REVIEW_GATE_DIR/gate-helpers.sh"

# Check review gate marker. Returns 0 if marker is valid (allow), 1 if invalid (deny).
# Sets REVIEW_GATE_REASON on failure.
# Usage: check_review_gate "$SESSION_ID" "style-guide" "docs/STYLE-GUIDE.md"
check_review_gate() {
  local SESSION_ID="$1"
  local SYSTEM="$2"        # e.g., "a11y", "voice-tone", "style-guide"
  local POLICY_FILE="$3"   # e.g., "docs/STYLE-GUIDE.md"
  local MARKER="/tmp/${SYSTEM}-reviewed-${SESSION_ID}"
  local HASH_FILE="/tmp/${SYSTEM}-reviewed-${SESSION_ID}.hash"
  local TTL_SECONDS="${REVIEW_TTL:-3600}"

  # 1. Marker must exist
  if [ ! -f "$MARKER" ]; then
    REVIEW_GATE_REASON="No ${SYSTEM} review marker found. The ${SYSTEM} agent must review first."
    return 1
  fi

  # 2. TTL check — marker mtime must be within TTL
  local NOW=$(date +%s)
  local MARKER_TIME=$(_mtime "$MARKER")
  local AGE=$(( NOW - MARKER_TIME ))
  if [ "$AGE" -ge "$TTL_SECONDS" ]; then
    rm -f "$MARKER" "$HASH_FILE"
    REVIEW_GATE_REASON="${SYSTEM} review expired (${AGE}s old, TTL ${TTL_SECONDS}s). Re-run the ${SYSTEM} agent."
    return 1
  fi

  # 3. Drift detection — substance-aware policy hash must match
  # (ADR-009 amendment 2026-06-06: trivial whitespace / line-ending /
  # trailing-newline edits do NOT trigger drift; substantive policy
  # changes DO. Conservative boundary — ambiguous edits stay substantive.
  # See gate-helpers.sh::_substance_hash_path.)
  if [ -f "$HASH_FILE" ] && [ -n "$POLICY_FILE" ]; then
    local STORED_HASH=$(cat "$HASH_FILE")
    local CURRENT_HASH
    CURRENT_HASH=$(_substance_hash_path "$POLICY_FILE")
    if [ "$STORED_HASH" != "$CURRENT_HASH" ]; then
      rm -f "$MARKER" "$HASH_FILE"
      REVIEW_GATE_REASON="${SYSTEM} policy file changed since last review. Re-run the ${SYSTEM} agent."
      return 1
    fi
  fi

  # Slide TTL window forward
  touch "$MARKER"
  return 0
}

# Store policy file hash after a successful review.
# Routes the marker + hash write through `_atomic_mark_with_hash` so a PASS
# never silently fails to persist (ADR-009 amendment 2026-06-06: closes the
# "marker doesn't land after PASS" failure mode P353 measured as ~12
# subagent invocations + 3 BYPASS_RISK_GATE=1 uses per 3-filing session).
# Usage: store_review_hash "$SESSION_ID" "style-guide" "docs/STYLE-GUIDE.md"
store_review_hash() {
  local SESSION_ID="$1"
  local SYSTEM="$2"
  local POLICY_FILE="$3"
  local MARKER="/tmp/${SYSTEM}-reviewed-${SESSION_ID}"

  if [ -n "$POLICY_FILE" ]; then
    local HASH
    HASH=$(_substance_hash_path "$POLICY_FILE")
    # Atomic: marker + hash either both land or neither does.
    if ! _atomic_mark_with_hash "$MARKER" "$HASH"; then
      # Diagnostic on failure — surface the silent-fail mode the
      # pre-amendment `touch + echo > .hash` pair hid.
      echo "WARN: ${SYSTEM}-mark-reviewed atomic marker-write failed for ${MARKER}" >&2
      return 1
    fi
  fi
  return 0
}

# Emit fail-closed deny JSON for PreToolUse hooks.
review_gate_deny() {
  local REASON="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "$REASON"
  }
}
EOF
}

# Emit fail-closed deny JSON for parse failures.
review_gate_parse_error() {
  cat <<'EOF'
{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Could not parse hook input. Gate is fail-closed." } }
EOF
}
