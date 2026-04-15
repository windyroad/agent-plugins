#!/usr/bin/env bats

# P001 / ADR-009: Stop-hook marker reset removed.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "risk-scorer: hooks.json has no Stop hook entry (ADR-009)" {
  ! grep -q '"Stop"' "$PLUGIN_DIR/hooks/hooks.json"
}

@test "risk-scorer: risk-score-reset.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/risk-score-reset.sh" ]
}

@test "risk-scorer: risk-policy-reset-marker.sh has been removed" {
  [ ! -f "$PLUGIN_DIR/hooks/risk-policy-reset-marker.sh" ]
}
