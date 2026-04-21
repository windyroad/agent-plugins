#!/bin/bash
# TDD - UserPromptSubmit hook (P095 / ADR-038)
# Injects TDD instructions and per-file state into every prompt.
# Only active when a test script is configured in package.json.
#
# Progressive disclosure (ADR-038) with tdd-inject carve-out: static
# prose (STATE RULES table, WORKFLOW, IMPORTANT blocks) is gated
# behind the once-per-session announcement marker; dynamic content
# (current TDD state + tracked test files) emits on every prompt.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/tdd-gate.sh"
# shellcheck source=lib/session-marker.sh
source "$SCRIPT_DIR/lib/session-marker.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty') || true

# If no test script configured, inject setup instructions (unchanged by ADR-038)
if ! tdd_has_test_script; then
  cat <<'HOOK_OUTPUT'
INSTRUCTION: MANDATORY TDD ENFORCEMENT. YOU MUST FOLLOW THIS.

This project has NO test script configured in package.json. Implementation file
edits (.ts, .tsx, .js, .jsx) are BLOCKED until testing is set up.

If the user's task involves writing or editing implementation code, you MUST
run /wr-tdd:setup-tests first to configure a test framework for this project.

Test files, config files, docs, and styles are still writable.
HOOK_OUTPUT
  exit 0
fi

# Collect per-file states (always per-prompt)
ALL_STATES=""
if [ -n "$SESSION_ID" ]; then
  ALL_STATES=$(tdd_get_all_states "$SESSION_ID")
fi

# Determine overall status for the header (always per-prompt)
OVERALL="IDLE"
if [ -n "$ALL_STATES" ]; then
  if echo "$ALL_STATES" | grep -q ":BLOCKED$"; then
    OVERALL="BLOCKED (some tests)"
  elif echo "$ALL_STATES" | grep -q ":RED$"; then
    OVERALL="RED (some tests failing)"
  elif echo "$ALL_STATES" | grep -q ":GREEN$"; then
    OVERALL="GREEN"
  fi
fi

if has_announced "tdd" "$SESSION_ID"; then
  # Subsequent prompt: terse reminder + dynamic state only.
  cat <<HOOK_OUTPUT
MANDATORY TDD gate active (test script present). Current TDD state: **${OVERALL}**. Write failing test before implementation; .ts/.tsx/.js/.jsx edits gated per test state. See turn-1 instructions for full rules and workflow.
HOOK_OUTPUT
else
  # First prompt of session: full MANDATORY block + mark announced.
  cat <<HOOK_OUTPUT
INSTRUCTION: MANDATORY TDD ENFORCEMENT. YOU MUST FOLLOW THIS.

This project enforces Red-Green-Refactor via hooks. Your current TDD state is: **${OVERALL}**

STATE RULES (per test file — each component has independent state):
- IDLE: You MUST write a failing test FIRST before any implementation code.
  Implementation file edits (.ts, .tsx, .js, .jsx) are BLOCKED until you write a test for that file.
- RED: Tests are failing. Write implementation code to make them pass.
  Implementation file edits are ALLOWED for files whose associated test is RED.
- GREEN: Tests are passing. You may refactor or write a new failing test.
  Implementation file edits are ALLOWED for files whose associated test is GREEN.
- BLOCKED: Test runner timed out. Fix the test setup before continuing.
  Implementation file edits are BLOCKED for files whose associated test is BLOCKED.

WORKFLOW:
1. Write a test file (*.test.ts or *.spec.ts) that describes the desired behavior
2. The test MUST fail (RED state) -- this proves the test is meaningful
3. Write the minimum implementation to make the test pass (GREEN state)
4. Refactor while keeping tests green
5. Repeat for the next behavior

IMPORTANT:
- State is tracked PER TEST FILE — a failing Countdown test does NOT block editing Hero
- Test files and config/doc/style files are ALWAYS writable regardless of state
- Implementation files are ONLY writable when their associated test is RED or GREEN
- The hook runs only the relevant test after each file write (not the full suite)
- To refactor existing code, touch the relevant test file first to enter the cycle
HOOK_OUTPUT
  mark_announced "tdd" "$SESSION_ID"
fi

# Dynamic tracked test files (always per-prompt, both branches)
if [ -n "$ALL_STATES" ]; then
  echo ""
  echo "TRACKED TEST FILES THIS SESSION:"
  echo "$ALL_STATES" | while IFS=: read -r file state; do
    echo "  - ${file} [${state}]"
  done
fi

exit 0
