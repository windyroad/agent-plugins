#!/usr/bin/env bats

# P001 / ADR-009: Stop-hook marker reset removed. Marker lifecycle is
# governed by TTL + drift detection. This test asserts the Stop hook
# entry is absent from the plugin's hooks.json.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "architect: hooks.json has no Stop hook entry (ADR-009)" {
  ! grep -q '"Stop"' "$PLUGIN_DIR/hooks/hooks.json"
}

@test "architect: architect-reset-marker.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/architect-reset-marker.sh" ]
}
