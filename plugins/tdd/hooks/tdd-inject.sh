#!/bin/bash
# TDD - UserPromptSubmit hook
# Injects TDD instructions and current state into every prompt.
# Only active when a test script is configured in package.json.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"

# Skip if no test script configured
if ! tdd_has_test_script; then
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

STATE="IDLE"
if [ -n "$SESSION_ID" ]; then
  STATE=$(tdd_read_state "$SESSION_ID")
fi

TEST_FILES=""
if [ -n "$SESSION_ID" ]; then
  TEST_FILES=$(tdd_get_test_files "$SESSION_ID")
fi

cat <<HOOK_OUTPUT
INSTRUCTION: MANDATORY TDD ENFORCEMENT. YOU MUST FOLLOW THIS.

This project enforces Red-Green-Refactor via hooks. Your current TDD state is: **${STATE}**

STATE RULES:
- IDLE: You MUST write a failing test FIRST before any implementation code.
  Implementation file edits (.ts, .tsx, .js, .jsx) are BLOCKED until you write a test.
- RED: Tests are failing. Write implementation code to make them pass.
  Implementation file edits are ALLOWED.
- GREEN: Tests are passing. You may refactor or write a new failing test.
  Implementation file edits are ALLOWED.
- BLOCKED: Test runner error or timeout. Fix the test setup before continuing.
  Implementation file edits are BLOCKED.

WORKFLOW:
1. Write a test file (*.test.ts, *.spec.ts, etc.) that describes the desired behavior
2. The test MUST fail (RED state) -- this proves the test is meaningful
3. Write the minimum implementation to make the test pass (GREEN state)
4. Refactor while keeping tests green
5. Repeat for the next behavior

IMPORTANT:
- Test files and config/doc/style files are ALWAYS writable regardless of state
- Implementation files are ONLY writable in RED or GREEN states
- The hook runs your tests automatically after every file write
- To refactor existing code, touch the relevant test file first to enter the cycle
HOOK_OUTPUT

if [ -n "$TEST_FILES" ]; then
  echo ""
  echo "TRACKED TEST FILES THIS SESSION:"
  echo "$TEST_FILES" | sed 's/^/  - /'
fi

exit 0
