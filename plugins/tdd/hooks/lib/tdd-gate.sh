#!/bin/bash
# TDD Gate - shared library for TDD enforcement hooks.
# Sourced by tdd-inject.sh, tdd-enforce-edit.sh, tdd-post-write.sh, tdd-reset.sh.
# Provides: tdd_classify_file, tdd_read_state, tdd_write_state, tdd_run_tests,
#           tdd_add_test_file, tdd_get_test_files, tdd_cleanup, tdd_has_test_script,
#           tdd_deny_json

# --- Configuration ---
TDD_TEST_CMD="${TDD_TEST_CMD:-npm test --}"
TDD_TEST_TIMEOUT="${TDD_TEST_TIMEOUT:-30}"

# --- File Classification ---
# Returns: "test", "exempt", or "impl"
tdd_classify_file() {
  local FILE_PATH="$1"
  local BASENAME
  BASENAME=$(basename "$FILE_PATH")

  # Test files (always allowed)
  case "$BASENAME" in
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx) echo "test"; return ;;
    *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx) echo "test"; return ;;
  esac
  case "$FILE_PATH" in
    */__tests__/*) echo "test"; return ;;
  esac

  # Exempt files (not gated)
  case "$FILE_PATH" in
    # Config files
    *.config.*|*.json|*.yml|*.yaml) echo "exempt"; return ;;
    # Module configs (*.mjs, *.cjs are config when at root or named as config)
    *.mjs|*.cjs) echo "exempt"; return ;;
    # Styles
    *.css|*.scss|*.sass|*.less) echo "exempt"; return ;;
    # Assets
    *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.webp) echo "exempt"; return ;;
    *.woff|*.woff2|*.ttf|*.eot) echo "exempt"; return ;;
    # Docs
    *.md|*.mdx) echo "exempt"; return ;;
    */docs/*|docs/*) echo "exempt"; return ;;
    # Tooling
    */.claude/*|.claude/*) echo "exempt"; return ;;
    */.github/*|.github/*) echo "exempt"; return ;;
    # Lockfiles and sourcemaps
    *package-lock.json|*yarn.lock|*pnpm-lock.yaml) echo "exempt"; return ;;
    *.map) echo "exempt"; return ;;
    # Shell scripts
    *.sh) echo "exempt"; return ;;
  esac

  # Implementation files (gated)
  case "$BASENAME" in
    *.ts|*.tsx|*.js|*.jsx) echo "impl"; return ;;
  esac

  # Everything else is exempt
  echo "exempt"
}

# --- State Management ---
# Marker files use session ID to isolate concurrent sessions
_tdd_state_file() { echo "/tmp/tdd-state-${1}"; }
_tdd_test_files_file() { echo "/tmp/tdd-test-files-${1}"; }
_tdd_test_stdout_file() { echo "/tmp/tdd-test-stdout-${1}"; }

# Read current state. Returns: IDLE, RED, GREEN, or BLOCKED
tdd_read_state() {
  local SESSION_ID="$1"
  local STATE_FILE
  STATE_FILE=$(_tdd_state_file "$SESSION_ID")
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "IDLE"
  fi
}

# Write state
tdd_write_state() {
  local SESSION_ID="$1"
  local NEW_STATE="$2"
  local STATE_FILE
  STATE_FILE=$(_tdd_state_file "$SESSION_ID")
  echo "$NEW_STATE" > "$STATE_FILE"
}

# Track test files touched this session
tdd_add_test_file() {
  local SESSION_ID="$1"
  local TEST_FILE="$2"
  local TRACK_FILE
  TRACK_FILE=$(_tdd_test_files_file "$SESSION_ID")
  # Avoid duplicates
  if [ -f "$TRACK_FILE" ] && grep -qxF "$TEST_FILE" "$TRACK_FILE" 2>/dev/null; then
    return 0
  fi
  echo "$TEST_FILE" >> "$TRACK_FILE"
}

# Get all test files for this session (newline-separated)
tdd_get_test_files() {
  local SESSION_ID="$1"
  local TRACK_FILE
  TRACK_FILE=$(_tdd_test_files_file "$SESSION_ID")
  if [ -f "$TRACK_FILE" ]; then
    cat "$TRACK_FILE"
  fi
}

# --- Test Runner ---
# Runs tests for the session's tracked test files.
# Returns: 0=pass, 1=fail, 124=timeout, other=error
# Saves stdout to marker file for debugging.
tdd_run_tests() {
  local SESSION_ID="$1"
  local STDOUT_FILE
  STDOUT_FILE=$(_tdd_test_stdout_file "$SESSION_ID")
  local TEST_FILES
  TEST_FILES=$(tdd_get_test_files "$SESSION_ID")

  if [ -z "$TEST_FILES" ]; then
    echo "No test files tracked" > "$STDOUT_FILE"
    return 0  # No tests to run = pass (no-op)
  fi

  # Build argument list from tracked test files
  local ARGS=""
  while IFS= read -r f; do
    ARGS="$ARGS $f"
  done <<< "$TEST_FILES"

  # Run with timeout
  local EXIT_CODE
  timeout "$TDD_TEST_TIMEOUT" bash -c "$TDD_TEST_CMD $ARGS" > "$STDOUT_FILE" 2>&1
  EXIT_CODE=$?

  return $EXIT_CODE
}

# --- Prerequisite Check ---
# Returns 0 if a test script is configured, 1 otherwise
tdd_has_test_script() {
  if [ -f "package.json" ]; then
    # Check if "test" script exists and is not the default npm placeholder
    local TEST_SCRIPT
    TEST_SCRIPT=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
    if [ -n "$TEST_SCRIPT" ] && [ "$TEST_SCRIPT" != "echo \"Error: no test specified\" && exit 1" ]; then
      return 0
    fi
  fi
  return 1
}

# --- Cleanup ---
tdd_cleanup() {
  local SESSION_ID="$1"
  rm -f "$(_tdd_state_file "$SESSION_ID")"
  rm -f "$(_tdd_test_files_file "$SESSION_ID")"
  rm -f "$(_tdd_test_stdout_file "$SESSION_ID")"
}

# --- Deny Helper ---
# Emit PreToolUse deny JSON
tdd_deny_json() {
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
