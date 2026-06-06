#!/bin/bash
# Architecture - PostToolUse hook for Edit/Write
# Refreshes the stored decision hash after an allowed write to docs/decisions/.
# This prevents drift detection from invalidating the marker when creating
# new decision files that the architect just approved.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/gate-helpers.sh"

# P191 Phase 2: anchor docs/decisions on the project root, not the hook's
# runtime CWD (see architect-enforce-edit.sh). The refreshed hash must match
# the enforce gate's drift-check hash, which is now project-root-anchored.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$SESSION_ID" ] || [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only act on writes to docs/decisions/
case "$FILE_PATH" in
  */docs/decisions/*|docs/decisions/*)
    ;;
  *)
    exit 0
    ;;
esac

MARKER="/tmp/architect-reviewed-${SESSION_ID}"
HASH_FILE="/tmp/architect-reviewed-${SESSION_ID}.hash"

# Only refresh if a valid marker exists. Uses substance-aware hash
# (ADR-009 amendment 2026-06-06) and atomic-rename write (mktemp + mv).
if [ -f "$MARKER" ] && [ -f "$HASH_FILE" ]; then
  if [ -d "$PROJECT_DIR/docs/decisions" ]; then
    HASH=$(_substance_hash_path "$PROJECT_DIR/docs/decisions")
  else
    HASH="none"
  fi
  htmp="${HASH_FILE}.tmp.$$.${RANDOM:-0}"
  if printf '%s\n' "$HASH" > "$htmp" 2>/dev/null; then
    if ! mv -f "$htmp" "$HASH_FILE" 2>/dev/null; then
      rm -f "$htmp"
      echo "WARN: architect-refresh-hash atomic rename failed for ${HASH_FILE}" >&2
    fi
  else
    rm -f "$htmp"
    echo "WARN: architect-refresh-hash tempfile write failed for ${HASH_FILE}" >&2
  fi
fi

exit 0
