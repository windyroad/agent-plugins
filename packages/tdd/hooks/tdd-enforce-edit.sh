#!/bin/bash
# TDD - PreToolUse enforcement hook (Edit|Write)
# Blocks implementation file edits unless the associated test's state is RED or GREEN.
# Test files and exempt files are always allowed.
# Per-file state: a failing Countdown test does NOT block editing Hero.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$FILE_PATH" ]; then
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

# Classify first, then check test script (only impl files need gating)
FILE_TYPE=$(tdd_classify_file "$FILE_PATH")
if [ "$FILE_TYPE" != "impl" ]; then
  exit 0
fi

# If no test script configured, check if setup skill is running
if ! tdd_has_test_script; then
  # Allow edits if the setup skill is actively running (chicken-and-egg bypass)
  if [ -n "$SESSION_ID" ] && [ -f "/tmp/tdd-setup-active-${SESSION_ID}" ]; then
    exit 0
  fi
  BASENAME=$(basename "$FILE_PATH")
  tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' because no test script is configured in package.json. Run /wr-tdd:setup-tests to set up a test framework for this project. TDD enforcement requires a working test runner before implementation code can be written."
  exit 0
fi

if [ -z "$SESSION_ID" ]; then
  # Fail-closed: cannot check state without session ID
  tdd_deny_json "BLOCKED: Could not determine session ID. TDD gate is fail-closed."
  exit 0
fi

# Check state for THIS implementation file's associated test
STATE=$(tdd_read_state_for_impl "$SESSION_ID" "$FILE_PATH")
BASENAME=$(basename "$FILE_PATH")
SUGGESTED_TEST=$(tdd_suggest_test_path "$FILE_PATH")

case "$STATE" in
  RED|GREEN)
    # Allowed: this file's test is in the TDD cycle
    exit 0
    ;;
  IDLE)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- no tests written for this file yet. TDD state is IDLE. Write a failing test first (e.g., ${SUGGESTED_TEST}) before editing this implementation file."
    exit 0
    ;;
  BLOCKED)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- its test runner timed out. TDD state is BLOCKED. Fix the test setup for this file before continuing."
    exit 0
    ;;
  *)
    tdd_deny_json "BLOCKED: Cannot edit '${BASENAME}' -- unknown TDD state '${STATE}'. Write a failing test first (e.g., ${SUGGESTED_TEST})."
    exit 0
    ;;
esac
