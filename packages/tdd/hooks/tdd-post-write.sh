#!/bin/bash
# TDD - PostToolUse hook (Edit|Write)
# Runs only the relevant test after file writes and transitions per-file state.
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

# Determine which test file to run
TEST_FILE=""

if [ "$FILE_TYPE" = "test" ]; then
  # Written a test file — track it and run it
  tdd_add_test_file "$SESSION_ID" "$FILE_PATH"
  TEST_FILE="$FILE_PATH"
elif [ "$FILE_TYPE" = "impl" ]; then
  # Written an impl file — find and run its associated test
  TEST_FILE=$(tdd_find_test_for_impl "$SESSION_ID" "$FILE_PATH")
fi

# If no test file to run, nothing to do
if [ -z "$TEST_FILE" ]; then
  exit 0
fi

# Run only the relevant test file
tdd_run_test_file "$SESSION_ID" "$TEST_FILE"
TEST_EXIT=$?

# Read current state for this specific test file
OLD_STATE=$(tdd_read_state "$SESSION_ID" "$TEST_FILE")

# Transition state based on test result
# Only timeout (124) → BLOCKED. All other failures → RED.
NEW_STATE="$OLD_STATE"

if [ $TEST_EXIT -eq 0 ]; then
  # Tests pass
  NEW_STATE="GREEN"
elif [ $TEST_EXIT -eq 124 ]; then
  # Timeout — genuinely broken setup
  NEW_STATE="BLOCKED"
else
  # Tests fail (exit code 1, 2, or any other non-zero)
  # This includes import errors, syntax errors, assertion failures.
  # All of these are RED — the user should write impl to fix them.
  NEW_STATE="RED"
fi

# Write new state for this specific test file
tdd_write_state "$SESSION_ID" "$TEST_FILE" "$NEW_STATE"

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
Test file: ${TEST_FILE}
State: ${NEW_STATE}
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
    echo "ACTION: Tests are failing for ${TEST_FILE}. Write implementation code to make them pass."
    ;;
  GREEN)
    echo ""
    echo "ACTION: Tests are passing for ${TEST_FILE}. You may refactor or write a new failing test for the next behavior."
    ;;
  BLOCKED)
    echo ""
    echo "ACTION: Test runner timed out for ${TEST_FILE} (exit code ${TEST_EXIT}). Fix the test setup before continuing."
    ;;
esac

exit 0
