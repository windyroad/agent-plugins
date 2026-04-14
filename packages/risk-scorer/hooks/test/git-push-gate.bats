#!/usr/bin/env bats
# Tests for git-push-gate.sh — gh pr merge block and release:watch guidance

setup() {
  HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$HOOKS_DIR/git-push-gate.sh"

  TEST_SESSION="bats-push-gate-$$-${BATS_TEST_NUMBER}"
  # Ensure a clean risk dir
  RDIR="${TMPDIR:-/tmp}/claude-risk-${TEST_SESSION}"
  rm -rf "$RDIR"
  mkdir -p "$RDIR"

  # Create a temp project dir for package.json detection
  TEST_PROJECT_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$RDIR"
  rm -rf "$TEST_PROJECT_DIR"
}

# Helper: build a PreToolUse Bash input with a given command
build_input() {
  local cmd="$1"
  cat <<ENDJSON
{
  "session_id": "$TEST_SESSION",
  "tool_name": "Bash",
  "tool_input": {
    "command": "$cmd"
  }
}
ENDJSON
}

@test "gh pr merge is blocked with release:watch guidance when script exists" {
  # Create a package.json with release:watch
  cat > "$TEST_PROJECT_DIR/package.json" <<'PKG'
{ "scripts": { "release:watch": "bash scripts/release-watch.sh" } }
PKG

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$TEST_PROJECT_DIR' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  [[ "$output" == *"release:watch"* ]]
}

@test "gh pr merge tells agent to create release:watch when script missing" {
  # Create a package.json WITHOUT release:watch
  cat > "$TEST_PROJECT_DIR/package.json" <<'PKG'
{ "scripts": { "test": "echo test" } }
PKG

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$TEST_PROJECT_DIR' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  # Should tell agent to create the script
  [[ "$output" == *"no release:watch script"* ]]
  [[ "$output" == *"gh pr merge"* ]]
  [[ "$output" == *"gh run watch"* ]]
}

@test "gh pr merge tells agent to create release:watch when no package.json" {
  local empty_dir="$(mktemp -d)"

  INPUT=$(build_input "gh pr merge 4 --merge")
  run bash -c "cd '$empty_dir' && echo '$INPUT' | '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"permissionDecision"* ]]
  [[ "$output" == *"deny"* ]]
  # Should tell agent to create the script
  [[ "$output" == *"no release:watch script"* ]]
  [[ "$output" == *"gh pr merge"* ]]
  [[ "$output" == *"gh run watch"* ]]

  rm -rf "$empty_dir"
}
