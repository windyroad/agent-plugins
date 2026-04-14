#!/usr/bin/env bats

# Tests for session-start.sh (SessionStart hook)
# Verifies: no config, config without channels, config with channels.

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$SCRIPT_DIR/session-start.sh"
  # Set up a fake Discord config
  TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR"
  unset CLAUDE_CHANNELS
  unset WR_CONNECT_SESSION_NAME
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "no discord config: exits 0, no output" {
  run "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "discord configured, no CLAUDE_CHANNELS: exits 0, warns about --channels" {
  mkdir -p "$HOME/.claude/channels/discord"
  echo "DISCORD_BOT_TOKEN=test" > "$HOME/.claude/channels/discord/.env"
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--channels"* ]]
  [[ "$output" == *"plugin:discord@claude-plugins-official"* ]]
}

@test "discord configured, CLAUDE_CHANNELS active: exits 0, outputs primer" {
  mkdir -p "$HOME/.claude/channels/discord"
  echo "DISCORD_BOT_TOKEN=test" > "$HOME/.claude/channels/discord/.env"
  export CLAUDE_CHANNELS=1
  export WR_CONNECT_SESSION_NAME="test-repo"
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test-repo"* ]]
  [[ "$output" == *"@test-repo"* ]]
}

@test "primer tells agent to prioritise @mentions" {
  mkdir -p "$HOME/.claude/channels/discord"
  echo "DISCORD_BOT_TOKEN=test" > "$HOME/.claude/channels/discord/.env"
  export CLAUDE_CHANNELS=1
  export WR_CONNECT_SESSION_NAME="my-repo"
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"@my-repo"* ]]
  [[ "$output" == *"relevant"* ]]
}

@test "primer includes prefix instruction" {
  mkdir -p "$HOME/.claude/channels/discord"
  echo "DISCORD_BOT_TOKEN=test" > "$HOME/.claude/channels/discord/.env"
  export CLAUDE_CHANNELS=1
  export WR_CONNECT_SESSION_NAME="my-repo"
  run "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"prefix"* ]]
  [[ "$output" == *"my-repo"* ]]
}
