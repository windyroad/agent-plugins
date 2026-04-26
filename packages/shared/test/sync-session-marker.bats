#!/usr/bin/env bats

# P095 / ADR-038: session-marker.sh duplicated across consumer plugins.
# Drift check — every packages/*/hooks/lib/session-marker.sh copy must
# match the canonical packages/shared/hooks/lib/session-marker.sh. The
# sync script is the remediation; this test is the CI guard. Mirrors
# sync-install-utils.bats (P026 / ADR-017).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-session-marker.sh"
  SHARED_SRC="$REPO_ROOT/packages/shared/hooks/lib/session-marker.sh"
}

@test "sync-session-marker: canonical source exists" {
  [ -f "$SHARED_SRC" ]
}

@test "sync-session-marker: sync script exists and is executable" {
  [ -x "$SYNC_SCRIPT" ]
}

@test "sync-session-marker: all consumer copies exist" {
  for plugin in architect jtbd tdd style-guide voice-tone itil risk-scorer; do
    [ -f "$REPO_ROOT/packages/$plugin/hooks/lib/session-marker.sh" ] || {
      echo "MISSING: packages/$plugin/hooks/lib/session-marker.sh"
      return 1
    }
  done
}

@test "sync-session-marker: all copies byte-identical to canonical (drift check)" {
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-session-marker: --check flag flags divergence when a copy differs" {
  # Create a temp workspace mirroring the layout so we can intentionally
  # diverge a copy without touching the repo.
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/hooks/lib" \
           "$tmp/packages/architect/hooks/lib" \
           "$tmp/packages/jtbd/hooks/lib" \
           "$tmp/packages/tdd/hooks/lib" \
           "$tmp/packages/style-guide/hooks/lib" \
           "$tmp/packages/voice-tone/hooks/lib" \
           "$tmp/packages/itil/hooks/lib" \
           "$tmp/packages/risk-scorer/hooks/lib" \
           "$tmp/scripts"
  cp "$SHARED_SRC" "$tmp/packages/shared/hooks/lib/session-marker.sh"
  for plugin in architect jtbd tdd style-guide voice-tone itil risk-scorer; do
    cp "$SHARED_SRC" "$tmp/packages/$plugin/hooks/lib/session-marker.sh"
  done
  # Diverge one copy
  echo "# drift" >> "$tmp/packages/architect/hooks/lib/session-marker.sh"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-session-marker.sh"
  chmod +x "$tmp/scripts/sync-session-marker.sh"

  run bash "$tmp/scripts/sync-session-marker.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]] || [[ "$output" == *"diverged"* ]]

  rm -rf "$tmp"
}

@test "sync-session-marker: --check flag flags a missing copy" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/hooks/lib" \
           "$tmp/packages/architect/hooks/lib" \
           "$tmp/packages/jtbd/hooks/lib" \
           "$tmp/packages/tdd/hooks/lib" \
           "$tmp/packages/style-guide/hooks/lib" \
           "$tmp/packages/voice-tone/hooks/lib" \
           "$tmp/packages/itil/hooks/lib" \
           "$tmp/packages/risk-scorer/hooks/lib" \
           "$tmp/scripts"
  cp "$SHARED_SRC" "$tmp/packages/shared/hooks/lib/session-marker.sh"
  for plugin in architect jtbd tdd style-guide voice-tone itil risk-scorer; do
    cp "$SHARED_SRC" "$tmp/packages/$plugin/hooks/lib/session-marker.sh"
  done
  # Remove one copy entirely
  rm "$tmp/packages/voice-tone/hooks/lib/session-marker.sh"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-session-marker.sh"
  chmod +x "$tmp/scripts/sync-session-marker.sh"

  run bash "$tmp/scripts/sync-session-marker.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"MISSING"* ]]

  rm -rf "$tmp"
}
