#!/usr/bin/env bats

# Tests for slide_marker_on_subprocess_return helper (P111).
#
# Behavioural contract:
# - Slides an existing marker forward (touch) on PostToolUse:Agent|Bash
#   completion, treating subprocess wall-clock as continuous parent-session
#   work for TTL purposes.
# - Never CREATES a marker (creating requires a real gate review).
# - Skips slide on subprocess error (tool_response.is_error=true) so a failed
#   subprocess does NOT extend the parent's trust window (ADR-009 amendment).
# - No-op when no marker exists or session_id is empty (fail-safe).

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$HOOKS_DIR/lib/gate-helpers.sh"

  TEST_SESSION="bats-slide-$$-${BATS_TEST_NUMBER}"
  MARKER="/tmp/architect-reviewed-${TEST_SESSION}"
  rm -f "$MARKER"
}

teardown() {
  rm -f "$MARKER"
}

# Helper: backdate file mtime by N seconds (portable between macOS and Linux)
_backdate() {
  local file="$1" seconds="$2"
  local stamp
  stamp=$(date -v-${seconds}S +%Y%m%d%H%M.%S 2>/dev/null \
       || date -d "${seconds} seconds ago" +%Y%m%d%H%M.%S 2>/dev/null)
  touch -t "$stamp" "$file"
}

@test "slide: existing marker is touched on success response" {
  touch "$MARKER"
  _backdate "$MARKER" 60
  BEFORE=$(_mtime "$MARKER")
  _HOOK_INPUT='{"tool_response":{"content":[]}}'
  slide_marker_on_subprocess_return "$MARKER"
  AFTER=$(_mtime "$MARKER")
  [ "$AFTER" -gt "$BEFORE" ]
}

@test "slide: long-running subprocess does NOT cause parent marker expiry on return (P111 reproduction)" {
  # Simulate the P111 failure mode: parent's marker is set, then a long
  # subprocess runs (we backdate the marker to simulate elapsed wall-clock),
  # then PostToolUse fires with a successful tool_response. The marker mtime
  # must be refreshed so the parent's NEXT PreToolUse gate check (which
  # compares NOW - mtime against TTL) sees a fresh marker.
  touch "$MARKER"
  # Marker is 50 minutes old — under default 60-min TTL but close to expiry.
  # Without the slide on subprocess return, a subsequent 15-min subprocess
  # would push the mtime past TTL and the next PreToolUse would deny.
  _backdate "$MARKER" 3000
  BEFORE=$(_mtime "$MARKER")
  _HOOK_INPUT='{"tool_response":{"content":[{"type":"text","text":"OK"}]}}'
  slide_marker_on_subprocess_return "$MARKER"
  AFTER=$(_mtime "$MARKER")
  NOW=$(date +%s)
  [ "$AFTER" -gt "$BEFORE" ]
  # And the new mtime is approximately NOW (within 5 seconds of slide call)
  AGE=$((NOW - AFTER))
  [ "$AGE" -lt 5 ]
}

@test "slide: does NOT touch marker when tool_response.is_error=true" {
  touch "$MARKER"
  _backdate "$MARKER" 60
  BEFORE=$(_mtime "$MARKER")
  _HOOK_INPUT='{"tool_response":{"is_error":true,"content":[]}}'
  slide_marker_on_subprocess_return "$MARKER"
  AFTER=$(_mtime "$MARKER")
  [ "$BEFORE" = "$AFTER" ]
}

@test "slide: no-op when marker does not exist (never creates)" {
  [ ! -f "$MARKER" ]
  _HOOK_INPUT='{"tool_response":{"content":[]}}'
  slide_marker_on_subprocess_return "$MARKER"
  [ ! -f "$MARKER" ]
}

@test "slide: no-op when marker path argument is empty" {
  _HOOK_INPUT='{"tool_response":{"content":[]}}'
  run slide_marker_on_subprocess_return ""
  [ "$status" -eq 0 ]
}

@test "slide: malformed hook input is fail-safe (no slide)" {
  touch "$MARKER"
  _backdate "$MARKER" 60
  BEFORE=$(_mtime "$MARKER")
  _HOOK_INPUT='not valid json'
  slide_marker_on_subprocess_return "$MARKER"
  AFTER=$(_mtime "$MARKER")
  # Fail-safe: when the hook input cannot be parsed, treat as error and skip
  [ "$BEFORE" = "$AFTER" ]
}
