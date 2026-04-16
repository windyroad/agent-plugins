#!/bin/bash
# TDD Gate - shared library for TDD enforcement hooks.
# Sourced by tdd-inject.sh, tdd-enforce-edit.sh, tdd-post-write.sh, tdd-reset.sh.
# Provides: tdd_classify_file, tdd_read_state, tdd_write_state, tdd_run_test_file,
#           tdd_add_test_file, tdd_get_test_files, tdd_find_test_for_impl,
#           tdd_read_state_for_impl, tdd_get_all_states, tdd_cleanup,
#           tdd_has_test_script, tdd_deny_json

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
    *.feature) echo "test"; return ;;
  esac
  case "$FILE_PATH" in
    */__tests__/*) echo "test"; return ;;
  esac

  # Exempt files (not gated)
  case "$FILE_PATH" in
    # Config and setup files (test infrastructure)
    *.config.*|*.setup.*|*.json|*.yml|*.yaml) echo "exempt"; return ;;
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

# --- State Management (per-test-file) ---
# State is stored per test file in a session-scoped directory.
# Each test file gets its own state: IDLE, RED, GREEN, or BLOCKED.

_tdd_state_dir() { echo "/tmp/tdd-state-${1}"; }
_tdd_test_files_file() { echo "/tmp/tdd-test-files-${1}"; }
_tdd_test_stdout_file() { echo "/tmp/tdd-test-stdout-${1}"; }

# Encode a file path for use as a filename (replace / with __)
_tdd_encode_path() {
  echo "$1" | sed 's|/|__|g'
}

# Read state for a specific test file. Returns: IDLE, RED, GREEN, or BLOCKED
tdd_read_state() {
  local SESSION_ID="$1"
  local TEST_FILE="$2"
  local STATE_DIR
  STATE_DIR=$(_tdd_state_dir "$SESSION_ID")
  local ENCODED
  ENCODED=$(_tdd_encode_path "$TEST_FILE")
  local STATE_FILE="${STATE_DIR}/${ENCODED}"
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "IDLE"
  fi
}

# Write state for a specific test file
tdd_write_state() {
  local SESSION_ID="$1"
  local TEST_FILE="$2"
  local NEW_STATE="$3"
  local STATE_DIR
  STATE_DIR=$(_tdd_state_dir "$SESSION_ID")
  mkdir -p "$STATE_DIR"
  local ENCODED
  ENCODED=$(_tdd_encode_path "$TEST_FILE")
  echo "$NEW_STATE" > "${STATE_DIR}/${ENCODED}"
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

# --- Impl-to-Test Association ---
# Given an implementation file, find its associated test file from tracked tests.
# Convention: Hero.tsx ↔ Hero.test.tsx or Hero.spec.tsx (same dir or __tests__/)
# Returns the first matching tracked test file, or empty string if none.
tdd_find_test_for_impl() {
  local SESSION_ID="$1"
  local IMPL_PATH="$2"
  local DIR BASENAME STEM EXT
  DIR=$(dirname "$IMPL_PATH")
  BASENAME=$(basename "$IMPL_PATH")

  # Strip extension to get stem (e.g., "Hero" from "Hero.tsx")
  # Handle .ts, .tsx, .js, .jsx, and Cucumber step definitions (.steps.js, .steps.ts, etc.)
  case "$BASENAME" in
    *.tsx) STEM="${BASENAME%.tsx}"; EXT="tsx" ;;
    *.ts)  STEM="${BASENAME%.ts}";  EXT="ts" ;;
    *.jsx) STEM="${BASENAME%.jsx}"; EXT="jsx" ;;
    *.js)  STEM="${BASENAME%.js}";  EXT="js" ;;
    *)     STEM="$BASENAME";       EXT="" ;;
  esac
  # Strip compound step-definition suffixes (e.g. "checkout.steps" -> "checkout")
  case "$STEM" in
    *.steps) STEM="${STEM%.steps}" ;;
  esac

  local TEST_FILES
  TEST_FILES=$(tdd_get_test_files "$SESSION_ID")
  if [ -z "$TEST_FILES" ]; then
    echo ""
    return
  fi

  # Check tracked test files for a match
  # Priority: exact match in tracked files (any convention)
  while IFS= read -r tracked; do
    local tracked_dir tracked_base
    tracked_dir=$(dirname "$tracked")
    tracked_base=$(basename "$tracked")

    # Same directory: Hero.test.tsx, Hero.spec.tsx, etc.
    if [ "$tracked_dir" = "$DIR" ]; then
      case "$tracked_base" in
        "${STEM}.test."*|"${STEM}.spec."*) echo "$tracked"; return ;;
      esac
    fi

    # __tests__ subdirectory: src/__tests__/Hero.test.tsx for src/Hero.tsx
    if [ "$tracked_dir" = "${DIR}/__tests__" ]; then
      case "$tracked_base" in
        "${STEM}.test."*|"${STEM}.spec."*) echo "$tracked"; return ;;
      esac
    fi

    # Parent __tests__: src/__tests__/Hero.test.tsx for src/components/Hero.tsx
    # (only if dir contains __tests__)
    case "$tracked" in
      */__tests__/*)
        case "$tracked_base" in
          "${STEM}.test."*|"${STEM}.spec."*) echo "$tracked"; return ;;
        esac
        ;;
    esac

    # Cucumber: features/step_definitions/foo.steps.js → features/foo.feature
    # If this impl is inside a step_definitions/ directory, look in the parent for a .feature file
    case "$DIR" in
      */step_definitions)
        local feature_dir
        feature_dir=$(dirname "$DIR")
        if [ "$tracked_dir" = "$feature_dir" ] && [ "$tracked_base" = "${STEM}.feature" ]; then
          echo "$tracked"; return
        fi
        ;;
    esac
  done <<< "$TEST_FILES"

  # No tracked test found
  echo ""
}

# Suggest a test file path for an impl file using naming convention.
# Used for user-facing messages (e.g., "write src/Hero.test.tsx first").
tdd_suggest_test_path() {
  local IMPL_PATH="$1"
  local DIR BASENAME STEM EXT
  DIR=$(dirname "$IMPL_PATH")
  BASENAME=$(basename "$IMPL_PATH")
  case "$BASENAME" in
    *.tsx) STEM="${BASENAME%.tsx}"; EXT="tsx" ;;
    *.ts)  STEM="${BASENAME%.ts}";  EXT="ts" ;;
    *.jsx) STEM="${BASENAME%.jsx}"; EXT="jsx" ;;
    *.js)  STEM="${BASENAME%.js}";  EXT="js" ;;
    *)     echo ""; return ;;
  esac
  echo "${DIR}/${STEM}.test.${EXT}"
}

# Read state for an implementation file by looking up its associated test
tdd_read_state_for_impl() {
  local SESSION_ID="$1"
  local IMPL_PATH="$2"
  local TEST_FILE
  TEST_FILE=$(tdd_find_test_for_impl "$SESSION_ID" "$IMPL_PATH")
  if [ -z "$TEST_FILE" ]; then
    echo "IDLE"
    return
  fi
  tdd_read_state "$SESSION_ID" "$TEST_FILE"
}

# Get all tracked test files with their states (format: "path:STATE" per line)
tdd_get_all_states() {
  local SESSION_ID="$1"
  local TEST_FILES
  TEST_FILES=$(tdd_get_test_files "$SESSION_ID")
  if [ -z "$TEST_FILES" ]; then
    return
  fi
  while IFS= read -r test_file; do
    local state
    state=$(tdd_read_state "$SESSION_ID" "$test_file")
    echo "${test_file}:${state}"
  done <<< "$TEST_FILES"
}

# --- Test Runner ---
# Runs a single test file.
# Returns: 0=pass, 1=fail, 124=timeout, other=error
# Saves stdout to marker file for debugging.
tdd_run_test_file() {
  local SESSION_ID="$1"
  local TEST_FILE="$2"
  local STDOUT_FILE
  STDOUT_FILE=$(_tdd_test_stdout_file "$SESSION_ID")

  if [ -z "$TEST_FILE" ]; then
    echo "No test file specified" > "$STDOUT_FILE"
    return 0
  fi

  # Run with timeout — only the specified test file
  local EXIT_CODE
  timeout "$TDD_TEST_TIMEOUT" bash -c "$TDD_TEST_CMD $TEST_FILE" > "$STDOUT_FILE" 2>&1
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
  local STATE_DIR
  STATE_DIR=$(_tdd_state_dir "$SESSION_ID")
  rm -rf "$STATE_DIR"
  rm -f "$(_tdd_test_files_file "$SESSION_ID")"
  rm -f "$(_tdd_test_stdout_file "$SESSION_ID")"
  rm -f "/tmp/tdd-setup-active-${SESSION_ID}"
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
