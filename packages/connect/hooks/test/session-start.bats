#!/usr/bin/env bats

# Tests for session-start.sh (SessionStart hook)
# Verifies three states: no config, config without channels, config with channels.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/session-start.sh"
  # Clear env vars for each test
  unset WR_CONNECT_BOT_TOKEN
  unset WR_CONNECT_CHANNEL_ID
  unset WR_CONNECT_SESSION_NAME
  unset CLAUDE_CHANNELS
}

@test "no env vars: exits 0, no output" {
  run "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "env vars set, no CLAUDE_CHANNELS: exits 0, warns about --channels" {
  export WR_CONNECT_BOT_TOKEN="test-token"
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--channels"* ]]
  [[ "$output" == *"plugin:discord@claude-plugins-official"* ]]
}

@test "env vars set, CLAUDE_CHANNELS active: exits 0, outputs primer with session name" {
  export WR_CONNECT_BOT_TOKEN="test-token"
  export WR_CONNECT_SESSION_NAME="repo-b"
  export CLAUDE_CHANNELS=1
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo-b"* ]]
  [[ "$output" == *"@repo-b"* ]]
}

@test "primer tells agent to prioritise @mentions" {
  export WR_CONNECT_BOT_TOKEN="test-token"
  export WR_CONNECT_SESSION_NAME="my-repo"
  export CLAUDE_CHANNELS=1
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"@my-repo"* ]]
  [[ "$output" == *"relevant"* ]]
}
