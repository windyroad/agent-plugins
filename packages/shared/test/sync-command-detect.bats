#!/usr/bin/env bats

# P268 / P275 / P366 / ADR-017: command-detect.sh duplicated across consumer
# plugins (itil, retrospective, architect). Drift check — every
# packages/*/hooks/lib/command-detect.sh copy must match the canonical
# packages/shared/hooks/lib/command-detect.sh. The sync script is the
# remediation; this test is the CI guard. Mirrors sync-session-marker.bats
# (P095 / ADR-038).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-command-detect.sh"
  SHARED_SRC="$REPO_ROOT/packages/shared/hooks/lib/command-detect.sh"
}

@test "sync-command-detect: canonical source exists" {
  [ -f "$SHARED_SRC" ]
}

@test "sync-command-detect: sync script exists and is executable" {
  [ -x "$SYNC_SCRIPT" ]
}

@test "sync-command-detect: all consumer copies exist" {
  for plugin in itil retrospective architect; do
    [ -f "$REPO_ROOT/packages/$plugin/hooks/lib/command-detect.sh" ] || {
      echo "MISSING: packages/$plugin/hooks/lib/command-detect.sh"
      return 1
    }
  done
}

@test "sync-command-detect: all copies byte-identical to canonical (drift check)" {
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-command-detect: --check flag flags divergence when a copy differs" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/hooks/lib" \
           "$tmp/packages/itil/hooks/lib" \
           "$tmp/packages/retrospective/hooks/lib" \
           "$tmp/packages/architect/hooks/lib" \
           "$tmp/scripts"
  cp "$SHARED_SRC" "$tmp/packages/shared/hooks/lib/command-detect.sh"
  for plugin in itil retrospective architect; do
    cp "$SHARED_SRC" "$tmp/packages/$plugin/hooks/lib/command-detect.sh"
  done
  echo "# drift" >> "$tmp/packages/itil/hooks/lib/command-detect.sh"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-command-detect.sh"
  chmod +x "$tmp/scripts/sync-command-detect.sh"

  run bash "$tmp/scripts/sync-command-detect.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]] || [[ "$output" == *"diverged"* ]]

  rm -rf "$tmp"
}

@test "sync-command-detect: --check flag flags a missing copy" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/hooks/lib" \
           "$tmp/packages/itil/hooks/lib" \
           "$tmp/packages/retrospective/hooks/lib" \
           "$tmp/packages/architect/hooks/lib" \
           "$tmp/scripts"
  cp "$SHARED_SRC" "$tmp/packages/shared/hooks/lib/command-detect.sh"
  for plugin in itil retrospective architect; do
    cp "$SHARED_SRC" "$tmp/packages/$plugin/hooks/lib/command-detect.sh"
  done
  rm "$tmp/packages/retrospective/hooks/lib/command-detect.sh"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-command-detect.sh"
  chmod +x "$tmp/scripts/sync-command-detect.sh"

  run bash "$tmp/scripts/sync-command-detect.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"MISSING"* ]]

  rm -rf "$tmp"
}
