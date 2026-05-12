#!/usr/bin/env bats

# Tests for voice-tone-enforce-edit.sh — verifies the path-based exemption
# for governance-managed surfaces (docs/story-maps/, docs/stories/) per
# ADR-060 § Phase 2 amendment 2026-05-12 lines 481-496 (P170 Phase 2 Slice 2.5).
#
# The voice-tone hook is opt-in (gates *.html|*.jsx|*.tsx|*.vue|*.svelte|
# *.ejs|*.hbs) and blocks outright when docs/VOICE-AND-TONE.md is absent.
# Story-map HTML files would otherwise be blocked even when no policy
# exists — this is the empirical block P170 line 297 documented when the
# STORY-MAP-001 bootstrap was attempted. The exemption short-circuits before
# the extension check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/voice-tone-enforce-edit.sh"
  ORIG_DIR="$PWD"
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "$TEST_DIR"
}

run_hook_with_file() {
  local file_path="$1"
  local json="{\"tool_input\":{\"file_path\":\"${file_path}\"},\"session_id\":\"test-session-$$\"}"
  echo "$json" | bash "$HOOK"
}

assert_path_allowed() {
  local file_path="$1"
  run run_hook_with_file "$file_path"
  [ "$status" -eq 0 ]
  [[ "$output" != *"BLOCKED"* ]]
}

assert_path_blocked() {
  local file_path="$1"
  run run_hook_with_file "$file_path"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# --- Story maps + stories exemptions (P170 Phase 2 Slice 2.5 / ADR-060) ---

@test "voice-tone: exempts docs/story-maps/ HTML in per-state subdir" {
  assert_path_allowed "$PWD/docs/story-maps/draft/STORY-MAP-001-foo.html"
}

@test "voice-tone: exempts docs/story-maps/ HTML in completed subdir" {
  assert_path_allowed "$PWD/docs/story-maps/completed/STORY-MAP-002-bar.html"
}

@test "voice-tone: exempts docs/story-maps/ even when no VOICE-AND-TONE.md exists" {
  # P170 line 297: STORY-MAP-001 bootstrap was blocked here exactly because
  # this exemption did not exist. Behavioural regression-guard.
  [ ! -f docs/VOICE-AND-TONE.md ]
  assert_path_allowed "$PWD/docs/story-maps/in-progress/STORY-MAP-001-rfc-framework.html"
}

@test "voice-tone: exempts docs/stories/ files even though .md isn't normally gated" {
  assert_path_allowed "$PWD/docs/stories/draft/STORY-001-foo.md"
}

# --- Regression: non-exempt HTML still gate ---

@test "voice-tone: still blocks an unrelated .html file when no policy exists" {
  assert_path_blocked "$PWD/public/index.html"
}

@test "voice-tone: still blocks a .tsx component file when no policy exists" {
  assert_path_blocked "$PWD/src/Component.tsx"
}
