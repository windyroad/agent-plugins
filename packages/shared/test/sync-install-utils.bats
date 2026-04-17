#!/usr/bin/env bats

# P026: install-utils.mjs duplicated across packages.
# Drift check — every packages/*/lib/install-utils.mjs copy must match
# the canonical packages/shared/install-utils.mjs. The sync script is
# the remediation; this test is the CI guard.

setup() {
  # Test file lives at packages/shared/test/ — 3 levels below repo root.
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-install-utils.sh"
  SHARED_SRC="$REPO_ROOT/packages/shared/install-utils.mjs"
}

@test "sync-install-utils: canonical source exists" {
  [ -f "$SHARED_SRC" ]
}

@test "sync-install-utils: sync script exists and is executable" {
  [ -x "$SYNC_SCRIPT" ]
}

@test "sync-install-utils: at least one lib/ copy exists" {
  local count
  count=$(find "$REPO_ROOT/packages" -maxdepth 3 -type f -path '*/lib/install-utils.mjs' | wc -l | tr -d ' ')
  [ "$count" -ge 1 ]
}

@test "sync-install-utils: all lib/install-utils.mjs copies match shared (drift check)" {
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-install-utils: --check flag flags divergence when a copy differs" {
  # Create a temp workspace mirroring the layout so we can intentionally
  # diverge a copy without touching the repo.
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared" "$tmp/packages/fakepkg/lib" "$tmp/scripts"
  cp "$SHARED_SRC" "$tmp/packages/shared/install-utils.mjs"
  cp "$SHARED_SRC" "$tmp/packages/fakepkg/lib/install-utils.mjs"
  # Diverge the copy
  echo "// drift" >> "$tmp/packages/fakepkg/lib/install-utils.mjs"
  # Copy script into the temp root so its REPO_ROOT resolves correctly
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-install-utils.sh"
  chmod +x "$tmp/scripts/sync-install-utils.sh"

  run bash "$tmp/scripts/sync-install-utils.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]] || [[ "$output" == *"diverged"* ]]

  rm -rf "$tmp"
}
