#!/usr/bin/env bats

# P001 / ADR-009: Stop-hook marker reset removed.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "voice-tone: hooks.json has no Stop hook entry (ADR-009)" {
  ! grep -q '"Stop"' "$PLUGIN_DIR/hooks/hooks.json"
}

@test "voice-tone: voice-tone-reset-marker.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/voice-tone-reset-marker.sh" ]
}
