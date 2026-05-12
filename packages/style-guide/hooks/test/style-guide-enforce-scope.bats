#!/usr/bin/env bats

# Tests for style-guide-enforce-edit.sh — verifies the path-based exemption
# for governance-managed surfaces (docs/story-maps/, docs/stories/) per
# ADR-060 § Phase 2 amendment 2026-05-12 lines 481-496 (P170 Phase 2 Slice 2.5).
#
# The style-guide hook is opt-in (gates only *.css|*.html|*.jsx|*.tsx|*.vue|
# *.svelte|*.ejs|*.hbs). Story-map HTML files would otherwise be blocked at
# `*.html` matching when docs/STYLE-GUIDE.md is absent OR review-gate is open.
# The exemption short-circuits before the extension check.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/style-guide-enforce-edit.sh"
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

@test "style-guide: exempts docs/story-maps/ HTML in per-state subdir" {
  assert_path_allowed "$PWD/docs/story-maps/draft/STORY-MAP-001-foo.html"
}

@test "style-guide: exempts docs/story-maps/ HTML in completed subdir" {
  assert_path_allowed "$PWD/docs/story-maps/completed/STORY-MAP-002-bar.html"
}

@test "style-guide: exempts docs/stories/ files even though .md isn't normally gated" {
  # Markdown isn't in the opt-in extension list anyway, so this passes by
  # virtue of the extension filter — but the explicit exemption documents
  # intent and survives a hypothetical future scope-widening.
  assert_path_allowed "$PWD/docs/stories/draft/STORY-001-foo.md"
}

# --- Regression: non-exempt UI files still gate ---

@test "style-guide: still blocks an unrelated .html file when no policy exists" {
  # No docs/STYLE-GUIDE.md created — hook should still block this HTML.
  assert_path_blocked "$PWD/public/index.html"
}

@test "style-guide: still blocks a .tsx component file when no policy exists" {
  assert_path_blocked "$PWD/src/Component.tsx"
}
