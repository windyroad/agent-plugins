#!/usr/bin/env bats

# P001 / ADR-009: legacy Stop-hook marker reset remains removed.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "voice-tone: hooks.json registers the bounded assistant response Stop hook" {
  run jq -r '.hooks.Stop[0].hooks[0].command' "$PLUGIN_DIR/hooks/hooks.json"
  [ "$status" -eq 0 ]
  [ "$output" = '${CLAUDE_PLUGIN_ROOT}/hooks/assistant-voice-tone-stop.sh' ]
}

@test "voice-tone: voice-tone-reset-marker.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/voice-tone-reset-marker.sh" ]
}
