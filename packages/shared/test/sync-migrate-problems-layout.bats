#!/usr/bin/env bats

# P170 / RFC-002 / ADR-031: migrate-problems-layout.sh shared shell
# routine. Canonical at packages/shared/lib/migrate-problems-layout.sh;
# synced into each consumer's lib/ directory per ADR-017. This bats
# fixture asserts the canonical exists + every consumer copy exists +
# all copies are byte-identical to canonical (drift check). Mirrors
# sync-session-marker.bats / sync-install-utils.bats.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-migrate-problems-layout.sh"
  SHARED_SRC="$REPO_ROOT/packages/shared/lib/migrate-problems-layout.sh"
  # T7 ships with itil as the only consumer; T8 + T9 wire the consumer
  # call sites but the synced copy itself is added at T7 commit time so
  # the sync triad lands intact per ADR-017 Confirmation criterion 5.
  CONSUMERS=(itil)
}

@test "migrate-problems-layout: canonical source exists" {
  [ -f "$SHARED_SRC" ]
}

@test "migrate-problems-layout: canonical declares bash dependency in shebang" {
  head -1 "$SHARED_SRC" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash'
}

@test "migrate-problems-layout: canonical declares nullglob for partial-migration safety (architect advisory)" {
  grep -q 'shopt -s nullglob\|shopt -os nullglob' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical exposes migrate_problems_to_per_state_layout entrypoint" {
  grep -q '^migrate_problems_to_per_state_layout()\|^function migrate_problems_to_per_state_layout' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical exposes detect_flat_layout predicate" {
  grep -q '^detect_flat_layout()\|^function detect_flat_layout' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical iterates all five lifecycle states" {
  grep -q 'open' "$SHARED_SRC"
  grep -q 'known-error' "$SHARED_SRC"
  grep -q 'verifying' "$SHARED_SRC"
  grep -q 'parked' "$SHARED_SRC"
  grep -q 'closed' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical uses git mv (preserves history)" {
  grep -q 'git mv' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical commit message names ADR-031" {
  grep -q 'ADR-031' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical commit message uses standalone docs(problems) shape" {
  grep -q 'docs(problems): auto-migrate to per-state subdirectory layout' "$SHARED_SRC"
}

@test "migrate-problems-layout: canonical emits RISK_BYPASS: adr-031-migration trailer" {
  grep -q 'RISK_BYPASS: adr-031-migration' "$SHARED_SRC"
}

@test "migrate-problems-layout: sync script exists and is executable" {
  [ -x "$SYNC_SCRIPT" ]
}

@test "migrate-problems-layout: all consumer copies exist" {
  for plugin in "${CONSUMERS[@]}"; do
    [ -f "$REPO_ROOT/packages/$plugin/lib/migrate-problems-layout.sh" ] || {
      echo "MISSING: packages/$plugin/lib/migrate-problems-layout.sh"
      return 1
    }
  done
}

@test "migrate-problems-layout: all copies byte-identical to canonical (drift check)" {
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
}

@test "migrate-problems-layout: --check flag flags divergence when a copy differs" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/lib" "$tmp/packages/itil/lib" "$tmp/scripts"

  # Mirror canonical + sync script into temp; intentionally diverge the
  # itil copy and assert --check exits non-zero.
  cp "$SHARED_SRC" "$tmp/packages/shared/lib/migrate-problems-layout.sh"
  cp "$REPO_ROOT/packages/itil/lib/migrate-problems-layout.sh" "$tmp/packages/itil/lib/migrate-problems-layout.sh"
  echo "# intentional drift" >> "$tmp/packages/itil/lib/migrate-problems-layout.sh"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-migrate-problems-layout.sh"

  run bash "$tmp/scripts/sync-migrate-problems-layout.sh" --check
  [ "$status" -ne 0 ]

  rm -rf "$tmp"
}

@test "migrate-problems-layout: package.json has check:migrate-problems-layout npm script" {
  grep -q '"check:migrate-problems-layout"' "$REPO_ROOT/package.json"
}
