#!/usr/bin/env bats

# Hook-level integration tests for architect-slide-marker.sh (P111).
# Verifies that the PostToolUse:Agent|Bash hook correctly wires session_id
# extraction + slide_marker_on_subprocess_return for the architect markers.

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$HOOKS_DIR/architect-slide-marker.sh"
  TEST_SESSION="bats-arch-slide-$$-${BATS_TEST_NUMBER}"
  REVIEW_MARKER="/tmp/architect-reviewed-${TEST_SESSION}"
  PLAN_MARKER="/tmp/architect-plan-reviewed-${TEST_SESSION}"
  rm -f "$REVIEW_MARKER" "$PLAN_MARKER"
}

teardown() {
  rm -f "$REVIEW_MARKER" "$PLAN_MARKER"
}

_backdate() {
  local file="$1" seconds="$2"
  local stamp
  stamp=$(date -v-${seconds}S +%Y%m%d%H%M.%S 2>/dev/null \
       || date -d "${seconds} seconds ago" +%Y%m%d%H%M.%S 2>/dev/null)
  touch -t "$stamp" "$file"
}

@test "hook: slides architect-reviewed marker on subprocess return" {
  touch "$REVIEW_MARKER"
  _backdate "$REVIEW_MARKER" 60
  BEFORE=$(stat -c%Y "$REVIEW_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$REVIEW_MARKER")
  echo '{"session_id":"'"$TEST_SESSION"'","tool_name":"Agent","tool_response":{"content":[]}}' | "$HOOK"
  AFTER=$(stat -c%Y "$REVIEW_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$REVIEW_MARKER")
  [ "$AFTER" -gt "$BEFORE" ]
}

@test "hook: slides architect-plan-reviewed marker too" {
  touch "$PLAN_MARKER"
  _backdate "$PLAN_MARKER" 60
  BEFORE=$(stat -c%Y "$PLAN_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$PLAN_MARKER")
  echo '{"session_id":"'"$TEST_SESSION"'","tool_name":"Agent","tool_response":{"content":[]}}' | "$HOOK"
  AFTER=$(stat -c%Y "$PLAN_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$PLAN_MARKER")
  [ "$AFTER" -gt "$BEFORE" ]
}

@test "hook: skips slide when tool_response.is_error=true" {
  touch "$REVIEW_MARKER"
  _backdate "$REVIEW_MARKER" 60
  BEFORE=$(stat -c%Y "$REVIEW_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$REVIEW_MARKER")
  echo '{"session_id":"'"$TEST_SESSION"'","tool_name":"Bash","tool_response":{"is_error":true,"content":[]}}' | "$HOOK"
  AFTER=$(stat -c%Y "$REVIEW_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$REVIEW_MARKER")
  [ "$BEFORE" = "$AFTER" ]
}

@test "hook: no-op when no marker exists (never creates)" {
  [ ! -f "$REVIEW_MARKER" ]
  echo '{"session_id":"'"$TEST_SESSION"'","tool_name":"Agent","tool_response":{"content":[]}}' | "$HOOK"
  [ ! -f "$REVIEW_MARKER" ]
}

@test "hook: exits 0 when session_id is missing" {
  run bash -c 'echo "{}" | '"$HOOK"
  [ "$status" -eq 0 ]
}

@test "hook: P111 reproduction — long subprocess does not cause parent marker expiry on return" {
  touch "$REVIEW_MARKER"
  # Marker is 50 minutes old, well within default 60-min TTL but close.
  # Without the slide on subprocess return, a 15-min subprocess would push
  # the next PreToolUse check past TTL. With the slide, the next check sees
  # a fresh marker.
  _backdate "$REVIEW_MARKER" 3000
  echo '{"session_id":"'"$TEST_SESSION"'","tool_name":"Bash","tool_input":{"command":"claude -p ..."},"tool_response":{"content":[{"type":"text","text":"OK"}]}}' | "$HOOK"
  NOW=$(date +%s)
  AFTER=$(stat -c%Y "$REVIEW_MARKER" 2>/dev/null || /usr/bin/stat -f%m "$REVIEW_MARKER")
  AGE=$((NOW - AFTER))
  [ "$AGE" -lt 5 ]
}
