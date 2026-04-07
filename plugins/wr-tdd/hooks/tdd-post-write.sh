#!/bin/bash
# TDD - PostToolUse hook (Edit|Write)
# Runs tests after file writes and transitions state.
# Emits additionalContext with the current TDD state.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"

# Skip if no test script configured
if ! tdd_has_test_script; then
  exit 0
fi

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || true
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

if [ -z "$FILE_PATH" ] || [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Classify the file
FILE_TYPE=$(tdd_classify_file "$FILE_PATH")

# Skip exempt files entirely
if [ "$FILE_TYPE" = "exempt" ]; then
  exit 0
fi

# Track test files
if [ "$FILE_TYPE" = "test" ]; then
  tdd_add_test_file "$SESSION_ID" "$FILE_PATH"
fi

# Run tests
tdd_run_tests "$SESSION_ID"
TEST_EXIT=$?

# Read current state
OLD_STATE=$(tdd_read_state "$SESSION_ID")

# Transition state based on file type + test result
NEW_STATE="$OLD_STATE"

if [ $TEST_EXIT -eq 0 ]; then
  # Tests pass
  NEW_STATE="GREEN"
elif [ $TEST_EXIT -eq 1 ]; then
  # Tests fail
  case "$FILE_TYPE" in
    test)
      NEW_STATE="RED"
      ;;
    impl)
      case "$OLD_STATE" in
        RED) NEW_STATE="RED" ;;    # still working
        GREEN) NEW_STATE="RED" ;;  # broke something
        *) NEW_STATE="RED" ;;
      esac
      ;;
  esac
else
  # Timeout (124) or other error
  NEW_STATE="BLOCKED"
fi

# Write new state
tdd_write_state "$SESSION_ID" "$NEW_STATE"

# Read last test output for context
STDOUT_FILE="/tmp/tdd-test-stdout-${SESSION_ID}"
TEST_OUTPUT=""
if [ -f "$STDOUT_FILE" ]; then
  # Limit to last 50 lines to avoid flooding context
  TEST_OUTPUT=$(tail -50 "$STDOUT_FILE")
fi

# Emit state as additionalContext
if [ "$OLD_STATE" != "$NEW_STATE" ]; then
  TRANSITION="State transition: ${OLD_STATE} -> ${NEW_STATE}"
else
  TRANSITION="State unchanged: ${NEW_STATE}"
fi

cat <<EOF
TDD STATE UPDATE: ${TRANSITION}
Current state: ${NEW_STATE}
File written: ${FILE_PATH} (${FILE_TYPE})
Test result: exit code ${TEST_EXIT}
EOF

if [ $TEST_EXIT -ne 0 ] && [ -n "$TEST_OUTPUT" ]; then
  echo ""
  echo "Test output (last 50 lines):"
  echo "$TEST_OUTPUT"
fi

case "$NEW_STATE" in
  RED)
    echo ""
    echo "ACTION: Tests are failing. Write implementation code to make them pass."
    ;;
  GREEN)
    echo ""
    echo "ACTION: Tests are passing. You may refactor or write a new failing test for the next behavior."
    ;;
  BLOCKED)
    echo ""
    echo "ACTION: Test runner error (exit code ${TEST_EXIT}). Fix the test setup before continuing."
    ;;
esac

exit 0
