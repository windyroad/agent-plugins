#!/bin/bash
# TDD - PreToolUse enforcement hook (Edit|Write)
# Blocks implementation file edits unless state is RED or GREEN.
# Test files and exempt files are always allowed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"

# Skip if no test script configured
if ! tdd_has_test_script; then
  exit 0
fi

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [ -z "$SESSION_ID" ]; then
  # Fail-closed: cannot check state without session ID
  tdd_deny_json "BLOCKED: Could not determine session ID. TDD gate is fail-closed."
  exit 0
fi

# Classify the file
FILE_TYPE=$(tdd_classify_file "$FILE_PATH")

# Test and exempt files are always allowed
if [ "$FILE_TYPE" != "impl" ]; then
  exit 0
fi

# Check state for implementation files
STATE=$(tdd_read_state "$SESSION_ID")
BASENAME=$(basename "$FILE_PATH")

case "$STATE" in
  RED|GREEN)
    # Allowed: agent is in the TDD cycle
    exit 0
    ;;
  IDLE)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- no tests written yet. TDD state is IDLE. You MUST write a failing test first (*.test.ts or *.spec.ts) before editing implementation files. The test should describe the behavior you want to implement."
    exit 0
    ;;
  BLOCKED)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- test runner is in error state. TDD state is BLOCKED. Fix the test setup first (check test configuration, fix syntax errors in test files, or verify the test command works)."
    exit 0
    ;;
  *)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- unknown TDD state '${STATE}'. Write a failing test first."
    exit 0
    ;;
esac
