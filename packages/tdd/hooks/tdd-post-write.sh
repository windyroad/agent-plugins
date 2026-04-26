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

# P096 Phase 2 — silent-on-GREEN-unchanged: when both old and new state
# are GREEN, the assistant already knows the file passes; emit nothing.
# Transitions and any non-GREEN state still emit the full block below.
if [ "$OLD_STATE" = "GREEN" ] && [ "$NEW_STATE" = "GREEN" ]; then
  exit 0
fi

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

# P096 Phase 2 — dedupe RED test output: when consecutive RED edits on
# the same test file produce identical last-50-lines output, only the
# first emission carries the body; subsequent emissions skip the test
# output block. Hash file is keyed by session + encoded test path.
if [ $TEST_EXIT -ne 0 ] && [ -n "$TEST_OUTPUT" ]; then
  ENCODED_TEST=$(echo "$TEST_FILE" | sed 's|/|__|g')
  HASH_FILE="/tmp/tdd-stdout-hash-${SESSION_ID}-${ENCODED_TEST}"
  NEW_HASH=$(printf '%s' "$TEST_OUTPUT" | shasum 2>/dev/null | awk '{print $1}')
  PREV_HASH=""
  [ -f "$HASH_FILE" ] && PREV_HASH=$(cat "$HASH_FILE" 2>/dev/null)
  if [ -n "$NEW_HASH" ] && [ "$NEW_HASH" = "$PREV_HASH" ]; then
    echo ""
    echo "Test output unchanged from previous emission (hash match)."
  else
    echo ""
    echo "Test output (last 50 lines):"
    echo "$TEST_OUTPUT"
    [ -n "$NEW_HASH" ] && echo "$NEW_HASH" > "$HASH_FILE"
  fi
fi

# P096 Phase 2 — GREEN ACTION line dropped (standing prose the assistant
# already knows; the STATE UPDATE block above carries the transition
# signal). RED and BLOCKED keep their actionable next-step ACTION line.
case "$NEW_STATE" in
  RED)
    echo ""
    echo "ACTION: Tests are failing for ${TEST_FILE}. Write implementation code to make them pass."
    ;;
  BLOCKED)
    echo ""
    echo "ACTION: Test runner timed out for ${TEST_FILE} (exit code ${TEST_EXIT}). Fix the test setup before continuing."
    ;;
esac

exit 0
