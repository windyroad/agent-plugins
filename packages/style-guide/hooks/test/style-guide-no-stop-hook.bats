#!/usr/bin/env bats

# P001 / ADR-009: Stop-hook marker reset removed.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "style-guide: hooks.json has no Stop hook entry (ADR-009)" {
  ! grep -q '"Stop"' "$PLUGIN_DIR/hooks/hooks.json"
}

@test "style-guide: style-guide-reset-marker.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/style-guide-reset-marker.sh" ]
}
