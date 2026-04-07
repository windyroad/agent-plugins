#!/bin/bash
# TDD - Stop hook
# Cleans up TDD marker files when the session ends.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -n "$SESSION_ID" ]; then
  tdd_cleanup "$SESSION_ID"
fi

exit 0
